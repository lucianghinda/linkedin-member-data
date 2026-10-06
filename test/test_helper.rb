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
require "linkedin/member_data/cli"

require "minitest/autorun"
require "json"
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }
