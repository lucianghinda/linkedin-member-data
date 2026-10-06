# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::LoadTest < Minitest::Test
  def test_library_entry_point_does_not_load_the_cli
    script = 'require "linkedin/member_data"; exit(defined?(LinkedIn::MemberData::CLI) ? 1 : 0)'

    assert system(RbConfig.ruby, "-I", File.expand_path("../../../lib", __dir__), "-e", script)
  end
end
