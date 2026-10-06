# frozen_string_literal: true

require "json"

module LinkedIn
  module MemberData
    # Base class of every error this gem raises on purpose.
    class Error < StandardError; end

    # Missing or empty access token.
    class ConfigurationError < Error; end

    # Network failure after all retries (timeouts, reset connections).
    class ConnectionError < Error
      # @return [true] network errors are worth a retry.
      def retryable? = true

      # @return [nil] there is no Retry-After header, so the backoff decides.
      def retry_after = nil
    end

    # Any non-2xx HTTP response, or a 2xx response with a body that is not JSON.
    # The class depends on the status. See `Unauthorized`, `Forbidden`, `NotFound`,
    # `VersionError`, `RateLimited` and `ServerError`. Other statuses raise ApiError itself.
    class ApiError < Error
      # Details of the failed response.
      # `status` is the HTTP status code (Integer).
      # `code` is `serviceErrorCode` or `code` from the body (Integer or String, nil when the body has neither).
      # `body` is the parsed JSON body (nil when the body is empty, not JSON, or not an object).
      # @return [Integer, String, Hash, nil] `status`, `code` or `body`.
      attr_reader :status, :code, :body

      # Builds the error class that fits the response status.
      #
      # @api private
      # @param response [Net::HTTPResponse] a non-2xx response.
      # @return [ApiError] an instance of the subclass for the status.
      def self.from_response(response)
        status = response.code.to_i
        body = parse_body(response.body)
        klass = class_for(status)
        klass.new(message_from(body, status), status: status, code: code_from(body), body: body,
                                              **klass.extra_options(response))
      end

      def self.class_for(status)
        STATUS_CLASSES.fetch(status) { status >= 500 ? ServerError : ApiError }
      end

      def self.parse_body(raw)
        return nil if raw.to_s.empty?

        parsed = JSON.parse(raw)
        parsed.is_a?(Hash) ? parsed : nil
      rescue JSON::ParserError
        nil
      end

      def self.message_from(body, status)
        message = body.to_h["message"]
        message.is_a?(String) && !message.empty? ? message : "HTTP #{status}"
      end

      def self.code_from(body) = body && (body["serviceErrorCode"] || body["code"])

      # Internal hook: subclasses add constructor options read from the response.
      # @api private
      def self.extra_options(_response) = {}

      private_class_method :class_for, :parse_body, :message_from, :code_from

      # @param message [String] `message` from the body, or "HTTP <status>".
      # @param status [Integer] HTTP status code.
      # @param code [Integer, String, nil] error code from the body.
      # @param body [Hash, nil] parsed response body.
      def initialize(message, status:, code: nil, body: nil)
        super(message)
        @status = status
        @code = code
        @body = body
      end

      # Tells if a retry may help. False for most API errors.
      # @return [Boolean]
      def retryable? = false

      # Only RateLimited knows a Retry-After. Others let the backoff decide.
      # @return [nil]
      def retry_after = nil
    end

    # HTTP 401. The token is invalid or expired.
    class Unauthorized < ApiError; end

    # HTTP 403. The token is not allowed to read this data.
    class Forbidden < ApiError; end

    # HTTP 404. For snapshots it can mean "No data found for this memberId".
    class NotFound < ApiError; end

    # HTTP 426. The API version sent by the gem is not supported.
    class VersionError < ApiError; end

    # HTTP 429. Retryable.
    class RateLimited < ApiError
      # Seconds to wait, from the `Retry-After` header.
      # @return [Integer, nil] `nil` when the header is absent, is not a positive number, or is an HTTP date.
      attr_reader :retry_after

      # Adds the parsed `Retry-After` header to the constructor options.
      # @api private
      def self.extra_options(response) = { retry_after: retry_after_from(response["Retry-After"]) }

      # Only a positive number of seconds counts. HTTP-dates and 0 mean "use backoff".
      # @api private
      def self.retry_after_from(value)
        seconds = value.to_s.match?(/\A\d+\z/) ? value.to_i : 0
        seconds.positive? ? seconds : nil
      end

      # @param message [String] error message.
      # @param status [Integer] HTTP status code.
      # @param code [Integer, String, nil] error code from the body.
      # @param body [Hash, nil] parsed response body.
      # @param retry_after [Integer, nil] seconds from the `Retry-After` header.
      def initialize(message, status:, code: nil, body: nil, retry_after: nil)
        super(message, status: status, code: code, body: body)
        @retry_after = retry_after
      end

      # @return [true] a rate limit is worth a retry.
      def retryable? = true
    end

    # HTTP 5xx. Retryable.
    class ServerError < ApiError
      # @return [true] server errors are worth a retry.
      def retryable? = true
    end

    # Defined last because the classes must exist first.
    class ApiError
      # HTTP status => error class. Other statuses use `ServerError` (5xx) or `ApiError`.
      # @api private
      STATUS_CLASSES = {
        401 => Unauthorized,
        403 => Forbidden,
        404 => NotFound,
        426 => VersionError,
        429 => RateLimited
      }.freeze
    end
  end
end
