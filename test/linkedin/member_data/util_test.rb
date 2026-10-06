# frozen_string_literal: true

require "test_helper"
require "date"

class LinkedIn::MemberData::UtilTest < Minitest::Test
  Util = LinkedIn::MemberData::Util

  def test_time_from_ms_returns_utc_time
    time = Util.time_from_ms(1_574_449_662_997)

    assert_equal Time.utc(2019, 11, 22, 19, 7, 42, 997_000), time
    assert_predicate time, :utc?
  end

  def test_time_from_ms_with_nil
    assert_nil Util.time_from_ms(nil)
  end

  def test_epoch_ms_passes_integers_through
    assert_equal 42, Util.epoch_ms(42)
  end

  def test_epoch_ms_converts_time
    assert_equal 1_574_449_662_997, Util.epoch_ms(Time.utc(2019, 11, 22, 19, 7, 42, 997_000))
  end

  def test_epoch_ms_converts_date_to_midnight_utc
    assert_equal 1_788_220_800_000, Util.epoch_ms(Date.new(2026, 9, 1))
  end

  def test_epoch_ms_keeps_the_instant_of_a_date_time
    date_time = DateTime.new(2026, 9, 1, 12, 30, 0, "+02:00")

    assert_equal Time.utc(2026, 9, 1, 10, 30).to_i * 1000, Util.epoch_ms(date_time)
  end

  def test_epoch_ms_converts_time_with_offset
    assert_equal 1_574_449_662_000, Util.epoch_ms(Time.new(2019, 11, 22, 21, 7, 42, "+02:00"))
  end

  def test_epoch_ms_round_trips_with_time_from_ms
    assert_equal 1_574_449_662_997, Util.epoch_ms(Util.time_from_ms(1_574_449_662_997))
  end

  def test_epoch_ms_with_nil
    assert_nil Util.epoch_ms(nil)
  end

  def test_epoch_ms_rejects_other_types
    error = assert_raises(ArgumentError) { Util.epoch_ms("2026-09-01") }

    assert_match(/Time, Date or Integer/, error.message)
  end
end
