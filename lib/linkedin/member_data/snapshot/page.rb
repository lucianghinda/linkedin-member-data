# frozen_string_literal: true

module LinkedIn
  module MemberData
    class Snapshot
      # One response page. `has_next` is true when paging.links has rel "next".
      Page = Data.define(:domain, :rows, :start, :count, :total, :has_next, :raw) do
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

        def next? = has_next
      end
    end
  end
end
