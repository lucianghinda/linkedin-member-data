# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::EventTest < Minitest::Test
  Event = LinkedIn::MemberData::Event

  def setup
    @raw = fixture("changelog_event")
    @event = Event.from_api(@raw)
  end

  def test_from_api_maps_identifiers
    assert_equal 978_988_628, @event.id
    assert_equal "c86c3c71-7844-4ed1-b1fc-66deeac14192", @event.activity_id
  end

  def test_from_api_maps_status_and_config
    assert_equal "SUCCESS", @event.activity_status
    assert_equal 1, @event.config_version
  end

  def test_from_api_maps_times_as_utc
    assert_equal Time.utc(2019, 11, 22, 19, 7, 12, 331_000), @event.captured_at
    assert_equal Time.utc(2019, 11, 22, 19, 7, 42, 997_000), @event.processed_at
    assert_predicate @event.processed_at, :utc?
  end

  def test_from_api_maps_actor_and_owner
    assert_equal "urn:li:person:2qXA98-mVk", @event.owner
    assert_equal "urn:li:person:kAq_1ptj-v", @event.actor
  end

  def test_from_api_maps_resource
    assert_equal "messages", @event.resource_name
    assert_equal "0-UzY2MDM3MjAzODc4OTk1OTI3MDRfNTAw", @event.resource_id
    assert_equal "/messages/0-UzY2MDM3MjAzODc4OTk1OTI3MDRfNTAw", @event.resource_uri
  end

  def test_from_api_maps_method
    assert_equal "CREATE", @event.method
    assert_nil @event.method_name
  end

  def test_from_api_keeps_activity_payloads_raw
    assert_equal "TEXT", @event.activity.dig("content", "format")
    assert_equal({ "firstName" => "Tom" }, @event.processed_activity["author~"])
  end

  def test_from_api_maps_sibling_activities
    assert_empty @event.sibling_activities
    assert_empty @event.parent_sibling_activities
  end

  def test_from_api_keeps_the_raw_hash
    assert_same @raw, @event.raw
  end

  def test_missing_keys_become_nil_and_unknown_keys_are_ignored
    event = Event.from_api({ "id" => 1, "somethingNew" => true })

    assert_equal 1, event.id
    assert_nil event.processed_at
    assert_nil event.resource_name
  end

  def test_processed_at_ms_keeps_the_raw_cursor_value
    assert_equal 1_574_449_662_997, @event.processed_at_ms
  end
end
