# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module LinkedIn
  module MemberData
    # One HTTP door to api.linkedin.com. Adds headers, parses JSON,
    # maps statuses to errors and retries 429/5xx/network failures.
    class Connection
      BASE_URL = "https://api.linkedin.com"
      API_VERSION = "202312"
      RETRYABLE_EXCEPTIONS = [Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET].freeze
      HEADERS = {
        "Linkedin-Version" => API_VERSION,
        "X-Restli-Protocol-Version" => "2.0.0",
        "Content-Type" => "application/json",
        "User-Agent" => "linkedin-member-data/#{VERSION}"
      }.freeze

      # Default transport: a real Net::HTTP call. Replaced in tests.
      class NetHttpTransport
        def initialize(timeout:)
          @timeout = timeout
        end

        def call(request, uri)
          Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: @timeout, read_timeout: @timeout) do |http|
            http.request(request)
          end
        end
      end

      # Runs a block again on retryable errors. Waits for Retry-After, else backs off.
      class Retrier
        def initialize(retries:, sleeper:)
          @retries = retries
          @sleeper = sleeper
        end

        def run(attempt = 0, &)
          yield
        rescue ApiError, ConnectionError => error
          raise unless error.retryable? && attempt < @retries

          pause(attempt, error.retry_after)
          run(attempt + 1, &)
        end

        private

        def pause(attempt, retry_after)
          backoff = (0.5 * (2**attempt)) + (rand * 0.1)
          @sleeper.call([retry_after, backoff].compact.first)
        end
      end

      def initialize(access_token:, retries: 3, timeout: 30, logger: nil, sleeper: Kernel.method(:sleep),
                     transport: NetHttpTransport.new(timeout: timeout))
        @headers = HEADERS.merge("Authorization" => "Bearer #{access_token}")
        @retrier = Retrier.new(retries: retries, sleeper: sleeper)
        @logger = logger
        @transport = transport
      end

      def get(path, params = {})
        perform(build_request(Net::HTTP::Get, path, params))
      end

      def post(path, body = {})
        request = build_request(Net::HTTP::Post, path)
        request.body = JSON.generate(body)
        perform(request)
      end

      private

      def build_request(klass, path, params = {})
        uri = URI.join(BASE_URL, path)
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
