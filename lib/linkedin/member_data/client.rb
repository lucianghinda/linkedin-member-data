# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Entry point of the gem. Holds one Connection.
    class Client
      attr_reader :connection

      def initialize(access_token:, retries: 3, timeout: 30, logger: nil, connection: nil)
        require_token(access_token)
        @connection = connection.nil? ? Connection.new(access_token:, retries:, timeout:, logger:) : connection
      end

      def authorization
        element = member_authorizations.first
        Authorization.from_api(element) unless element.nil?
      end

      def enable_changelog!
        connection.post("/rest/memberAuthorizations", {})
        true
      end

      private

      def member_authorizations
        connection.get("/rest/memberAuthorizations", q: "memberAndApplication").fetch("elements", [])
      end

      def require_token(token)
        raise ConfigurationError, "access_token is required" if token.to_s.strip.empty?
      end
    end
  end
end
