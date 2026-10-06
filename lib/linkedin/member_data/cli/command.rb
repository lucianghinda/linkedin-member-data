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
        # Positional arguments the command accepts.
        MAX_ARGUMENTS = 0

        def initialize(context, argv)
          @context = context
          @argv = argv
          @options = {}
        end

        def run
          parser.parse!(argv, into: options)
          check_arguments
          execute
        end

        private

        attr_reader :context, :argv, :options

        def check_arguments
          extra = argv.drop(self.class::MAX_ARGUMENTS)
          raise UsageError, "unexpected argument: #{extra.first}" unless extra.empty?
        end

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
