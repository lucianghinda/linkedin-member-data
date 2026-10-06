# frozen_string_literal: true

require "test_helper"
require "date"

class LinkedIn::MemberData::ChangelogTest < Minitest::Test
  include LinkedIn::MemberData

  def setup
    @transport = FakeTransport.new
    @client = fake_client(@transport)
  end

  def event(id, processed_at)
    fixture("changelog_event").merge("id" => id, "processedAt" => processed_at)
  end

  def page(*events)
    { "paging" => { "start" => 0, "count" => events.size }, "elements" => events }
  end

  def queries
    @transport.requests.map { |_, uri| URI.decode_www_form(uri.query).to_h }
  end

  def test_count_is_validated_before_any_request
    assert_raises(ArgumentError) { @client.changelog(count: 0) }
    assert_raises(ArgumentError) { @client.changelog(count: 51) }
    assert_empty @transport.requests
  end

  def test_rejects_count_one_before_the_cursor_can_stall
    error = assert_raises(ArgumentError) { @client.changelog(count: 1) }

    assert_match(/between 2 and 50/, error.message)
    assert_empty @transport.requests
  end

  def test_since_accepts_integer_and_nil
    assert_equal 1_000, @client.changelog(since: 1_000).since
    assert_nil @client.changelog.since
  end

  def test_since_accepts_time
    assert_equal 1_574_449_662_997, @client.changelog(since: Time.utc(2019, 11, 22, 19, 7, 42, 997_000)).since
  end

  def test_since_accepts_date
    assert_equal Time.utc(2026, 9, 1).to_i * 1000, @client.changelog(since: Date.new(2026, 9, 1)).since
  end

  def test_first_request_params
    @transport.respond(200, page)

    @client.changelog(since: 5, count: 7).to_a

    assert_equal({ "q" => "memberAndApplication", "count" => "7", "startTime" => "5" }, queries.first)
  end

  def test_omits_start_time_when_nil
    @transport.respond(200, page)

    @client.changelog.to_a

    assert_equal({ "q" => "memberAndApplication", "count" => "10" }, queries.first)
  end

  def test_yields_events_and_advances_cursor_to_last_processed_at
    @transport.respond(200, page(event(1, 100), event(2, 200)))
              .respond(200, page(event(2, 200), event(3, 300)))
              .respond(200, page(event(3, 300)))

    ids = @client.changelog(count: 2).map(&:id)

    assert_equal [1, 2, 3], ids
    assert_equal([nil, "200", "300"], queries.map { |query| query["startTime"] })
  end

  def test_stops_on_empty_page
    @transport.respond(200, page)

    assert_empty @client.changelog.to_a
    assert_equal 1, @transport.requests.size
  end

  def test_each_is_lazy
    @transport.respond(200, page(event(1, 100), event(2, 200)))

    first = @client.changelog.first

    assert_equal 1, first.id
    assert_equal 1, @transport.requests.size
  end

  def test_pages_exposes_fresh_events
    @transport.respond(200, page(event(1, 100), event(2, 200))).respond(200, page(event(2, 200)))

    pages = @client.changelog.pages.to_a

    assert_equal 1, pages.size
    assert_equal [1, 2], pages.first.events.map(&:id)
  end

  def test_pages_exposes_next_start_time_and_raw
    @transport.respond(200, page(event(1, 100), event(2, 200))).respond(200, page(event(2, 200)))

    first = @client.changelog.pages.first

    assert_equal 200, first.next_start_time
    assert_equal 2, first.raw["elements"].size
  end

  def test_page_fetches_one_page_without_dedupe
    @transport.respond(200, page(event(9, 900)))

    result = @client.changelog(count: 3).page(850)

    assert_equal [9], result.events.map(&:id)
    assert_equal({ "q" => "memberAndApplication", "count" => "3", "startTime" => "850" }, queries.first)
  end

  def test_errors_propagate
    @transport.respond(429)

    assert_raises(RateLimited) { @client.changelog.to_a }
  end

  def test_each_without_block_returns_enumerator
    assert_kind_of Enumerator, @client.changelog.each
  end

  def test_stops_when_last_event_has_no_processed_at
    @transport.respond(200, page(event(1, 100), event(2, 200)))
              .respond(200, page(event(2, 200), event(3, nil)))

    assert_equal [1, 2, 3], @client.changelog(count: 2).map(&:id)
    assert_equal 2, @transport.requests.size
  end

  def test_events_beyond_count_sharing_one_processed_at_are_unreachable
    @transport.respond(200, page(event(1, 100), event(2, 100))).respond(200, page(event(1, 100), event(2, 100)))

    assert_equal [1, 2], @client.changelog(count: 2).map(&:id)
    assert_equal 2, @transport.requests.size
  end

  def test_count_must_be_an_integer
    assert_raises(ArgumentError) { @client.changelog(count: 2.5) }
    assert_raises(ArgumentError) { @client.changelog(count: nil) }
  end

  def test_each_twice_walks_again_with_a_fresh_walk
    2.times { @transport.respond(200, page(event(1, 100))).respond(200, page(event(1, 100))) }
    changelog = @client.changelog

    assert_equal [1], changelog.to_a.map(&:id)
    assert_equal [1], changelog.to_a.map(&:id)
  end

  def test_each_with_block_returns_the_changelog
    @transport.respond(200, page)
    changelog = @client.changelog

    assert_same(changelog, changelog.each { |_event| nil })
  end

  def test_next_start_time_is_nil_for_an_empty_page
    @transport.respond(200, page)

    assert_nil @client.changelog.page(0).next_start_time
  end
end
