# frozen_string_literal: true

require "optparse"

module LinkedIn
  module MemberData
    class CLI
      # Options that come before the command name: --token and --help.
      # @api private
      class GlobalOptions
        # @param argv [Array<String>] arguments. Global options are removed from it.
        # @return [Hash{Symbol => Object}] options found, for example `{ token: "...", help: true }`.
        # @raise [OptionParser::ParseError] on an unknown option.
        def self.parse(argv) = {}.tap { |options| parser.order!(argv, into: options) }

        def self.parser
          OptionParser.new do |opts|
            opts.on("--token TOKEN")
            opts.on("-h", "--help")
          end
        end

        private_class_method :parser
      end
    end
  end
end
