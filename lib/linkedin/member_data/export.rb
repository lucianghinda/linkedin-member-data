# frozen_string_literal: true

require "fileutils"
require "json"

module LinkedIn
  module MemberData
    # Downloads every snapshot domain into a directory: one `<DOMAIN>.json`
    # per domain plus `manifest.json`. Built by {Client#export}.
    #
    # Domains are fetched in order. A domain that fails with an API or network
    # error is recorded as `:failed` and the run goes on. `Unauthorized` and
    # `Forbidden` stop the run at once (a bad token fails every domain the same
    # way); the manifest is still written before the error propagates.
    class Export
      # File name of the manifest written next to the domain files.
      # @return [String]
      MANIFEST_FILE = "manifest.json"

      # @return [String] export directory.
      attr_reader :dir

      # @return [Array<String>] normalized domain names, in request order.
      attr_reader :domains

      # @param client [Client]
      # @param dir [String] directory to write into. Created when missing.
      # @param domains [Array<Symbol, String>] domains to export. Symbols are upcased.
      # @raise [ArgumentError] when a domain is not a Symbol or a String.
      def initialize(client, dir, domains: Domains::ALL)
        @client = client
        @dir = dir
        @domains = domains.map { |domain| Domains.normalize(domain) }
        @entries = []
      end

      # Runs the export. Yields twice per domain when a block is given: an
      # entry with status `:fetching`, then the final entry.
      # @yieldparam entry [Entry]
      # @return [Manifest]
      # @raise [Unauthorized, Forbidden] when the token is rejected; the manifest is written first.
      # @raise [SystemCallError] when a file cannot be written.
      def run(&progress)
        FileUtils.mkdir_p(dir)
        @entries = []
        walk(progress)
        write_manifest
      end

      private

      def walk(progress)
        domains.each { |domain| @entries << export_domain(domain, progress) }
      rescue Unauthorized, Forbidden
        write_manifest
        raise
      end

      def export_domain(domain, progress)
        progress&.call(Entry.fetching(domain))
        entry = fetch_and_save(domain)
        progress&.call(entry)
        entry
      end

      def fetch_and_save(domain)
        save(domain, @client.snapshot(domain).to_a)
      rescue Unauthorized, Forbidden
        raise
      rescue ApiError, ConnectionError => error
        Entry.failed(domain, error)
      end

      def save(domain, rows)
        write_rows(domain, rows)
        Entry.saved(domain, rows.size)
      end

      def write_rows(domain, rows)
        File.write(File.join(dir, "#{domain}.json"), "#{JSON.pretty_generate(rows)}\n")
      end

      def write_manifest
        Manifest.build(dir, @entries).tap(&:write)
      end
    end
  end
end

require_relative "export/entry"
require_relative "export/manifest"
