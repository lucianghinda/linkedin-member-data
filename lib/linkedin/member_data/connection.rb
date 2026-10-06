# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "openssl"

module LinkedIn
  module MemberData
    # One HTTP door to api.linkedin.com. Adds headers, parses JSON,
    # maps statuses to errors and retries 429/5xx/network failures.
    # @api private
    class Connection
      # @return [String]
      BASE_URL = "https://api.linkedin.com"
      # Value of the `Linkedin-Version` header.
      # @return [String]
      API_VERSION = "202312"
      # Network errors that become a `ConnectionError`.
      # @return [Array<Class>]
      RETRYABLE_EXCEPTIONS = [
        Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED,
        Errno::EPIPE, SocketError, EOFError, OpenSSL::SSL::SSLError
      ].freeze
      # Upper limit for a server-sent Retry-After, in seconds.
      # @return [Integer]
      MAX_RETRY_AFTER = 60
      HEADERS = {
        "Linkedin-Version" => API_VERSION,
        "X-Restli-Protocol-Version" => "2.0.0",
        "Content-Type" => "application/json",
        "User-Agent" => "linkedin-member-data/#{VERSION}"
      }.freeze

      # Default transport: a real Net::HTTP call. Replaced in tests.
      # @api private
      class NetHttpTransport
        # @param timeout [Integer, Float] open, read and write timeout in seconds.
        def initialize(timeout:)
          @timeout = timeout
        end

        # @param request [Net::HTTPRequest]
        # @param uri [URI::HTTPS]
        # @return [Net::HTTPResponse]
        def call(request, uri)
          Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: @timeout,
                                              read_timeout: @timeout, write_timeout: @timeout, max_retries: 0) do |http|
            http.request(request)
          end
        end
      end

      # Runs a block again on retryable errors. Waits for Retry-After, else backs off.
      # @api private
      class Retrier
        def initialize(retries:, sleeper:)
          @retries = retries
          @sleeper = sleeper
        end

        # Yields, and runs again on a retryable error. Raises after the last try.
        # @api private
        def run
          (0..@retries).each do |attempt|
            return yield
          rescue ApiError, ConnectionError => error
            wait_or_raise(error, attempt)
          end
        end

        private

        def wait_or_raise(error, attempt)
          raise error unless error.retryable? && attempt < @retries

          backoff = (0.5 * (2**attempt)) + (rand * 0.1)
          # compact.first picks Retry-After when present (a plain `||` is not provable by MC/DC).
          @sleeper.call([[error.retry_after, backoff].compact.first, MAX_RETRY_AFTER].min)
        end
      end
      private_constant :Retrier, :HEADERS

      # @param access_token [String] OAuth token. Sent as a Bearer header.
      # @param retries [Integer] retries on 429, 5xx and network errors. `0` turns retries off.
      #   Must be a nonnegative integer.
      # @param timeout [Integer, Float] timeout in seconds for the default transport.
      # @param logger [Logger, nil] gets one debug line per request.
      # @param sleeper [#call] called with the seconds to wait between retries.
      # @param transport [#call] takes `(request, uri)` and returns a response. Replaced in tests.
      def initialize(access_token:, retries: 3, timeout: 30, logger: nil, sleeper: Kernel.method(:sleep),
                     transport: NetHttpTransport.new(timeout: timeout))
        raise ArgumentError, "retries must be a nonnegative integer" unless retries.is_a?(Integer) && retries >= 0

        @headers = HEADERS.merge("Authorization" => "Bearer #{access_token}")
        @retrier = Retrier.new(retries: retries, sleeper: sleeper)
        @logger = logger
        @transport = transport
      end

      # Hides the token.
      # @return [String]
      def inspect = "#<#{self.class} base_url=#{BASE_URL}>"

      # Sends a GET request.
      #
      # @param path [String] must start with a single `/`.
      # @param params [Hash] query parameters. Nil values are dropped.
      # @return [Hash] parsed JSON body. `{}` for an empty body.
      # @raise [ArgumentError] when `path` does not start with a single `/`.
      # @raise [ApiError] on a non-2xx response, or when a 2xx body is not JSON.
      # @raise [ConnectionError] on a network failure after all retries.
      def get(path, params = {})
        perform(build_request(Net::HTTP::Get, path, params))
      end

      # Sends a POST request with a JSON body.
      #
      # @param path [String] must start with a single `/`.
      # @param body [Hash] sent as JSON.
      # @return [Hash] parsed JSON body. `{}` for an empty body.
      # @raise [ArgumentError] when `path` does not start with a single `/`.
      # @raise [ApiError] on a non-2xx response, or when a 2xx body is not JSON.
      # @raise [ConnectionError] on a network failure after all retries.
      def post(path, body = {})
        request = build_request(Net::HTTP::Post, path)
        request.body = JSON.generate(body)
        perform(request)
      end

      private

      def build_request(klass, path, params = {})
        raise ArgumentError, "path must start with a single /: #{path.inspect}" unless path.match?(%r{\A/(?!/)})

        uri = URI("#{BASE_URL}#{path}")
        query = params.compact
        uri.query = URI.encode_www_form(query) unless query.empty?
        klass.new(uri, @headers)
      end

      def perform(request)
        @retrier.run { attempt_request(request) }
      end

      def attempt_request(request)
        response = transport_call(request)
        code = response.code
        @logger&.debug("#{request.method} #{request.uri} -> #{code}")
        raise ApiError.from_response(response) unless code.start_with?("2")

        parse_json(response.body.to_s, code.to_i)
      end

      def transport_call(request)
        @transport.call(request, request.uri)
      rescue *RETRYABLE_EXCEPTIONS => error
        raise ConnectionError, "#{error.class}: #{error.message}"
      end

      def parse_json(text, status)
        text.strip.empty? ? {} : JSON.parse(text)
      rescue JSON::ParserError
        raise ApiError.new("invalid JSON in response body", status: status)
      end
    end
  end
end
