# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "irb"
gem "minitest", ">= 5.25.5", "< 7"
gem "rake", "~> 13.0"

group :development, :test do
  gem "quality_gate", "~> 0.3", require: false
  # branchproof needs CRuby 4.0+. The gem itself supports Ruby 3.2+.
  gem "branchproof", "~> 0.12", require: false, install_if: -> { RUBY_VERSION >= "4.0" }
end
