# frozen_string_literal: true

module LinkedIn
  module MemberData
    class Snapshot
      # One response page of snapshot data. Immutable.
      #
      # @!attribute [r] domain
      #   @return [String, nil] `snapshotDomain` of the first element. An all-domains call may return several.
      # @!attribute [r] rows
      #   @return [Array<Hash{String => Object}>] rows of every element on this page. Keys differ per domain.
      # @!attribute [r] start
      #   @return [Integer, nil] page index from the `paging` object.
      # @!attribute [r] count
      #   @return [Integer, nil] page size from the `paging` object.
      # @!attribute [r] total
      #   @return [Integer, nil] total number of items from the `paging` object.
      # @!attribute [r] has_next
      #   @return [Boolean] true when `paging.links` has a link with rel `next`.
      # @!attribute [r] raw
      #   @return [Hash] the parsed response body.
      Page = Data.define(:domain, :rows, :start, :count, :total, :has_next, :raw) do
        # Builds a page from a parsed response body. Missing keys give empty or nil values.
        #
        # @param raw [Hash] parsed JSON body of the API response.
        # @return [Snapshot::Page]
        def self.from_api(raw)
          elements = raw.fetch("elements", [])
          # domain comes from the first element; an all-domains call may return several
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

        # Tells if another page may follow. Same value as `#has_next`.
        # The last page can still carry a `next` link, so an empty next page is possible.
        #
        # @return [Boolean]
        def next? = has_next
      end
    end
  end
end
