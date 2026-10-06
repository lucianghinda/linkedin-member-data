# frozen_string_literal: true

module LinkedIn
  module MemberData
    class CLI
      # Raw changelog events as a JSON array.
      # @api private
      class ChangelogCommand < Command
        # @return [Array<Array>]
        OPTIONS = [
          ["--since DATE", SinceParser, "ISO date or datetime"],
          ["--count N", Integer, "Events per request (1..50)"],
          ["--out FILE", "Write to FILE instead of stdout"]
        ].freeze

        private

        def execute
          output.progress("Fetching changelog...")
          events = client.changelog(**options.slice(:since, :count)).map(&:raw)
          output.write(events, options[:out])
          0
        end
      end
    end
  end
end
