# frozen_string_literal: true

require "date"

module LinkedIn
  module MemberData
    # Conversions between epoch milliseconds (LinkedIn wire format) and Time.
    module Util
      module_function

      def time_from_ms(milliseconds)
        return nil if milliseconds.nil?

        Time.at(Rational(milliseconds, 1000)).utc
      end

      def epoch_ms(value)
        case value
        when nil, Integer then value
        when Time, Date then (to_time(value).to_r * 1000).floor
        else raise ArgumentError, "expected Time, Date or Integer epoch milliseconds, got #{value.class}"
        end
      end

      # A Date counts as midnight UTC.
      def to_time(value)
        case value
        when DateTime then value.to_time
        when Date then Time.utc(value.year, value.month, value.day)
        else value
        end
      end
      private_class_method :to_time
    end
  end
end
