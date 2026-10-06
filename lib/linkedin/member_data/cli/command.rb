# frozen_string_literal: true

require "optparse"

module LinkedIn
  module MemberData
    class CLI
      # Base for commands. A command parses its own options, then runs.
      # `run` returns the exit code.
      class Command
        # Option specs for OptionParser#on. Subclasses override.
        OPTIONS = [].freeze

        def initialize(context, argv)
          @context = context
          @argv = argv
          @options = {}
        end

        def run
          parser.parse!(argv, into: options)
          execute
        end

        private

        attr_reader :context, :argv, :options

        def output = context.output

        def client = context.client

        def parser
          parser = OptionParser.new("Usage: linkedin-member-data COMMAND [options]")
          self.class::OPTIONS.each { |spec| parser.on(*spec) }
          parser
        end
      end
    end
  end
end
