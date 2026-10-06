# frozen_string_literal: true

require_relative "lib/linkedin/member_data/version"

Gem::Specification.new do |spec|
  spec.name = "linkedin-member-data"
  spec.version = LinkedIn::MemberData::VERSION
  spec.authors = ["Lucian Ghinda"]
  spec.email = ["lucianghinda@users.noreply.github.com"]

  spec.summary = "Ruby client and CLI for the LinkedIn Member Data Portability (Member) API."
  spec.description = "Download your own LinkedIn data (snapshot domains and changelog events) " \
                     "through the Member Data Portability API. Zero runtime dependencies."
  spec.homepage = "https://github.com/lucianghinda/linkedin-member-data"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml docs/ .branchproof.json .quality_gate.yml .ruby-version])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
