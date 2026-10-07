# frozen_string_literal: true

module LinkedIn
  module MemberData
    class CLI
      # One domain to a file or stdout, or every domain into a directory.
      # @api private
      class SnapshotCommand < Command
        # @return [Array<Array>]
        OPTIONS = [
          ["--all", "Download every domain"],
          ["--out FILE", "Write to FILE instead of stdout"],
          ["--out-dir DIR", "Directory for --all"]
        ].freeze

        # @return [Integer]
        MAX_ARGUMENTS = 1

        private

        def check_arguments
          super
          options[:all] ? check_all : check_one
        end

        def check_all
          raise UsageError, "--all cannot be used with --out" if options[:out]
          raise UsageError, "--all takes no DOMAIN" unless argv.empty?
        end

        def check_one
          raise UsageError, "--out-dir needs --all" if options[:"out-dir"]
        end

        def execute = options[:all] ? download_all : download_one

        def download_one
          domain = argv.shift
          raise UsageError, "snapshot needs a DOMAIN (or --all)" if domain.nil?

          output.write(fetch(domain.upcase), options[:out])
          0
        end

        # Delegates to Client#export. Progress and failures go to stderr.
        # Exit 1 when any domain failed; auth errors propagate.
        def download_all
          manifest = client.export(out_dir) { |entry| report(entry) }
          manifest.success? ? 0 : 1
        end

        def report(entry)
          output.progress("Fetching #{entry.domain}...") if entry.status == :fetching
          output.error("#{entry.domain}: #{entry.error}") if entry.failed?
        end

        # The key comes from OptionParser's long option name (--out-dir).
        def out_dir = options.fetch(:"out-dir") { raise UsageError, "--all needs --out-dir DIR" }

        def fetch(domain)
          output.progress("Fetching #{domain}...")
          client.snapshot(domain).to_a
        end
      end
    end
  end
end
