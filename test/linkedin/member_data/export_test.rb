# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class LinkedIn::MemberData::ExportTest < Minitest::Test
  include LinkedIn::MemberData

  def setup
    @transport = FakeTransport.new
    @client = fake_client(@transport)
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def profile_rows
    fixture("snapshot_profile")["elements"].first["snapshotData"]
  end

  def test_writes_one_file_per_domain_with_the_same_bytes_as_the_cli
    @transport.respond(200, fixture("snapshot_profile"))

    manifest = @client.export(@dir, domains: [:profile])

    assert_equal "#{JSON.pretty_generate(profile_rows)}\n", File.read(File.join(@dir, "PROFILE.json"))
    assert_equal [:saved], manifest.entries.map(&:status)
  end

  def test_walks_every_page_of_a_domain
    @transport.respond(200, fixture("snapshot_page_with_next"))
              .respond(200, fixture("snapshot_second_page"))
              .respond(404, fixture("snapshot_no_data"))

    manifest = @client.export(@dir, domains: %w[CONNECTIONS])

    assert_equal 3, manifest.entries.first.rows
    assert_equal 3, JSON.parse(File.read(File.join(@dir, "CONNECTIONS.json"))).size
  end

  def test_empty_domain_gets_an_empty_array_file
    @transport.respond(404, fixture("snapshot_no_data"))

    manifest = @client.export(@dir, domains: ["SKILLS"])

    assert_equal "[]\n", File.read(File.join(@dir, "SKILLS.json"))
    assert_equal [:empty, 0], [manifest.entries.first.status, manifest.entries.first.rows]
  end

  def test_manifest_file_lists_every_domain_in_order
    @transport.respond(200, fixture("snapshot_profile")).respond(404, fixture("snapshot_no_data")).respond(500)

    manifest = @client.export(@dir, domains: %w[PROFILE SKILLS INBOX])

    json = JSON.parse(File.read(manifest.path))

    assert_equal(%w[PROFILE SKILLS INBOX], json["domains"].map { |d| d["domain"] })
    assert_equal({ "domain" => "INBOX", "status" => "failed", "error" => "HTTP 500" }, json["domains"].last)
    assert_equal VERSION, json["gem_version"]
  end

  def test_failed_domain_has_no_file_and_the_run_continues
    @transport.respond(500).respond(200, fixture("snapshot_profile"))

    manifest = @client.export(@dir, domains: %w[INBOX PROFILE])

    refute_path_exists File.join(@dir, "INBOX.json")
    assert_path_exists File.join(@dir, "PROFILE.json")
    refute_predicate manifest, :success?
  end

  def test_connection_error_is_a_failed_entry
    @transport.fail_with(Net::ReadTimeout.new)

    manifest = @client.export(@dir, domains: %w[PROFILE])

    assert_equal :failed, manifest.entries.first.status
    assert_match(/Net::ReadTimeout/, manifest.entries.first.error)
  end

  def test_progress_yields_fetching_then_final_status
    @transport.respond(200, fixture("snapshot_profile")).respond(500)
    seen = []

    @client.export(@dir, domains: %w[PROFILE INBOX]) { |entry| seen << [entry.domain, entry.status] }

    assert_equal([%w[PROFILE fetching], %w[PROFILE saved], %w[INBOX fetching], %w[INBOX failed]],
                 seen.map { |domain, status| [domain, status.to_s] })
  end

  def test_unauthorized_stops_the_run_and_writes_the_manifest
    @transport.respond(401, { "message" => "bad token" })

    assert_raises(Unauthorized) { @client.export(@dir, domains: %w[PROFILE SKILLS]) }

    assert_empty JSON.parse(File.read(File.join(@dir, "manifest.json")))["domains"]
    assert_equal 1, @transport.requests.size
  end

  def test_forbidden_stops_the_run
    @transport.respond(200, fixture("snapshot_profile")).respond(403)

    assert_raises(Forbidden) { @client.export(@dir, domains: %w[PROFILE SKILLS]) }

    json = JSON.parse(File.read(File.join(@dir, "manifest.json")))

    assert_equal(["PROFILE"], json["domains"].map { |d| d["domain"] })
  end

  def test_rejects_a_bad_domain_type_before_any_request
    assert_raises(ArgumentError) { @client.export(@dir, domains: [42]) }
    assert_empty @transport.requests
  end

  def test_creates_the_directory
    @transport.respond(404, fixture("snapshot_no_data"))
    nested = File.join(@dir, "a", "b")

    @client.export(nested, domains: [:profile])

    assert_path_exists File.join(nested, "manifest.json")
  end

  def test_defaults_to_every_domain
    export = Export.new(@client, @dir)

    assert_equal Domains::ALL, export.domains
  end

  def test_write_errors_propagate
    @transport.respond(200, fixture("snapshot_profile"))
    File.write(File.join(@dir, "blocked"), "")

    assert_raises(SystemCallError) { @client.export(File.join(@dir, "blocked"), domains: [:profile]) }
  end
end
