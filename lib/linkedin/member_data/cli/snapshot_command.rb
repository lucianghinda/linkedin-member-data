# frozen_string_literal: true

require "fileutils"

module LinkedIn
  module MemberData
    class CLI
      # One domain to a file or stdout, or every domain into a directory.
      class SnapshotCommand < Command
        OPTIONS = [
          ["--all", "Download every domain"],
          ["--out FILE", "Write to FILE instead of stdout"],
          ["--out-dir DIR", "Directory for --all"]
        ].freeze

        private

        def execute = options[:all] ? download_all : download_one

        def download_one
          domain = argv.shift
          raise UsageError, "snapshot needs a DOMAIN (or --all)" if domain.nil?

          output.write(fetch(domain), options[:out])
          0
        end

        # A failing domain is reported and the run goes on. Exit 1 at the end.
        def download_all
          FileUtils.mkdir_p(out_dir)
          failed = Domains::ALL.reject { |domain| save(domain, out_dir) }
          failed.empty? ? 0 : 1
        end

        # The key comes from OptionParser's long option name (--out-dir).
        def out_dir = options.fetch(:"out-dir") { raise UsageError, "--all needs --out-dir DIR" }

        # A bad token fails every domain the same way, so Unauthorized and
        # Forbidden stop the run at once. Other errors are per domain.
        def save(domain, dir)
          write_domain(domain, dir)
        rescue Unauthorized, Forbidden
          raise
        rescue ApiError, ConnectionError => error
          report(domain, error)
        end

        # Returns the byte count, which is truthy.
        def write_domain(domain, dir) = output.write(fetch(domain), File.join(dir, "#{domain}.json"))

        # Returns nil, so the domain counts as failed in download_all.
        def report(domain, error) = output.error("#{domain}: #{error.message}")

        def fetch(domain)
          output.progress("Fetching #{domain}...")
          client.snapshot(domain).to_a
        end
      end
    end
  end
end
