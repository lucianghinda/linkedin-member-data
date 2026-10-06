# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::ConnectionTest < Minitest::Test
  include LinkedIn::MemberData

  def setup
    @transport = FakeTransport.new
    @sleeps = []
    @connection = Connection.new(
      access_token: "tok", retries: 2, transport: @transport, sleeper: ->(s) { @sleeps << s }
    )
  end

  def test_get_builds_url_with_query
    @transport.respond(200, { "ok" => true })

    result = @connection.get("/rest/memberSnapshotData", q: "criteria", domain: "PROFILE", start: 0)

    request, uri = @transport.requests.first

    assert_equal({ "ok" => true }, result)
    assert_equal "https://api.linkedin.com/rest/memberSnapshotData?q=criteria&domain=PROFILE&start=0", uri.to_s
    assert_equal "GET", request.method
  end

  def test_get_sets_auth_and_version_headers
    @transport.respond(200, {})

    @connection.get("/x")

    request, = @transport.requests.first

    assert_equal "Bearer tok", request["Authorization"]
    assert_equal "202312", request["Linkedin-Version"]
    assert_equal "2.0.0", request["X-Restli-Protocol-Version"]
  end

  def test_get_sets_content_type_and_user_agent
    @transport.respond(200, {})

    @connection.get("/x")

    request, = @transport.requests.first

    assert_equal "application/json", request["Content-Type"]
    assert_equal "linkedin-member-data/#{VERSION}", request["User-Agent"]
  end

  def test_get_omits_nil_params
    @transport.respond(200, {})

    @connection.get("/rest/memberChangeLogs", q: "memberAndApplication", startTime: nil, count: 10)

    _, uri = @transport.requests.first

    assert_equal "q=memberAndApplication&count=10", uri.query
  end

  def test_post_sends_json_body
    @transport.respond(201, "")

    result = @connection.post("/rest/memberAuthorizations", {})

    request, = @transport.requests.first

    assert_equal({}, result)
    assert_equal "POST", request.method
    assert_equal "{}", request.body
  end

  def test_post_uses_path_without_query
    @transport.respond(201, "")

    @connection.post("/rest/memberAuthorizations", {})

    _, uri = @transport.requests.first

    assert_equal "https://api.linkedin.com/rest/memberAuthorizations", uri.to_s
  end

  def test_empty_success_body_returns_empty_hash
    @transport.respond(200, "")

    assert_equal({}, @connection.get("/x"))
  end

  def test_nil_success_body_returns_empty_hash
    @transport.respond(204)

    assert_equal({}, @connection.get("/x"))
  end

  def test_invalid_json_success_body_raises_api_error
    @transport.respond(200, "not json")

    error = assert_raises(ApiError) { @connection.get("/x") }
    assert_equal 200, error.status
    assert_match(/invalid JSON/, error.message)
  end

  def test_maps_error_statuses
    @transport.respond(401, { "message" => "nope" })

    error = assert_raises(Unauthorized) { @connection.get("/x") }
    assert_equal "nope", error.message
  end

  def test_retries_on_429_using_retry_after_then_succeeds
    @transport.respond(429, nil, "Retry-After" => "3").respond(200, { "ok" => 1 })

    assert_equal({ "ok" => 1 }, @connection.get("/x"))
    assert_equal [3], @sleeps
    assert_equal 2, @transport.requests.size
  end

  def test_retries_on_5xx_then_raises
    @transport.respond(500).respond(502).respond(503)

    assert_raises(ServerError) { @connection.get("/x") }
    assert_equal 3, @transport.requests.size
    assert_equal 2, @sleeps.size
  end

  def test_backoff_doubles_between_attempts
    @transport.respond(500).respond(502).respond(503)

    assert_raises(ServerError) { @connection.get("/x") }
    assert_operator @sleeps[0], :>=, 0.5
    assert_operator @sleeps[1], :>=, 1.0
  end

  def test_does_not_retry_non_retryable_errors
    @transport.respond(404)

    assert_raises(NotFound) { @connection.get("/x") }
    assert_equal 1, @transport.requests.size
    assert_empty @sleeps
  end

  def test_retries_zero_disables_retry
    connection = Connection.new(access_token: "tok", retries: 0, transport: @transport, sleeper: ->(s) { @sleeps << s })
    @transport.respond(429)

    assert_raises(RateLimited) { connection.get("/x") }
    assert_equal 1, @transport.requests.size
  end

  def test_retries_network_errors_then_raises_connection_error
    @transport.fail_with(Net::ReadTimeout.new).fail_with(Errno::ECONNRESET.new).fail_with(Net::OpenTimeout.new)

    error = assert_raises(ConnectionError) { @connection.get("/x") }
    assert_match(/Net::OpenTimeout/, error.message)
    assert_equal 3, @transport.requests.size
  end

  def test_recovers_from_network_error
    @transport.fail_with(Net::ReadTimeout.new).respond(200, { "ok" => 1 })

    assert_equal({ "ok" => 1 }, @connection.get("/x"))
  end

  def test_logs_request_and_status_at_debug
    lines = []
    logger = Object.new
    logger.define_singleton_method(:debug) { |msg| lines << msg }
    connection = Connection.new(access_token: "tok", transport: @transport, logger: logger)
    @transport.respond(200, {})

    connection.get("/rest/memberAuthorizations", q: "memberAndApplication")

    assert_equal ["GET https://api.linkedin.com/rest/memberAuthorizations?q=memberAndApplication -> 200"], lines
  end

  def test_default_transport_uses_net_http_with_timeout
    http = Minitest::Mock.new
    http.expect(:request, FakeTransport::Response.new("200", "{}", {}), [Net::HTTP::Get])
    starter = lambda do |host, port, **opts, &block|
      assert_equal ["api.linkedin.com", 443, true], [host, port, opts[:use_ssl]]
      assert_equal [7, 7], [opts[:open_timeout], opts[:read_timeout]]
      block.call(http)
    end

    result = Net::HTTP.stub(:start, starter) { Connection.new(access_token: "tok", timeout: 7).get("/x") }

    assert_equal({}, result)
    http.verify
  end
end
