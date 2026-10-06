# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::PackageTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  GEMSPEC = File.join(ROOT, "linkedin-member-data.gemspec")

  def specification
    Gem::Specification.load(GEMSPEC)
  end

  def test_gemspec_ships_every_library_file
    expected = Dir.glob("lib/**/*.rb", base: ROOT).sort

    assert_equal expected, specification.files.grep(%r{\Alib/}).sort
  end

  def test_gemspec_ships_the_executable_and_docs
    files = specification.files

    assert_includes files, "exe/linkedin-member-data"
    assert_includes files, "llms.txt"
    assert_includes files, "doc/LinkedIn/MemberData.md"
  end

  def test_gemspec_does_not_ship_tooling_files
    files = specification.files

    assert_empty files.grep(%r{\A(test|docs|bin)/})
    assert_empty files.grep(/\A\./)
  end
end
