# frozen_string_literal: true

require "time"
require "date"
require "optparse"

module LinkedIn
  module MemberData
    class CLI
      # Reads --since: an ISO datetime, or an ISO date (midnight UTC).
      class SinceParser
        def self.call(value)
          Time.iso8601(value)
        rescue ArgumentError
          from_date(value)
        end

        def self.from_date(value)
          date = Date.iso8601(value)
          Time.utc(date.year, date.month, date.day)
        rescue ArgumentError
          raise UsageError, "--since must be an ISO date or datetime, got #{value.inspect}"
        end

        private_class_method :from_date

        OptionParser.accept(self) { |value| call(value) }
      end
    end
  end
end
