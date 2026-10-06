# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::AuthorizationTest < Minitest::Test
  def test_from_api_reads_member_and_application
    auth = LinkedIn::MemberData::Authorization.from_api(fixture("authorization")["elements"].first)

    assert_equal "urn:li:person:123ABC", auth.member
    assert_equal "urn:li:developerApplication:123456", auth.developer_application
  end

  def test_from_api_keeps_time_scopes_and_raw
    raw = fixture("authorization")["elements"].first
    auth = LinkedIn::MemberData::Authorization.from_api(raw)

    assert_equal Time.utc(2023, 10, 27, 5, 1, 9, 85_000), auth.regulated_at
    assert_equal ["DMA"], auth.scopes
    assert_same raw, auth.raw
  end

  def test_from_api_with_missing_fields
    auth = LinkedIn::MemberData::Authorization.from_api({})

    assert_nil auth.member
    assert_nil auth.regulated_at
    assert_empty auth.scopes
  end
end
