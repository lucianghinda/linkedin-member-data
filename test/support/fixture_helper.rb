# frozen_string_literal: true

module FixtureHelper
  def fixture(name)
    JSON.parse(File.read(File.expand_path("../fixtures/#{name}.json", __dir__)))
  end

  def fake_client(transport)
    connection = LinkedIn::MemberData::Connection.new(access_token: "tok", retries: 0, transport: transport)
    LinkedIn::MemberData::Client.new(access_token: "tok", connection: connection)
  end
end

Minitest::Test.include FixtureHelper
