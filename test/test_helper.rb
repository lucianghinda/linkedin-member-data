# frozen_string_literal: true

# quality_gate coverage — start
if ENV["COVERAGE"] == "1"
  require "simplecov"
  require "undercover/simplecov_formatter"

  SimpleCov.formatter = SimpleCov::Formatter::Undercover
  SimpleCov.start do
    enable_coverage :branch
    add_filter "/test/"
    add_filter "/spec/"
  end
end
# quality_gate coverage — end
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "linkedin/member_data"

require "minitest/autorun"
require "json"
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

module FixtureHelper
  def fixture(name)
    JSON.parse(File.read(File.expand_path("fixtures/#{name}.json", __dir__)))
  end

  def fake_client(transport)
    connection = LinkedIn::MemberData::Connection.new(access_token: "tok", retries: 0, transport: transport)
    LinkedIn::MemberData::Client.new(access_token: "tok", connection: connection)
  end
end

Minitest::Test.include FixtureHelper
