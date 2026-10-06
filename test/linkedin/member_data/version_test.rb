# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::VersionTest < Minitest::Test
  def test_has_a_version_number
    refute_nil LinkedIn::MemberData::VERSION
  end
end
