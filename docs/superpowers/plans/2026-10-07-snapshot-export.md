# Snapshot Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-ruby:subagent-driven-development (recommended) or superpowers-ruby:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `client.export(dir)` downloads every snapshot domain into `<DOMAIN>.json` files plus a `manifest.json`, with progress callbacks; the CLI's `snapshot --all` uses it. Spec: `docs/superpowers/specs/2026-10-06-snapshot-export-design.md`.

**Architecture:** `Export` (one run over a list of domains) builds `Export::Entry` values (Data) and finishes with an `Export::Manifest` (Data) that writes `manifest.json`. `Client#export` is a one-line factory. `CLI::SnapshotCommand#download_all` becomes a thin wrapper that prints progress and maps `manifest.success?` to an exit code.

**Tech Stack:** Ruby >= 3.2 (`Data.define`), stdlib only (`json`, `fileutils`, `time`), Minitest, existing `FakeTransport` + `fake_client` helpers.

---

## Conventions for every task

- Activate Ruby: `source /opt/homebrew/opt/chruby/share/chruby/chruby.sh && chruby 4.0.6`.
- Work from `/Users/luciang/Dropbox/workprojects/opensource/linkedin-members-api/gems/linkedin-member-data` on branch `main` (create and use branch `snapshot-export`).
- RuboCop inherits the quality_gate ruby profile: methods <= 5 lines, classes <= 100 lines, AbcSize <= 16, cyclomatic <= 6, <= 3 assertions per test (split tests, keep every assertion), line length 120. Tests are exempt from size cops and reek. Never disable a cop inline. Avoid `x || literal` in lib code (branchproof cannot prove it).
- Every public class, method and constant gets YARD: one-line summary, `@param`, `@return`, `@raise`, `@example` on `Client#export`. `.yardopts` has `--fail-on-warning`.
- Gates before every commit: `bundle exec rake` (tests + rubocop), `bundle exec quality_gate verify`, `bundle exec rake branchproof` (MC/DC >= 90).
- Commits: Conventional Commits, blank line, `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Stage files by path.
- Simple technical English in comments; comment only what is not obvious.

## File structure

```
lib/linkedin/member_data/export.rb           # Export: run, per-domain fetch + write, manifest
lib/linkedin/member_data/export/entry.rb     # Export::Entry (Data) + constructors
lib/linkedin/member_data/export/manifest.rb  # Export::Manifest (Data): failed, success?, to_h, write
lib/linkedin/member_data/client.rb           # + export(dir, domains:, &progress)
lib/linkedin/member_data.rb                  # + require export (before client)
lib/linkedin/member_data/cli/snapshot_command.rb  # download_all delegates to client.export
test/linkedin/member_data/export_test.rb
test/linkedin/member_data/cli_test.rb        # StubClient#export, --all file count
examples/export.rb
README.md, CHANGELOG.md, doc/, llms.txt
```

---

### Task 1: Export::Entry and Export::Manifest

**Files:**
- Create: `lib/linkedin/member_data/export/entry.rb`, `lib/linkedin/member_data/export/manifest.rb`, `lib/linkedin/member_data/export.rb` (class shell only)
- Modify: `lib/linkedin/member_data.rb`
- Test: `test/linkedin/member_data/export_entry_test.rb`, `test/linkedin/member_data/export_manifest_test.rb`

- [ ] **Step 1: Write the failing tests**

`test/linkedin/member_data/export_entry_test.rb`:

```ruby
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
```

`test/linkedin/member_data/export_manifest_test.rb`:

```ruby
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

  def test_to_h_lists_domains_in_order
    hash = Export::Manifest.build("out", entries).to_h

    assert_equal %w[exported_at gem_version domains], hash.keys
    assert_equal %w[PROFILE INBOX ADS_CLICKED], hash["domains"].map { |d| d["domain"] }
    assert_equal %w[saved empty failed], hash["domains"].map { |d| d["status"] }
  end

  def test_write_produces_pretty_json_with_newline
    Dir.mktmpdir do |dir|
      manifest = Export::Manifest.build(dir, entries)

      manifest.write

      content = File.read(manifest.path)
      assert_equal "#{JSON.pretty_generate(manifest.to_h)}\n", content
      assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/, JSON.parse(content)["exported_at"])
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec ruby -Ilib -Itest test/linkedin/member_data/export_entry_test.rb`
Expected: FAIL with `uninitialized constant LinkedIn::MemberData::Export`

- [ ] **Step 3: Write the code**

`lib/linkedin/member_data/export/entry.rb`:

```ruby
# frozen_string_literal: true

module LinkedIn
  module MemberData
    class Export
      # What happened to one domain during an export.
      #
      # @!attribute [r] domain
      #   @return [String] domain name, for example `"CONNECTIONS"`.
      # @!attribute [r] status
      #   @return [Symbol] `:fetching`, `:saved`, `:empty` or `:failed`.
      # @!attribute [r] file
      #   @return [String, nil] file name relative to the export directory; nil unless saved or empty.
      # @!attribute [r] rows
      #   @return [Integer, nil] rows written; nil while fetching or when failed.
      # @!attribute [r] error
      #   @return [String, nil] error message when failed.
      Entry = Data.define(:domain, :status, :file, :rows, :error) do
        # @param domain [String]
        # @return [Entry] status `:fetching`.
        def self.fetching(domain) = new(domain: domain, status: :fetching, file: nil, rows: nil, error: nil)

        # @param domain [String]
        # @param rows [Integer] rows written to the file.
        # @return [Entry] status `:empty` when rows is zero, else `:saved`.
        def self.saved(domain, rows)
          status = rows.zero? ? :empty : :saved
          new(domain: domain, status: status, file: "#{domain}.json", rows: rows, error: nil)
        end

        # @param domain [String]
        # @param error [Exception]
        # @return [Entry] status `:failed` with the error message.
        def self.failed(domain, error) = new(domain: domain, status: :failed, file: nil, rows: nil, error: error.message)

        # @return [Boolean]
        def failed? = status == :failed

        # Hash for manifest.json: string keys and status, nil values dropped.
        # @return [Hash{String => Object}]
        def to_manifest = to_h.merge(status: status.to_s).compact.transform_keys(&:to_s)
      end
    end
  end
end
```

`lib/linkedin/member_data/export/manifest.rb`:

```ruby
# frozen_string_literal: true

require "json"
require "time"

module LinkedIn
  module MemberData
    class Export
      # Result of an export: one entry per domain and the manifest.json path.
      #
      # @!attribute [r] path
      #   @return [String] path of manifest.json.
      # @!attribute [r] entries
      #   @return [Array<Entry>] one final entry per domain, in request order.
      # @!attribute [r] exported_at
      #   @return [Time] UTC time the manifest was built.
      # @!attribute [r] gem_version
      #   @return [String]
      Manifest = Data.define(:path, :entries, :exported_at, :gem_version) do
        # @param dir [String] export directory.
        # @param entries [Array<Entry>]
        # @return [Manifest]
        def self.build(dir, entries)
          new(path: File.join(dir, MANIFEST_FILE), entries: entries, exported_at: Time.now.utc, gem_version: VERSION)
        end

        # @return [Array<Entry>] entries with status `:failed`.
        def failed = entries.select(&:failed?)

        # @return [Boolean] true when no domain failed.
        def success? = failed.empty?

        # @return [Hash{String => Object}] the manifest.json content.
        def to_h
          { "exported_at" => exported_at.iso8601, "gem_version" => gem_version,
            "domains" => entries.map(&:to_manifest) }
        end

        # Writes manifest.json as pretty JSON with a trailing newline.
        # @return [Integer] bytes written.
        def write = File.write(path, "#{JSON.pretty_generate(to_h)}\n")
      end
    end
  end
end
```

`lib/linkedin/member_data/export.rb` (shell; `run` comes in Task 2):

```ruby
# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Downloads every snapshot domain into a directory: one `<DOMAIN>.json`
    # per domain plus `manifest.json`. Built by {Client#export}.
    class Export
      # File name of the manifest written next to the domain files.
      # @return [String]
      MANIFEST_FILE = "manifest.json"
    end
  end
end

require_relative "export/entry"
require_relative "export/manifest"
```

Add to `lib/linkedin/member_data.rb` right before `require_relative "member_data/client"`:

```ruby
require_relative "member_data/export"
```

Note on `Data#to_h`: `to_h.merge(status: status.to_s)` keeps symbol keys until `transform_keys(&:to_s)`. Key order in the result is `domain, status, file, rows, error` minus nils, which is what the manifest test expects.

- [ ] **Step 4: Run tests, rubocop, gates**

Run: `bundle exec rake && bundle exec quality_gate verify && bundle exec rake branchproof`
Expected: all green. If rubocop flags `Lint/ConstantDefinitionInBlock`, no constant is defined inside a `Data.define` block here (MANIFEST_FILE is on `Export`), so there should be none. If `Entry.failed` or `Entry.fetching` exceed line length 120, break the `new(...)` call over two lines.

- [ ] **Step 5: Commit**

```bash
git add lib/linkedin/member_data/export.rb lib/linkedin/member_data/export lib/linkedin/member_data.rb test/linkedin/member_data/export_entry_test.rb test/linkedin/member_data/export_manifest_test.rb
git commit -m "feat: add Export::Entry and Export::Manifest"
```

---

### Task 2: Export#run and Client#export

**Files:**
- Modify: `lib/linkedin/member_data/export.rb`, `lib/linkedin/member_data/client.rb`
- Test: `test/linkedin/member_data/export_test.rb`

- [ ] **Step 1: Write the failing test**

```ruby
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class LinkedIn::MemberData::ExportTest < Minitest::Test
  include LinkedIn::MemberData

  def setup
    @transport = FakeTransport.new
    @client = fake_client(@transport)
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def profile_rows
    fixture("snapshot_profile")["elements"].first["snapshotData"]
  end

  def test_writes_one_file_per_domain_with_the_same_bytes_as_the_cli
    @transport.respond(200, fixture("snapshot_profile"))

    manifest = @client.export(@dir, domains: [:profile])

    assert_equal "#{JSON.pretty_generate(profile_rows)}\n", File.read(File.join(@dir, "PROFILE.json"))
    assert_equal [:saved], manifest.entries.map(&:status)
  end

  def test_walks_every_page_of_a_domain
    @transport.respond(200, fixture("snapshot_page_with_next"))
              .respond(200, fixture("snapshot_second_page"))
              .respond(404, fixture("snapshot_no_data"))

    manifest = @client.export(@dir, domains: %w[CONNECTIONS])

    assert_equal 3, manifest.entries.first.rows
    assert_equal 3, JSON.parse(File.read(File.join(@dir, "CONNECTIONS.json"))).size
  end

  def test_empty_domain_gets_an_empty_array_file
    @transport.respond(404, fixture("snapshot_no_data"))

    manifest = @client.export(@dir, domains: ["SKILLS"])

    assert_equal "[]\n", File.read(File.join(@dir, "SKILLS.json"))
    assert_equal [:empty, 0], [manifest.entries.first.status, manifest.entries.first.rows]
  end

  def test_manifest_file_lists_every_domain_in_order
    @transport.respond(200, fixture("snapshot_profile")).respond(404, fixture("snapshot_no_data")).respond(500)

    manifest = @client.export(@dir, domains: %w[PROFILE SKILLS INBOX])

    json = JSON.parse(File.read(manifest.path))
    assert_equal %w[PROFILE SKILLS INBOX], json["domains"].map { |d| d["domain"] }
    assert_equal({ "domain" => "INBOX", "status" => "failed", "error" => "HTTP 500" }, json["domains"].last)
    assert_equal VERSION, json["gem_version"]
  end

  def test_failed_domain_has_no_file_and_the_run_continues
    @transport.respond(500).respond(200, fixture("snapshot_profile"))

    manifest = @client.export(@dir, domains: %w[INBOX PROFILE])

    refute_path_exists File.join(@dir, "INBOX.json")
    assert_path_exists File.join(@dir, "PROFILE.json")
    refute_predicate manifest, :success?
  end

  def test_connection_error_is_a_failed_entry
    @transport.fail_with(Net::ReadTimeout.new)

    manifest = @client.export(@dir, domains: %w[PROFILE])

    assert_equal :failed, manifest.entries.first.status
    assert_match(/Net::ReadTimeout/, manifest.entries.first.error)
  end

  def test_progress_yields_fetching_then_final_status
    @transport.respond(200, fixture("snapshot_profile")).respond(500)
    seen = []

    @client.export(@dir, domains: %w[PROFILE INBOX]) { |entry| seen << [entry.domain, entry.status] }

    assert_equal [%w[PROFILE fetching], %w[PROFILE saved], %w[INBOX fetching], %w[INBOX failed]],
                 seen.map { |domain, status| [domain, status.to_s] }
  end

  def test_unauthorized_stops_the_run_and_writes_the_manifest
    @transport.respond(401, { "message" => "bad token" })

    assert_raises(Unauthorized) { @client.export(@dir, domains: %w[PROFILE SKILLS]) }

    assert_empty JSON.parse(File.read(File.join(@dir, "manifest.json")))["domains"]
    assert_equal 1, @transport.requests.size
  end

  def test_forbidden_stops_the_run
    @transport.respond(200, fixture("snapshot_profile")).respond(403)

    assert_raises(Forbidden) { @client.export(@dir, domains: %w[PROFILE SKILLS]) }

    json = JSON.parse(File.read(File.join(@dir, "manifest.json")))
    assert_equal ["PROFILE"], json["domains"].map { |d| d["domain"] }
  end

  def test_rejects_a_bad_domain_type_before_any_request
    assert_raises(ArgumentError) { @client.export(@dir, domains: [42]) }
    assert_empty @transport.requests
  end

  def test_creates_the_directory
    @transport.respond(404, fixture("snapshot_no_data"))
    nested = File.join(@dir, "a", "b")

    @client.export(nested, domains: [:profile])

    assert_path_exists File.join(nested, "manifest.json")
  end

  def test_defaults_to_every_domain
    export = Export.new(@client, @dir)

    assert_equal Domains::ALL, export.domains
  end

  def test_write_errors_propagate
    @transport.respond(200, fixture("snapshot_profile"))
    File.write(File.join(@dir, "blocked"), "")

    assert_raises(SystemCallError) { @client.export(File.join(@dir, "blocked"), domains: [:profile]) }
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec ruby -Ilib -Itest test/linkedin/member_data/export_test.rb`
Expected: FAIL with `undefined method 'export'`

- [ ] **Step 3: Write Export#run and Client#export**

Replace `lib/linkedin/member_data/export.rb` with:

```ruby
# frozen_string_literal: true

require "fileutils"
require "json"

module LinkedIn
  module MemberData
    # Downloads every snapshot domain into a directory: one `<DOMAIN>.json`
    # per domain plus `manifest.json`. Built by {Client#export}.
    #
    # Domains are fetched in order. A domain that fails with an API or network
    # error is recorded as `:failed` and the run goes on. `Unauthorized` and
    # `Forbidden` stop the run at once (a bad token fails every domain the same
    # way); the manifest is still written before the error propagates.
    class Export
      # File name of the manifest written next to the domain files.
      # @return [String]
      MANIFEST_FILE = "manifest.json"

      # @return [String] export directory.
      attr_reader :dir

      # @return [Array<String>] normalized domain names, in request order.
      attr_reader :domains

      # @param client [Client]
      # @param dir [String] directory to write into. Created when missing.
      # @param domains [Array<Symbol, String>] domains to export. Symbols are upcased.
      # @raise [ArgumentError] when a domain is not a Symbol or a String.
      def initialize(client, dir, domains: Domains::ALL)
        @client = client
        @dir = dir
        @domains = domains.map { |domain| Domains.normalize(domain) }
      end

      # Runs the export. Yields twice per domain when a block is given: an
      # entry with status `:fetching`, then the final entry.
      # @yieldparam entry [Entry]
      # @return [Manifest]
      # @raise [Unauthorized, Forbidden] when the token is rejected; the manifest is written first.
      # @raise [SystemCallError] when a file cannot be written.
      def run(&progress)
        FileUtils.mkdir_p(dir)
        @entries = []
        domains.each { |domain| @entries << export_domain(domain, progress) }
        write_manifest
      rescue Unauthorized, Forbidden
        write_manifest
        raise
      end

      private

      def export_domain(domain, progress)
        progress&.call(Entry.fetching(domain))
        entry = fetch_and_save(domain)
        progress&.call(entry)
        entry
      end

      def fetch_and_save(domain)
        rows = @client.snapshot(domain).to_a
        write_rows(domain, rows)
        Entry.saved(domain, rows.size)
      rescue Unauthorized, Forbidden
        raise
      rescue ApiError, ConnectionError => error
        Entry.failed(domain, error)
      end

      def write_rows(domain, rows)
        File.write(File.join(dir, "#{domain}.json"), "#{JSON.pretty_generate(rows)}\n")
      end

      def write_manifest
        Manifest.build(dir, @entries).tap(&:write)
      end
    end
  end
end

require_relative "export/entry"
require_relative "export/manifest"
```

Add to `Client` after `snapshot`:

```ruby
      # Downloads snapshot domains into a directory, one JSON file each, plus `manifest.json`.
      # @example Everything, with progress
      #   client.export("linkedin-export") { |entry| puts "#{entry.domain}: #{entry.status}" }
      # @example A few domains
      #   manifest = client.export("out", domains: %w[PROFILE CONNECTIONS])
      #   manifest.success? # => true when no domain failed
      # @param dir [String] directory to write into. Created when missing.
      # @param domains [Array<Symbol, String>] domains to export. Defaults to every known domain.
      # @yieldparam entry [Export::Entry] `:fetching` before each domain, then the final entry.
      # @return [Export::Manifest]
      # @raise [Unauthorized, Forbidden] when the token is rejected. The manifest is written first.
      # @raise [ArgumentError] when a domain is not a Symbol or a String.
      def export(dir, domains: Domains::ALL, &progress)
        Export.new(self, dir, domains: domains).run(&progress)
      end
```

Notes for the implementer:
- `@entries` is set at the start of `run`, so a second `run` on the same object starts fresh. `write_manifest` in the `rescue` relies on `@entries` already existing; it does because `mkdir_p` runs first (a `SystemCallError` from `mkdir_p` is not rescued here, which is the intended behavior).
- If reek flags `fetch_and_save` or `export_domain` (FeatureEnvy/DuplicateMethodCall), prefer small renames over config changes; `progress&.call` twice is fine.
- `test_write_errors_propagate` creates a plain file where the export wants a directory, so `mkdir_p` raises `Errno::EEXIST`, a `SystemCallError`.

- [ ] **Step 4: Run tests and gates**

Run: `bundle exec rake && bundle exec quality_gate verify && bundle exec rake branchproof`
Expected: all green, MC/DC >= 90. If branchproof reports an unproven condition in `Entry.saved` (`rows.zero?`), both `test_empty_domain...` and `test_writes_one_file...` cover it; otherwise add the missing case.

- [ ] **Step 5: Commit**

```bash
git add lib/linkedin/member_data/export.rb lib/linkedin/member_data/client.rb test/linkedin/member_data/export_test.rb
git commit -m "feat: add Client#export to download the whole snapshot into a folder"
```

---

### Task 3: CLI `snapshot --all` delegates to Export

**Files:**
- Modify: `lib/linkedin/member_data/cli/snapshot_command.rb`, `test/linkedin/member_data/cli_test.rb`

- [ ] **Step 1: Update the tests**

In `test/linkedin/member_data/cli_test.rb`, add to `StubClient` (it must behave like a `Client` for `Export`):

```ruby
    def export(dir, domains: LinkedIn::MemberData::Domains::ALL, &progress)
      LinkedIn::MemberData::Export.new(self, dir, domains: domains).run(&progress)
    end
```

Change the `--all` file-count assertion: the directory now also holds `manifest.json`, so where the test asserts `Domains::ALL.size - 1` children (65 domain files, INBOX failed), assert `Domains::ALL.size` (65 domain files + manifest.json). Add two tests:

```ruby
  def test_snapshot_all_writes_a_manifest
    client = StubClient.new(snapshots: { "PROFILE" => [{ "a" => 1 }] })
    Dir.mktmpdir do |dir|
      run_cli(["snapshot", "--all", "--out-dir", dir], client: client)

      manifest = JSON.parse(File.read(File.join(dir, "manifest.json")))
      assert_equal Domains::ALL, manifest["domains"].map { |d| d["domain"] }
      assert_equal "saved", manifest["domains"].first["status"]
    end
  end

  def test_snapshot_all_marks_empty_domains
    Dir.mktmpdir do |dir|
      run_cli(["snapshot", "--all", "--out-dir", dir], client: StubClient.new)

      manifest = JSON.parse(File.read(File.join(dir, "manifest.json")))
      assert_equal ["empty"], manifest["domains"].map { |d| d["status"] }.uniq
      assert_equal "[]\n", File.read(File.join(dir, "PROFILE.json"))
    end
  end
```

Run: `bundle exec ruby -Ilib -Itest test/linkedin/member_data/cli_test.rb`
Expected: the changed file-count test and the two new tests fail (no manifest yet).

- [ ] **Step 2: Replace download_all and its helpers**

In `snapshot_command.rb`, delete `saved?`, `written?`, `reported?` and replace `download_all` with:

```ruby
        # Delegates to Client#export. Progress and failures go to stderr.
        # Exit 1 when any domain failed; auth errors propagate.
        def download_all
          manifest = client.export(out_dir) { |entry| report(entry) }
          manifest.success? ? 0 : 1
        end

        def report(entry)
          case entry.status
          when :fetching then output.progress("Fetching #{entry.domain}...")
          when :failed then output.error("#{entry.domain}: #{entry.error}")
          end
        end
```

Keep `out_dir`, `download_one`, `fetch`, `check_all`, `check_one` as they are. Remove `require "fileutils"` from this file if nothing else uses it (Export creates the directory now).

- [ ] **Step 3: Run tests and gates**

Run: `bundle exec rake && bundle exec quality_gate verify && bundle exec rake branchproof`
Expected: all green. Existing `--all` tests (`continues on failure`, `stops at once on unauthorized`, `requires out-dir`) must pass unchanged apart from the file count.

- [ ] **Step 4: Smoke test**

Run: `env -u LINKEDIN_ACCESS_TOKEN bundle exec exe/linkedin-member-data snapshot --all --out-dir /tmp/x; echo "exit=$?"`
Expected: `error: no access token ...`, exit 2 (token check still happens before any export).

- [ ] **Step 5: Commit**

```bash
git add lib/linkedin/member_data/cli/snapshot_command.rb test/linkedin/member_data/cli_test.rb
git commit -m "refactor: back snapshot --all with Client#export"
```

---

### Task 4: Example script, README, CHANGELOG, docs

**Files:**
- Create: `examples/export.rb`
- Modify: `README.md`, `CHANGELOG.md`, regenerated `doc/` and `llms.txt`

- [ ] **Step 1: Write examples/export.rb**

```ruby
# frozen_string_literal: true

# Downloads your whole LinkedIn snapshot into a folder, one JSON file per domain.
# Run from the gem root:  LINKEDIN_ACCESS_TOKEN=... ruby -Ilib examples/export.rb [DIR]

require "linkedin/member_data"

dir = ARGV.fetch(0, "linkedin-export")
client = LinkedIn::MemberData::Client.new(access_token: ENV.fetch("LINKEDIN_ACCESS_TOKEN"))

begin
  manifest = client.export(dir) do |entry|
    case entry.status
    when :fetching then print "#{entry.domain}... "
    when :saved then puts "#{entry.rows} rows"
    when :empty then puts "empty"
    when :failed then puts "failed: #{entry.error}"
    end
  end
rescue LinkedIn::MemberData::Unauthorized => e
  abort "token rejected (#{e.status}): #{e.message}. A partial manifest is in #{dir}/manifest.json"
end

puts "\nWrote #{manifest.entries.size} domains to #{dir} (#{manifest.failed.size} failed). See #{manifest.path}."
exit(manifest.success? ? 0 : 1)
```

Run: `ruby -c examples/export.rb && bundle exec rubocop examples/export.rb` (clean), then `LINKEDIN_ACCESS_TOKEN=fake ruby -Ilib examples/export.rb /tmp/li-fake` and expect the `token rejected (401)` line and a `manifest.json` with an empty `domains` list in `/tmp/li-fake`. Remove `/tmp/li-fake` afterwards. Also commit `examples/demo.rb` (already present, untracked) in this task.

- [ ] **Step 2: README**

Add after the "## Snapshot" section:

```markdown
## Export everything

```ruby
manifest = client.export("linkedin-export") do |entry|
  puts "#{entry.domain}: #{entry.status}"      # :fetching, then :saved, :empty or :failed
end

manifest.entries.size   # one entry per domain
manifest.failed         # entries with status :failed
manifest.success?       # true when nothing failed
manifest.path           # "linkedin-export/manifest.json"
```

The folder gets one `<DOMAIN>.json` per domain (a JSON array of rows; `[]` when LinkedIn has no data yet) and a `manifest.json` that lists every domain with its status, file, row count or error. Pass `domains: %w[PROFILE CONNECTIONS]` to export a subset. A failing domain is recorded and the run continues. `Unauthorized` and `Forbidden` stop the run after writing the manifest. Every run re-fetches everything and overwrites.

`ruby examples/export.rb [DIR]` is a ready-made script, and the CLI does the same with `linkedin-member-data snapshot --all --out-dir DIR`.
```

In the CLI section, mention that `--all` also writes `manifest.json`.

- [ ] **Step 3: CHANGELOG**

Under `## [Unreleased]` add:

```markdown
- `Client#export(dir, domains:)` downloads snapshot domains into a folder with a `manifest.json`. `snapshot --all` now uses it and writes the manifest too.
- `examples/export.rb` and `examples/demo.rb`.
```

- [ ] **Step 4: Docs and gates**

Run: `bundle exec rake docs` (expect 100% documented, no warnings), then `bundle exec rake`, `bundle exec quality_gate verify`, `bundle exec rake branchproof`, `ruby bin/prepare_release` (exit 0; delete `pkg/*.gem` it built, or leave `pkg/` since it is gitignored).

- [ ] **Step 5: Commit**

```bash
git add examples README.md CHANGELOG.md doc llms.txt
git commit -m "docs: document Client#export and add the export example"
```

---

## Self-review notes

- Spec coverage: public interface (T2), Entry/Manifest (T1), files and manifest format (T1, T2), error rules (T2), CLI delegation with unchanged stderr lines (T3), example script and README (T4), package test needs no change (`lib/**/*.rb` glob).
- Names used consistently: `Export.new(client, dir, domains:)`, `Export#run(&progress)`, `Export#domains`, `Export::Entry.fetching/saved/failed`, `Entry#failed?`, `Entry#to_manifest`, `Export::Manifest.build(dir, entries)`, `Manifest#failed/#success?/#to_h/#write/#path`, `Export::MANIFEST_FILE`, `Client#export(dir, domains:, &progress)`.
