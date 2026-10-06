# frozen_string_literal: true

require_relative "snapshot/page"

module LinkedIn
  module MemberData
    # Lazy view over `GET /rest/memberSnapshotData` for one domain (or all).
    # Nothing is fetched until you iterate. Each iteration starts a new walk from the first page.
    #
    # Pages are indexed by `start` (0, 1, 2, ...). The API says to keep going
    # until it answers "No data found for this memberId", so that error ends
    # iteration instead of raising. A page with no rows also ends iteration.
    #
    # It includes `Enumerable`, so `first`, `to_a`, `lazy`, `select` and the rest work on rows.
    # `first` fetches one page only.
    #
    # @example Walk all rows of one domain
    #   snapshot = client.snapshot(:connections)
    #   snapshot.each { |row| puts row["First Name"] }
    #   snapshot.first                                       # fetches one page
    #   snapshot.lazy.select { |row| row["Company"] }.first(5)
    class Snapshot
      include Enumerable

      # API path of the snapshot resource.
      # @return [String]
      PATH = "/rest/memberSnapshotData"

      # Text of the API error that means "no more data". It ends iteration.
      # @return [String]
      NO_DATA_MESSAGE = "No data found for this memberId"

      # The domain name sent to the API. `nil` means all domains.
      # @return [String, nil]
      attr_reader :domain

      # @api private
      # @param connection [Connection] used for every request.
      # @param domain [String, nil] domain name as sent to the API. `nil` means all domains.
      def initialize(connection, domain)
        @connection = connection
        @domain = domain
      end

      # Yields every row of every page. Pages are fetched one by one while you iterate.
      # Rows are plain Hashes with the keys LinkedIn returns. Keys differ per domain.
      #
      # @example Block form
      #   client.snapshot(:connections).each { |row| puts row["First Name"] }
      # @example Without a block, you get an Enumerator
      #   client.snapshot(:connections).each.first(3)
      # @yieldparam row [Hash{String => Object}] one row of snapshot data.
      # @return [Snapshot] self, when a block is given.
      # @return [Enumerator<Hash>] when no block is given.
      # @raise [ApiError] on a non-2xx response, except the "No data found" answer.
      # @raise [ConnectionError] on a network failure after all retries.
      def each(&block)
        return enum_for(:each) unless block

        pages.each { |page| page.rows.each(&block) }
        self
      end

      # Lazy Enumerator of pages. The walk stops at the first page without a `next` link.
      # It also stops at an empty page or at the "No data found" answer. Any other API error raises.
      #
      # @example Inspect paging data
      #   client.snapshot(:profile).pages.each do |page|
      #     puts "#{page.domain}: #{page.rows.size} rows, total #{page.total}"
      #   end
      # @return [Enumerator<Snapshot::Page>]
      # @raise [ApiError] while iterating, on a non-2xx response except "No data found".
      # @raise [ConnectionError] while iterating, on a network failure after all retries.
      def pages = Enumerator.new { |yielder| each_page(yielder) }

      # Fetches one page by index. Does not walk. Does not hide the "No data found" error.
      #
      # @example
      #   client.snapshot(:profile).page(0).rows
      # @param start [Integer] zero-based page index.
      # @return [Snapshot::Page]
      # @raise [NotFound] past the end of the data.
      # @raise [ApiError] on any other non-2xx response.
      # @raise [ConnectionError] on a network failure after all retries.
      def page(start)
        Page.from_api(@connection.get(PATH, q: "criteria", start: start, domain: domain))
      end

      private

      def each_page(yielder)
        (0..).each do |start|
          page = usable_page(start)
          yielder << page unless page.nil?
          break unless page&.next?
        end
      end

      # nil ends the walk. An empty page counts as the end even with a next
      # link, because `next` links can appear on the last page.
      def usable_page(start)
        page_or_nil(start)&.then { |page| page unless page.rows.empty? }
      end

      def page_or_nil(start)
        page(start)
      rescue ApiError => error
        raise unless error.message.include?(NO_DATA_MESSAGE)

        nil
      end
    end
  end
end
