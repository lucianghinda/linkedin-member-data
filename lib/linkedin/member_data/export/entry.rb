# frozen_string_literal: true

module LinkedIn
  module MemberData
    class Export
      # What happened to one domain during an export.
      #
      # @!attribute [r] domain
      #   @return [String] domain name, for example `"CONNECTIONS"`.
      # @!attribute [r] status
      #   @return [Symbol] `:fetching`, `:saved`, `:empty` or `:failed`.
      # @!attribute [r] file
      #   @return [String, nil] file name relative to the export directory; nil unless saved or empty.
      # @!attribute [r] rows
      #   @return [Integer, nil] rows written; nil while fetching or when failed.
      # @!attribute [r] error
      #   @return [String, nil] error message when failed.
      Entry = Data.define(:domain, :status, :file, :rows, :error) do
        # @param domain [String]
        # @return [Entry] status `:fetching`.
        def self.fetching(domain) = new(domain: domain, status: :fetching, file: nil, rows: nil, error: nil)

        # @param domain [String]
        # @param rows [Integer] rows written to the file.
        # @return [Entry] status `:empty` when rows is zero, else `:saved`.
        def self.saved(domain, rows)
          status = rows.zero? ? :empty : :saved
          new(domain: domain, status: status, file: "#{domain}.json", rows: rows, error: nil)
        end

        # @param domain [String]
        # @param error [Exception]
        # @return [Entry] status `:failed` with the error message.
        def self.failed(domain, error)
          new(domain: domain, status: :failed, file: nil, rows: nil, error: error.message)
        end

        # @return [Boolean]
        def failed? = status == :failed

        # Hash for manifest.json: string keys and status, nil values dropped.
        # @return [Hash{String => Object}]
        def to_manifest = to_h.merge(status: status.to_s).compact.transform_keys(&:to_s)
      end
    end
  end
end
