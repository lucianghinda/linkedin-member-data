# frozen_string_literal: true

require "optparse"

module LinkedIn
  module MemberData
    class CLI
      # Options that come before the command name: --token and --help.
      class GlobalOptions
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
