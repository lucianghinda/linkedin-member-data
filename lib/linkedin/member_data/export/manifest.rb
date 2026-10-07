# frozen_string_literal: true

require "json"
require "time"

module LinkedIn
  module MemberData
    class Export
      # Result of an export: one entry per domain and the manifest.json path.
      #
      # @!attribute [r] path
      #   @return [String] path of manifest.json.
      # @!attribute [r] entries
      #   @return [Array<Entry>] one final entry per domain, in request order.
      # @!attribute [r] exported_at
      #   @return [Time] UTC time the manifest was built.
      # @!attribute [r] gem_version
      #   @return [String]
      Manifest = Data.define(:path, :entries, :exported_at, :gem_version) do
        # @param dir [String] export directory.
        # @param entries [Array<Entry>]
        # @return [Manifest]
        def self.build(dir, entries)
          new(path: File.join(dir, MANIFEST_FILE), entries: entries, exported_at: Time.now.utc, gem_version: VERSION)
        end

        # @return [Array<Entry>] entries with status `:failed`.
        def failed = entries.select(&:failed?)

        # @return [Boolean] true when no domain failed.
        def success? = failed.empty?

        # @return [Hash{String => Object}] the manifest.json content (not `to_h`, which is the Data member hash).
        def as_json
          { "exported_at" => exported_at.iso8601, "gem_version" => gem_version,
            "domains" => entries.map(&:to_manifest) }
        end

        # Writes manifest.json as pretty JSON with a trailing newline.
        # @return [Integer] bytes written.
        def write = File.write(path, "#{JSON.pretty_generate(as_json)}\n")
      end
    end
  end
end
