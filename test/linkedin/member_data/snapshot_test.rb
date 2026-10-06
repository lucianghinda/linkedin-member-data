# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::SnapshotTest < Minitest::Test
  include LinkedIn::MemberData

  def setup
    @transport = FakeTransport.new
    @client = fake_client(@transport)
  end

  def test_client_snapshot_normalizes_domain
    assert_equal "CONNECTIONS", @client.snapshot(:connections).domain
    assert_equal "Profile", @client.snapshot("Profile").domain
    assert_nil @client.snapshot.domain
  end

  def test_each_yields_rows_from_a_single_page
    @transport.respond(200, fixture("snapshot_profile"))

    rows = @client.snapshot(:profile).to_a

    assert_equal [{ "First Name" => "Tom", "Last Name" => "Cruise", "Headline" => "Marketing Manager" }], rows
    _, uri = @transport.requests.first

    assert_equal "q=criteria&start=0&domain=PROFILE", uri.query
  end

  def test_no_domain_omits_param_and_reads_all_elements
    body = {
      "paging" => { "links" => [] },
      "elements" => [
        { "snapshotDomain" => "PROFILE", "snapshotData" => [{ "a" => 1 }] },
        { "snapshotDomain" => "SKILLS", "snapshotData" => [{ "b" => 2 }] }
      ]
    }
    @transport.respond(200, body)

    assert_equal [{ "a" => 1 }, { "b" => 2 }], @client.snapshot.to_a
    _, uri = @transport.requests.first

    assert_equal "q=criteria&start=0", uri.query
  end

  def test_each_is_lazy
    @transport.respond(200, fixture("snapshot_page_with_next"))

    first = @client.snapshot(:connections).first

    assert_equal "Ada", first["First Name"]
    assert_equal 1, @transport.requests.size
  end

  def test_walks_pages_until_no_data_error
    @transport.respond(200, fixture("snapshot_page_with_next"))
              .respond(200, fixture("snapshot_second_page"))
              .respond(404, fixture("snapshot_no_data"))

    names = @client.snapshot(:connections).map { |row| row["First Name"] }

    assert_equal %w[Ada Grace Linus], names
    starts = @transport.requests.map { |_, uri| URI.decode_www_form(uri.query).to_h["start"] }

    assert_equal %w[0 1 2], starts
  end

  def test_stops_when_page_has_no_next_link
    @transport.respond(200, fixture("snapshot_profile"))

    @client.snapshot(:profile).to_a

    assert_equal 1, @transport.requests.size
  end

  def test_other_errors_propagate
    @transport.respond(401, { "message" => "expired" })

    assert_raises(Unauthorized) { @client.snapshot(:profile).to_a }
  end

  def pages_for_connections
    @transport.respond(200, fixture("snapshot_page_with_next")).respond(404, fixture("snapshot_no_data"))
    @client.snapshot(:connections).pages.to_a
  end

  def test_pages_yields_one_page_before_the_no_data_error
    assert_equal 1, pages_for_connections.size
  end

  def test_page_exposes_domain_and_rows
    page = pages_for_connections.first

    assert_equal "CONNECTIONS", page.domain
    assert_equal 2, page.rows.size
  end

  def test_page_exposes_paging_numbers
    page = pages_for_connections.first

    assert_equal 0, page.start
    assert_equal 10, page.count
    assert_equal 16, page.total
  end

  def test_page_knows_next_and_keeps_raw
    page = pages_for_connections.first

    assert_predicate page, :next?
    assert_equal fixture("snapshot_page_with_next"), page.raw
  end

  def test_page_without_next_link_has_no_next
    @transport.respond(200, fixture("snapshot_profile"))

    refute_predicate @client.snapshot(:profile).page(0), :next?
  end

  def test_empty_response_gives_empty_page
    @transport.respond(200, {})
    page = @client.snapshot.page(0)

    assert_empty page.rows
    assert_nil page.domain
  end

  def test_page_fetches_one_page_and_raises_past_the_end
    @transport.respond(404, fixture("snapshot_no_data"))

    error = assert_raises(NotFound) { @client.snapshot(:connections).page(5) }
    assert_match(/No data found/, error.message)
  end

  def test_each_without_block_returns_enumerator
    assert_kind_of Enumerator, @client.snapshot(:profile).each
  end

  def test_empty_page_with_next_link_stops_walking
    body = { "paging" => { "links" => [{ "rel" => "next" }] }, "elements" => [] }
    @transport.respond(200, body)

    assert_empty @client.snapshot(:connections).to_a
    assert_equal 1, @transport.requests.size
  end

  def test_iterating_twice_repeats_the_requests
    2.times { @transport.respond(200, fixture("snapshot_profile")) }
    snapshot = @client.snapshot(:profile)

    assert_equal snapshot.to_a, snapshot.to_a
    assert_equal 2, @transport.requests.size
  end

  def test_each_with_block_returns_the_snapshot
    @transport.respond(200, fixture("snapshot_profile"))
    snapshot = @client.snapshot(:profile)

    assert_same(snapshot, snapshot.each { |_row| nil })
  end
end
