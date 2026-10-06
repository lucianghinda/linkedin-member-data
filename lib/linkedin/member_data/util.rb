# frozen_string_literal: true

require "date"

module LinkedIn
  module MemberData
    # Conversions between epoch milliseconds (LinkedIn wire format) and Time.
    module Util
      module_function

      def time_from_ms(milliseconds)
        case milliseconds
        when NilClass then nil
        else Time.at(Rational(milliseconds, 1000)).utc
        end
      end

      def epoch_ms(value)
        case value
        when NilClass, Integer then value
        when Time, Date then from_time(value)
        else raise ArgumentError, "expected Time, Date or Integer epoch milliseconds, got #{value.class}"
        end
      end

      def from_time(time)
        (at_utc(time).to_r * 1000).to_i
      end

      # A Date counts as midnight UTC.
      def at_utc(time_or_date)
        return time_or_date unless time_or_date.is_a?(Date)

        Time.utc(time_or_date.year, time_or_date.month, time_or_date.day)
      end
      private_class_method :from_time, :at_utc
    end
  end
end
