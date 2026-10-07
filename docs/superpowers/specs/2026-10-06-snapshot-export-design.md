# Snapshot export design

Status: APPROVED
Date: 2026-10-06

## Goal

Let a script download a member's entire snapshot into a folder, one JSON file per
domain, with a manifest that records what happened. The CLI's `snapshot --all`
uses the same code.

## Decisions

1. Library API plus CLI. `Client#export(dir, domains: Domains::ALL) { |entry| }`
   returns an `Export::Manifest`; `snapshot --all --out-dir DIR` calls it.
   Rationale: scripts need it in Ruby; one implementation, two front doors.
2. Empty domains get a file with `[]` and are listed in the manifest as `empty`.
   Rationale: the folder is always complete; the manifest says what was empty.
3. Every run re-fetches everything and overwrites. No resume in v1.
   Rationale: a snapshot is a point-in-time copy; simplest behavior.
4. One JSON file per domain, rows as an array, named `<DOMAIN>.json`.
   Rationale: matches the current CLI output; easy to load.

## Public interface

```ruby
manifest = client.export("export/")                  # all domains
manifest = client.export("export/", domains: %w[PROFILE CONNECTIONS]) do |entry|
  puts "#{entry.domain}: #{entry.status}"            # :fetching, then :saved / :empty / :failed
end

manifest.entries        # Array<Export::Entry>, one per domain, in request order
manifest.failed         # entries with status :failed
manifest.success?       # failed.empty?
manifest.path           # "export/manifest.json"

Export::Entry = Data.define(:domain, :status, :file, :rows, :error)
#   status: :fetching | :saved | :empty | :failed
#   file:   "CONNECTIONS.json" (relative to dir), nil when :failed
#   rows:   Integer, nil when :failed or :fetching
#   error:  String message, nil unless :failed
```

Behavior:

- `dir` is created with `mkdir_p`. Files are `<DOMAIN>.json`, pretty JSON array
  plus trailing newline (same bytes as the CLI writes today), and `manifest.json`.
- Domains are processed in the given order. For each: yield `:fetching`, fetch
  all rows with `client.snapshot(domain).to_a`, write the file, yield the final
  entry (`:saved` when rows > 0, `:empty` when rows == 0).
- `ApiError` (other than `Unauthorized`/`Forbidden`) and `ConnectionError` on one
  domain produce a `:failed` entry with the message, no file, and the run goes on.
- `Unauthorized` and `Forbidden` stop the run immediately and propagate; a partial
  manifest is still written first so the folder explains itself.
- `SystemCallError` (cannot write) propagates; nothing is swallowed.
- `manifest.json` is written at the end (and before an auth error propagates):

```json
{
  "exported_at": "2026-10-06T18:30:00Z",
  "gem_version": "0.1.1",
  "domains": [
    { "domain": "PROFILE",     "status": "saved",  "file": "PROFILE.json",     "rows": 1 },
    { "domain": "INBOX",       "status": "empty",  "file": "INBOX.json",       "rows": 0 },
    { "domain": "ADS_CLICKED", "status": "failed", "error": "HTTP 500" }
  ]
}
```

- Domain names are normalized like `Client#snapshot` (symbols upcased, strings
  verbatim). An unknown-type domain raises `ArgumentError` before any request.

## Components

```
lib/linkedin/member_data/export.rb          # Export: run, write files, build manifest
lib/linkedin/member_data/export/entry.rb    # Export::Entry (Data)
lib/linkedin/member_data/export/manifest.rb # Export::Manifest (entries, failed, success?, path, to_h, write)
lib/linkedin/member_data/client.rb          # Client#export
lib/linkedin/member_data/cli/snapshot_command.rb  # --all delegates to Export
examples/export.rb                           # script: export everything with progress
```

CLI `snapshot --all --out-dir DIR`: calls `client.export(dir)` with a progress
block that prints `Fetching X...` on `:fetching` and `X: <message>` on `:failed`
to stderr. Exit 0 when `manifest.success?`, else 1. Auth errors propagate to the
usual exit-1 handling. Output lines stay as they are today, so existing tests
keep passing.

## Testing

- `Export` tests with the `FakeTransport`-backed `fake_client`: file bytes equal
  `JSON.pretty_generate(rows) + "\n"`, empty domain file is `[]`, manifest
  content and order, `:fetching` then final status order of yields, per-domain
  failure recorded and run continues, `Unauthorized` stops and still writes the
  manifest, `domains:` subset and symbol normalization, `ArgumentError` for a bad
  domain type before any request.
- CLI tests: `--all` keeps its current stderr lines and exit codes; manifest file
  exists after a run.
- Package test: new files ship. YARD docs on every public method; `rake docs`.

## Out of scope

- Resume or incremental export, CSV, per-page files, parallel fetching.
