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
      # @param domains [Array<Symbol, String>] domains to export. Symbols are upcased. Duplicates are dropped.
      # @raise [ArgumentError] when a domain is not a Symbol or a String.
      def initialize(client, dir, domains: Domains::ALL)
        @client = client
        @dir = dir
        @domains = domains.map { |domain| Domains.normalize(domain) }.uniq
      end

      # Runs the export. Not thread-safe: build one Export per run.
      # Yields twice per domain when a block is given: an
      # entry with status `:fetching`, then the final entry.
      # @yieldparam entry [Entry]
      # @return [Manifest]
      # @raise [Unauthorized, Forbidden] when the token is rejected; the manifest is written first.
      # @raise [SystemCallError] when a file cannot be written.
      def run(&progress)
        FileUtils.mkdir_p(dir)
        write_manifest(export_all(progress))
      end

      private

      # `entries` is a parameter so the rescue below sees the same array.
      def export_all(progress, entries = [])
        domains.each_with_object(entries) { |domain, all| all << export_domain(domain, progress) }
      rescue Unauthorized, Forbidden
        # A SystemCallError from this write would mask the auth error. This is accepted.
        write_manifest(entries)
        raise
      end

      def export_domain(domain, progress)
        progress&.call(Entry.fetching(domain))
        entry = fetch_entry(domain)
        progress&.call(entry)
        entry
      end

      def fetch_entry(domain)
        save(domain, fetch_rows(domain))
      rescue Unauthorized, Forbidden
        raise
      rescue ApiError, ConnectionError => error
        Entry.failed(domain, error)
      end

      # Removes a file left by an earlier run, so a failed domain never keeps stale data.
      def fetch_rows(domain)
        FileUtils.rm_f(path_for(domain))
        @client.snapshot(domain).to_a
      end

      def save(domain, rows)
        write_rows(domain, rows)
        Entry.saved(domain, rows.size)
      end

      # Writes a temp file and renames it, so a crash never leaves a truncated file.
      def write_rows(domain, rows)
        path = path_for(domain)
        File.write("#{path}.tmp", "#{JSON.pretty_generate(rows)}\n")
        File.rename("#{path}.tmp", path)
      end

      def path_for(domain) = File.join(dir, "#{domain}.json")

      def write_manifest(entries)
        Manifest.build(dir, entries).tap(&:write)
      end
    end
  end
end

require_relative "export/entry"
require_relative "export/manifest"
