# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Entry point of the gem. Holds one `Connection`.
    #
    # @example Create a client and read a snapshot
    #   client = LinkedIn::MemberData::Client.new(access_token: ENV["LINKEDIN_ACCESS_TOKEN"])
    #   client.snapshot(:connections).each { |row| puts row["First Name"] }
    class Client
      # API path of the member authorizations resource.
      # @return [String]
      AUTHORIZATIONS_PATH = "/rest/memberAuthorizations"

      # The HTTP connection used for every request.
      # @api private
      # @return [Connection]
      attr_reader :connection

      # Builds a client. No request is sent.
      #
      # @param access_token [String] OAuth token with scope `r_dma_portability_self_serve`.
      #   Leading and trailing spaces are removed.
      # @param retries [Integer] retries on 429, 5xx and network errors, with backoff. `0` turns retries off.
      # @param timeout [Integer, Float] open, read and write timeout in seconds.
      # @param logger [Logger, nil] gets one debug line per request: `GET url -> status`.
      # @param connection [Connection, nil] ready-made connection. When given, `retries`, `timeout`
      #   and `logger` are not used. Meant for tests.
      # @raise [ConfigurationError] when `access_token` is nil or blank.
      def initialize(access_token:, retries: 3, timeout: 30, logger: nil, connection: nil)
        ensure_token(access_token)
        @connection = connection_for(connection, access_token: access_token.to_s.strip, retries:, timeout:, logger:)
      end

      # Returns a lazy view over snapshot data. No request is sent until you iterate.
      #
      # @example One domain, symbol or string
      #   client.snapshot(:profile).first     # symbol is upcased: "PROFILE"
      #   client.snapshot("ALL_COMMENTS").to_a
      # @example All domains
      #   client.snapshot.each { |row| puts row.keys.inspect }
      # @param domain [Symbol, String, nil] a name from `Domains::ALL`. A Symbol is upcased.
      #   A String is sent as given, because the API is case sensitive. `nil` means all domains.
      # @return [Snapshot]
      # @raise [ArgumentError] when `domain` is not a Symbol, a String or nil.
      def snapshot(domain = nil)
        Snapshot.new(connection, Domains.normalize(domain))
      end

      # Returns a lazy view over the changelog of the last 28 days. No request is sent until you iterate.
      #
      # @example Events of the last 7 days
      #   client.changelog(since: Time.now - 7 * 86_400).each do |event|
      #     puts "#{event.method} #{event.resource_name} at #{event.processed_at}"
      #   end
      # @example Resume from the last event you saw
      #   last_seen = client.changelog.to_a.last&.processed_at_ms
      #   client.changelog(since: last_seen).each { |event| puts event.id }
      # @param since [Time, Date, Integer, nil] first `processedAt` to fetch.
      #   Integer is epoch milliseconds. A Date is midnight UTC. `nil` starts at the oldest event.
      # @param count [Integer] events per request, from 2 to 50.
      # @return [Changelog]
      # @raise [ArgumentError] when `count` is outside 2..50 or `since` has an unsupported type.
      #   Raised before any request.
      def changelog(since: nil, count: Changelog::DEFAULT_COUNT)
        Changelog.new(connection, since: since, count: count)
      end

      # Fetches the authorization record of the token. Sends one request.
      #
      # @example
      #   authorization = client.authorization
      #   puts authorization.regulated_at if authorization
      # @return [Authorization, nil] `nil` when LinkedIn returns no authorization.
      # @raise [ApiError] on a non-2xx response, for example `Unauthorized` for a bad token.
      # @raise [ConnectionError] on a network failure after all retries.
      def authorization
        element = member_authorizations.first
        Authorization.from_api(element) unless element.nil?
      end

      # Starts changelog archiving for the member. LinkedIn usually does this by itself.
      #
      # @example
      #   client.enable_changelog!  # => true
      # @return [true] always true. API failures raise.
      # @raise [ApiError] on a non-2xx response.
      # @raise [ConnectionError] on a network failure after all retries.
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
