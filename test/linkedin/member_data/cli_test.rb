# frozen_string_literal: true

require "test_helper"
require "stringio"
require "tmpdir"

class LinkedIn::MemberData::CLITest < Minitest::Test
  include LinkedIn::MemberData

  # Minimal stand-in for Client. Snapshot/changelog return plain Arrays,
  # which is all the CLI needs (each/to_a).
  class StubClient
    attr_reader :calls

    def initialize(snapshots: {}, events: [], authorization: nil, failures: {})
      @snapshots = snapshots
      @events = events
      @authorization = authorization
      @failures = failures
      @calls = []
    end

    def snapshot(domain = nil)
      @calls << [:snapshot, domain]
      raise @failures[domain] if @failures[domain]

      @snapshots.fetch(domain, [])
    end

    def changelog(since: nil, count: 10)
      @calls << [:changelog, since, count]
      @events
    end

    def authorization
      @calls << [:authorization]
      @authorization
    end
  end

  def run_cli(argv, client: StubClient.new, env: { "LINKEDIN_ACCESS_TOKEN" => "tok" })
    stdout = StringIO.new
    stderr = StringIO.new
    factory = lambda do |token|
      @token_seen = token
      client
    end
    status = CLI.new(argv, stdout: stdout, stderr: stderr, env: env, client_factory: factory).run
    [status, stdout.string, stderr.string]
  end

  def test_no_command_prints_usage_and_exits_with_usage_status
    status, _, err = run_cli([])

    assert_equal 2, status
    assert_match(/Usage: linkedin-member-data/, err)
  end

  def test_help_exits_with_success_status
    status, out, = run_cli(["--help"])

    assert_equal 0, status
    assert_match(/Usage: linkedin-member-data/, out)
  end

  def test_unknown_command_exits_with_usage_status
    status, _, err = run_cli(["bogus"])

    assert_equal 2, status
    assert_match(/unknown command/, err)
  end

  def test_unknown_option_exits_with_usage_status
    status, _, err = run_cli(["--bogus", "version"])

    assert_equal 2, status
    assert_match(/error: invalid option/, err)
  end

  def test_version
    status, out, = run_cli(["version"])

    assert_equal 0, status
    assert_equal "#{VERSION}\n", out
  end

  def test_domains_lists_all
    status, out, = run_cli(["domains"])

    assert_equal 0, status
    assert_equal Domains::ALL, out.lines(chomp: true)
  end

  def test_domains_needs_no_token
    status, = run_cli(["domains"], env: {})

    assert_equal 0, status
  end

  def test_missing_token_exits_with_usage_status
    status, _, err = run_cli(["auth"], env: {})

    assert_equal 2, status
    assert_match(/LINKEDIN_ACCESS_TOKEN/, err)
  end

  def test_empty_env_token_exits_with_usage_status
    status, = run_cli(["auth"], env: { "LINKEDIN_ACCESS_TOKEN" => "" })

    assert_equal 2, status
  end

  def test_env_token_is_used
    run_cli(["auth"])

    assert_equal "tok", @token_seen
  end

  def test_token_flag_wins_over_env
    run_cli(["--token", "flag-tok", "auth"], client: StubClient.new(authorization: nil))

    assert_equal "flag-tok", @token_seen
  end

  def test_snapshot_writes_rows_to_stdout
    client = StubClient.new(snapshots: { "CONNECTIONS" => [{ "First Name" => "Ada" }] })

    status, out, = run_cli(%w[snapshot CONNECTIONS], client: client)

    assert_equal 0, status
    assert_equal [{ "First Name" => "Ada" }], JSON.parse(out)
  end

  def test_snapshot_reports_progress_and_asks_client_for_the_domain
    client = StubClient.new

    _, _, err = run_cli(%w[snapshot CONNECTIONS], client: client)

    assert_match(/Fetching CONNECTIONS/, err)
    assert_equal [[:snapshot, "CONNECTIONS"]], client.calls
  end

  def test_snapshot_writes_to_file
    client = StubClient.new(snapshots: { "PROFILE" => [{ "First Name" => "Tom" }] })
    Dir.mktmpdir do |dir|
      path = File.join(dir, "profile.json")

      status, out, = run_cli(["snapshot", "PROFILE", "--out", path], client: client)

      assert_equal 0, status
      assert_empty out
      assert_equal [{ "First Name" => "Tom" }], JSON.parse(File.read(path))
    end
  end

  def test_snapshot_without_domain_exits_with_usage_status
    status, _, err = run_cli(["snapshot"])

    assert_equal 2, status
    assert_match(/DOMAIN/, err)
  end

  def test_snapshot_all_continues_on_failure_and_exits_with_failure_status
    Dir.mktmpdir do |dir|
      status, _, err = run_cli(["snapshot", "--all", "--out-dir", dir], client: failing_inbox_client)

      assert_equal 1, status
      assert_match(/INBOX: no inbox/, err)
    end
  end

  def test_snapshot_all_writes_one_file_per_successful_domain
    Dir.mktmpdir do |dir|
      run_cli(["snapshot", "--all", "--out-dir", dir], client: failing_inbox_client)

      assert_equal [{ "a" => 1 }], JSON.parse(File.read(File.join(dir, "PROFILE.json")))
      assert_equal Domains::ALL.size - 1, Dir.children(dir).size
    end
  end

  def test_snapshot_all_asks_for_every_domain
    client = failing_inbox_client
    Dir.mktmpdir { |dir| run_cli(["snapshot", "--all", "--out-dir", dir], client: client) }

    assert_equal Domains::ALL, client.calls.map(&:last)
  end

  def failing_inbox_client
    StubClient.new(
      snapshots: { "PROFILE" => [{ "a" => 1 }] },
      failures: { "INBOX" => Forbidden.new("no inbox", status: 403) }
    )
  end

  def test_snapshot_all_without_failures_exits_with_success_status
    Dir.mktmpdir do |dir|
      status, = run_cli(["snapshot", "--all", "--out-dir", dir])

      assert_equal 0, status
      assert_equal Domains::ALL.size, Dir.children(dir).size
    end
  end

  def test_snapshot_all_requires_out_dir
    status, _, err = run_cli(["snapshot", "--all"])

    assert_equal 2, status
    assert_match(/--out-dir/, err)
  end

  def test_changelog_writes_raw_events
    raw = fixture("changelog_event")
    client = StubClient.new(events: [Event.from_api(raw)])

    status, out, = run_cli(["changelog"], client: client)

    assert_equal 0, status
    assert_equal [raw], JSON.parse(out)
  end

  def test_changelog_passes_since_and_count
    client = StubClient.new

    run_cli(["changelog", "--since", "2026-09-01", "--count", "25"], client: client)

    assert_equal [[:changelog, Time.utc(2026, 9, 1), 25]], client.calls
  end

  def test_changelog_uses_client_defaults_without_options
    client = StubClient.new

    run_cli(["changelog"], client: client)

    assert_equal [[:changelog, nil, 10]], client.calls
  end

  def test_changelog_writes_to_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "events.json")

      status, out, = run_cli(["changelog", "--out", path])

      assert_equal 0, status
      assert_empty out
      assert_equal [], JSON.parse(File.read(path))
    end
  end

  def test_changelog_accepts_iso_datetime
    client = StubClient.new

    run_cli(["changelog", "--since", "2026-09-01T10:30:00Z"], client: client)

    assert_equal Time.utc(2026, 9, 1, 10, 30), client.calls.first[1]
  end

  def test_changelog_rejects_bad_since
    status, _, err = run_cli(["changelog", "--since", "yesterday"])

    assert_equal 2, status
    assert_match(/--since/, err)
  end

  def test_auth_prints_json
    client = StubClient.new(authorization: Authorization.from_api(fixture("authorization")["elements"].first))

    status, out, = run_cli(["auth"], client: client)

    assert_equal 0, status
    assert_equal "urn:li:person:123ABC", JSON.parse(out).dig("memberComplianceAuthorizationKey", "member")
  end

  def test_auth_without_authorization_exits_with_failure_status
    status, _, err = run_cli(["auth"], client: StubClient.new(authorization: nil))

    assert_equal 1, status
    assert_match(/No authorization/, err)
  end

  def test_api_error_exits_with_failure_status
    client = StubClient.new(failures: { "PROFILE" => Unauthorized.new("token expired", status: 401) })

    status, _, err = run_cli(%w[snapshot PROFILE], client: client)

    assert_equal 1, status
    assert_match(/error: token expired/, err)
  end
end
