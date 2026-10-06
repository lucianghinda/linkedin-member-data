# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Entry point of the gem. Holds one Connection.
    class Client
      AUTHORIZATIONS_PATH = "/rest/memberAuthorizations"

      attr_reader :connection

      def initialize(access_token:, retries: 3, timeout: 30, logger: nil, connection: nil)
        ensure_token(access_token)
        @connection = connection_for(connection, access_token:, retries:, timeout:, logger:)
      end

      def snapshot(domain = nil)
        Snapshot.new(connection, Domains.normalize(domain))
      end

      def authorization
        element = member_authorizations.first
        Authorization.from_api(element) unless element.nil?
      end

      # Returns true. API failures raise.
      def enable_changelog!
        connection.post(AUTHORIZATIONS_PATH, {})
        true
      end

      private

      def member_authorizations
        connection.get(AUTHORIZATIONS_PATH, q: "memberAndApplication").fetch("elements", [])
      end

      def connection_for(connection, **) = connection.nil? ? Connection.new(**) : connection

      def ensure_token(token)
        raise ConfigurationError, "access_token is required" if token.to_s.strip.empty?
      end
    end
  end
end
