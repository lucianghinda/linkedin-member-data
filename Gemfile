# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "irb"
gem "minitest", ">= 5.25.5", "< 7"
gem "rake", "~> 13.0"
gem "yard", "~> 0.9", require: false
gem "yard-markdown", "~> 0.9", require: false

group :development, :test do
  gem "quality_gate", "~> 0.3", require: false
  # branchproof needs CRuby 4.0+. The gem itself supports Ruby 3.2+, so the
  # gem is left out of resolution entirely on older Rubies (install_if alone
  # would still fail to resolve).
  gem "branchproof", "~> 0.12", require: false if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("4.0")
end
