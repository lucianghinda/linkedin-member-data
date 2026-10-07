# frozen_string_literal: true

require "test_helper"

class LinkedIn::MemberData::ExportEntryTest < Minitest::Test
  Entry = LinkedIn::MemberData::Export::Entry

  def test_fetching
    entry = Entry.fetching("PROFILE")

    assert_equal %w[PROFILE fetching], [entry.domain, entry.status.to_s]
    assert_nil entry.file
    assert_nil entry.rows
  end

  def test_saved_with_rows
    entry = Entry.saved("PROFILE", 3)

    assert_equal :saved, entry.status
    assert_equal "PROFILE.json", entry.file
    assert_equal 3, entry.rows
  end

  def test_saved_with_zero_rows_is_empty
    entry = Entry.saved("INBOX", 0)

    assert_equal :empty, entry.status
    assert_equal 0, entry.rows
  end

  def test_failed
    error = LinkedIn::MemberData::ServerError.new("HTTP 500", status: 500)
    entry = Entry.failed("INBOX", error)

    assert_equal :failed, entry.status
    assert_equal "HTTP 500", entry.error
    assert_predicate entry, :failed?
  end

  def test_to_manifest_drops_nils_and_uses_strings
    assert_equal({ "domain" => "PROFILE", "status" => "saved", "file" => "PROFILE.json", "rows" => 1 },
                 Entry.saved("PROFILE", 1).to_manifest)
    assert_equal({ "domain" => "INBOX", "status" => "failed", "error" => "boom" },
                 Entry.failed("INBOX", StandardError.new("boom")).to_manifest)
  end
end
