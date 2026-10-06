# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::ClientTest < Minitest::Test
  include LinkedIn::MemberData

  def setup
    @transport = FakeTransport.new
    @client = fake_client(@transport)
  end

  def test_requires_access_token
    assert_raises(ConfigurationError) { Client.new(access_token: nil) }
    assert_raises(ConfigurationError) { Client.new(access_token: "  ") }
  end

  def test_builds_a_connection_by_default
    client = Client.new(access_token: "tok")

    assert_instance_of Connection, client.connection
  end

  def test_authorization_returns_object
    @transport.respond(200, fixture("authorization"))

    assert_equal "urn:li:person:123ABC", @client.authorization.member
  end

  def test_authorization_requests_member_and_application
    @transport.respond(200, fixture("authorization"))

    @client.authorization

    _, uri = @transport.requests.first

    assert_equal "https://api.linkedin.com/rest/memberAuthorizations?q=memberAndApplication", uri.to_s
  end

  def test_authorization_returns_nil_when_empty
    @transport.respond(200, { "elements" => [] })

    assert_nil @client.authorization
  end

  def test_enable_changelog_returns_true
    @transport.respond(201, "")

    assert @client.enable_changelog!
  end

  def test_enable_changelog_posts_empty_object
    @transport.respond(201, "")

    @client.enable_changelog!

    request, uri = @transport.requests.first

    assert_equal "POST", request.method
    assert_equal "{}", request.body
    assert_equal "https://api.linkedin.com/rest/memberAuthorizations", uri.to_s
  end
end
