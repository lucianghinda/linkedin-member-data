# frozen_string_literal: true

require "json"

module LinkedIn
  module MemberData
    class Error < StandardError; end

    # Missing or empty access token.
    class ConfigurationError < Error; end

    # Network failure after all retries (timeouts, reset connections).
    class ConnectionError < Error; end

    # Any non-2xx HTTP response.
    class ApiError < Error
      attr_reader :status, :code, :body

      def self.from_response(response)
        status = response.code.to_i
        body = parse_body(response.body)
        klass = class_for(status)
        klass.new(message_from(body), status: status, code: code_from(body), body: body,
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

      def self.message_from(body) = body && body["message"]

      def self.code_from(body) = body && (body["serviceErrorCode"] || body["code"])

      # Hook for subclasses that read more from the response.
      def self.extra_options(_response) = {}

      private_class_method :class_for, :parse_body, :message_from, :code_from

      def initialize(message = nil, status:, code: nil, body: nil)
        super(Array(message).fetch(0) { "HTTP #{status}" })
        @status = status
        @code = code
        @body = body
      end

      def retryable? = false

      # Only RateLimited knows a Retry-After. Others let the backoff decide.
      def retry_after = nil
    end

    class Unauthorized < ApiError; end
    class Forbidden < ApiError; end
    class NotFound < ApiError; end
    class VersionError < ApiError; end

    class RateLimited < ApiError
      attr_reader :retry_after

      def self.extra_options(response) = { retry_after: response["Retry-After"]&.to_i }

      def initialize(message = nil, status:, code: nil, body: nil, retry_after: nil)
        super(message, status: status, code: code, body: body)
        @retry_after = retry_after
      end

      def retryable? = true
    end

    class ServerError < ApiError
      def retryable? = true
    end

    # Defined last because the classes must exist first.
    class ApiError
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
