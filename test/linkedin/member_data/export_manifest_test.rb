# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class LinkedIn::MemberData::ExportManifestTest < Minitest::Test
  include LinkedIn::MemberData

  def entries
    [Export::Entry.saved("PROFILE", 1), Export::Entry.saved("INBOX", 0),
     Export::Entry.failed("ADS_CLICKED", StandardError.new("HTTP 500"))]
  end

  def test_build_sets_path_time_and_version
    manifest = Export::Manifest.build("out", entries)

    assert_equal File.join("out", "manifest.json"), manifest.path
    assert_predicate manifest.exported_at, :utc?
    assert_equal VERSION, manifest.gem_version
  end

  def test_failed_and_success
    manifest = Export::Manifest.build("out", entries)

    assert_equal ["ADS_CLICKED"], manifest.failed.map(&:domain)
    refute_predicate manifest, :success?
    assert_predicate Export::Manifest.build("out", entries.first(2)), :success?
  end

  def test_as_json_lists_domains_in_order
    hash = Export::Manifest.build("out", entries).as_json

    assert_equal %w[exported_at gem_version domains], hash.keys
    assert_equal(%w[PROFILE INBOX ADS_CLICKED], hash["domains"].map { |d| d["domain"] })
    assert_equal(%w[saved empty failed], hash["domains"].map { |d| d["status"] })
  end

  def test_write_produces_pretty_json_with_newline
    Dir.mktmpdir do |dir|
      manifest = Export::Manifest.build(dir, entries)

      manifest.write

      content = File.read(manifest.path)

      assert_equal "#{JSON.pretty_generate(manifest.as_json)}\n", content
      assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, JSON.parse(content)["exported_at"])
    end
  end
end
