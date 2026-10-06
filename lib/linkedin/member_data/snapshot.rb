# frozen_string_literal: true

require_relative "snapshot/page"

module LinkedIn
  module MemberData
    # Lazy view over GET /rest/memberSnapshotData for one domain (or all).
    # Pages are indexed by `start` (0, 1, 2, ...). The API says to keep going
    # until it answers "No data found for this memberId", so that error ends
    # iteration instead of raising.
    class Snapshot
      include Enumerable

      PATH = "/rest/memberSnapshotData"
      NO_DATA_MESSAGE = "No data found for this memberId"

      attr_reader :domain

      def initialize(connection, domain)
        @connection = connection
        @domain = domain
      end

      def each(&block)
        return enum_for(:each) unless block

        pages.each { |page| page.rows.each(&block) }
        self
      end

      def pages = Enumerator.new { |yielder| each_page(yielder) }

      # One page. Raises NotFound past the end.
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
