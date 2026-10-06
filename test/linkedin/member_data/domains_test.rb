# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::DomainsTest < Minitest::Test
  Domains = LinkedIn::MemberData::Domains

  def test_all_is_a_frozen_list_of_66_domains
    assert_predicate Domains::ALL, :frozen?
    assert_equal 66, Domains::ALL.size
  end

  def test_all_has_no_duplicates
    assert_equal Domains::ALL.uniq.size, Domains::ALL.size
  end

  def test_all_includes_known_domains_in_upcase
    assert_includes Domains::ALL, "CONNECTIONS"
    assert_includes Domains::ALL, "PREMIUM_NOTES"
    assert(Domains::ALL.all? { |d| d == d.upcase })
  end

  def test_normalize_symbol
    assert_equal "MEMBER_SHARE_INFO", Domains.normalize(:member_share_info)
  end

  def test_normalize_string_is_verbatim
    assert_equal "Profile", Domains.normalize("Profile")
  end

  def test_normalize_nil
    assert_nil Domains.normalize(nil)
  end

  def test_normalize_rejects_other_types
    assert_raises(ArgumentError) { Domains.normalize(42) }
  end
end
