# frozen_string_literal: true

require "date"

module LinkedIn
  module MemberData
    # Conversions between epoch milliseconds (LinkedIn wire format) and Time.
    # @api private
    module Util
      module_function

      # Converts epoch milliseconds to a UTC Time. Keeps sub-second precision.
      #
      # @param milliseconds [Integer, nil] epoch milliseconds.
      # @return [Time, nil] UTC Time, or `nil` when `milliseconds` is `nil`.
      def time_from_ms(milliseconds)
        return nil if milliseconds.nil?

        Time.at(Rational(milliseconds, 1000)).utc
      end

      # Converts a Time, Date or Integer to epoch milliseconds. Rounds down.
      #
      # @example
      #   LinkedIn::MemberData::Util.epoch_ms(Time.utc(2026, 9, 1))  # => 1788220800000
      #   LinkedIn::MemberData::Util.epoch_ms(Date.new(2026, 9, 1))  # => 1788220800000 (midnight UTC)
      #   LinkedIn::MemberData::Util.epoch_ms(1_788_220_800_000)     # => 1788220800000
      #   LinkedIn::MemberData::Util.epoch_ms(nil)                   # => nil
      # @param value [Time, Date, Integer, nil] an Integer is taken as epoch milliseconds.
      #   A Date counts as midnight UTC.
      # @return [Integer, nil] epoch milliseconds, or `nil` when `value` is `nil`.
      # @raise [ArgumentError] when `value` is any other type.
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
