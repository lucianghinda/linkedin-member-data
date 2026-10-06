# frozen_string_literal: true

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

      # One response page. `has_next` is true when paging.links has rel "next".
      Page = Data.define(:domain, :rows, :start, :count, :total, :has_next, :raw) do
        def self.from_api(raw)
          elements = raw.fetch("elements", [])
          new(domain: elements.dig(0, "snapshotDomain"), rows: rows_from(elements), raw: raw,
              **paging_from(raw.fetch("paging", {})))
        end

        def self.rows_from(elements)
          elements.flat_map { |element| element.fetch("snapshotData", []) }
        end

        def self.paging_from(paging)
          { start: paging["start"], count: paging["count"], total: paging["total"],
            has_next: paging.fetch("links", []).any? { |link| link["rel"] == "next" } }
        end

        private_class_method :rows_from, :paging_from

        def next? = has_next
      end

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
        start = 0
        start += 1 while emit_with_next?(yielder, start)
      end

      # Returns true when another page may follow.
      def emit_with_next?(yielder, start)
        page = page_or_nil(start)
        yielder << page unless page.nil?
        page&.next?
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
