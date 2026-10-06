# linkedin-member-data

Ruby client and CLI for the LinkedIn [Member Data Portability (Member) API](https://learn.microsoft.com/en-us/linkedin/dma/member-data-portability/member-data-portability-member/). Download your own LinkedIn data: 66 snapshot domains (profile, connections, messages, posts, ...) and the changelog of your activity from the last 28 days.

Zero runtime dependencies. Ruby 3.2+.

## Installation

```bash
bundle add linkedin-member-data
```

Or install the CLI only:

```bash
gem install linkedin-member-data
```

## Getting a token

1. Create an app in the [LinkedIn Developer Portal](https://www.linkedin.com/developers/apps/) using the [Member Data Portability (Member) Default Company](https://www.linkedin.com/company/member-data-portability-member-default-company) page.
2. Under Products, request access to **Member Data Portability API (Member)**.
3. Open **Docs and tools > OAuth Token Tools**, create a token with scope `r_dma_portability_self_serve`, and consent.

Tokens last 60 days. Only EEA and Swiss members can consent today.

## Quick start

```ruby
require "linkedin/member_data"

client = LinkedIn::MemberData::Client.new(access_token: ENV["LINKEDIN_ACCESS_TOKEN"])

client.snapshot(:connections).each do |row|
  puts row["First Name"], row["Company"]
end

client.changelog(since: Time.now - 7 * 86_400).each do |event|
  puts "#{event.method} #{event.resource_name} at #{event.processed_at}"
end
```

Row keys differ per domain. These are CONNECTIONS keys.

## Snapshot

```ruby
snap = client.snapshot(:profile)       # symbol is upcased: "PROFILE"
snap = client.snapshot("ALL_COMMENTS") # strings are sent as given
snap = client.snapshot                 # all domains

snap.first                             # first row, fetches one page
snap.to_a                              # every row, walks all pages
snap.lazy.select { |row| row["Company"] }.first(5)  # Enumerable, so anything goes

snap.pages.each do |page|
  page.domain; page.rows; page.start; page.count; page.total; page.next?; page.raw
end

snap.page(0)                           # one page by index, no walking. Raises past the end.

LinkedIn::MemberData::Domains::ALL     # list of domain names
```

Rows are plain Hashes with the keys LinkedIn returns, for example `"First Name"`. Keys differ per domain.

Pages are walked until LinkedIn answers "No data found for this memberId". That answer ends iteration and is not raised. A page with no rows also ends iteration.

## Changelog

```ruby
log = client.changelog(since: Date.new(2026, 9, 1), count: 10)   # since: Time, Date or epoch ms; count: 1..50

log.each do |event|
  event.id; event.method; event.resource_name; event.resource_id
  event.captured_at; event.processed_at        # Time (UTC)
  event.activity; event.processed_activity     # Hash
  event.raw                                    # the original Hash
end

log.pages.each { |page| page.events; page.next_start_time }
```

The API returns the cursor event again on the next page. The gem skips events it has already seen. Iteration stops when a page has no new events, or when the last event has no `processedAt`.

`event.method` is the API field (`CREATE`, `UPDATE`, ...). It shadows Ruby's `Object#method` on purpose, so `event.method(:name)` does not work on an Event.

`count` defaults to 10. A value outside 1..50 raises `ArgumentError` before any request.

Event fields: `id, activity_id, activity_status, config_version, owner, actor, resource_name, resource_id, resource_uri, method, method_name, captured_at, processed_at, activity, processed_activity, sibling_activities, parent_sibling_activities, raw`.

Known limit: when more than `count` events share one `processedAt`, the cursor cannot reach the rest. Raise `count` (max 50) to reduce the chance.

To resume later, store the last `event.processed_at_ms` and pass it as `since:`.

```ruby
last_seen = client.changelog.to_a.last&.processed_at_ms
client.changelog(since: last_seen).each { |event| puts event.id }
```

## Authorization

```ruby
client.authorization        # => Authorization or nil
client.authorization.regulated_at
client.enable_changelog!    # start changelog archiving (usually automatic)
```

`Authorization` also has `member`, `developer_application`, `scopes` and `raw`.

## Options

```ruby
require "logger"

LinkedIn::MemberData::Client.new(
  access_token: "...",
  retries: 3,       # retries on 429, 5xx and network errors, with backoff; 0 disables
  timeout: 30,      # seconds
  logger: Logger.new($stderr)  # logs "GET url -> status" at debug level
)
```

Retries wait for `Retry-After` when it is present, capped at 60 seconds. Otherwise the wait grows with each try (exponential backoff).

## Errors

```
LinkedIn::MemberData::Error
  ConfigurationError           # missing token
  ConnectionError              # network failure after retries
  ApiError                     # status, code, body
    Unauthorized Forbidden NotFound VersionError RateLimited ServerError
```

`ConnectionError` covers timeouts, reset connections, DNS and TLS failures. `retryable?` is true for `RateLimited`, `ServerError` and `ConnectionError`. `ApiError#code` comes from `serviceErrorCode` or `code` in the response body. `RateLimited#retry_after` is nil when the header is absent.

```ruby
begin
  client.snapshot(:profile).to_a
rescue LinkedIn::MemberData::Unauthorized
  warn "Token is invalid or expired"
rescue LinkedIn::MemberData::ApiError => error
  warn "#{error.status}: #{error.message}"
end
```

## CLI

```bash
export LINKEDIN_ACCESS_TOKEN=...

linkedin-member-data snapshot CONNECTIONS --out connections.json
linkedin-member-data snapshot --all --out-dir ./export
linkedin-member-data changelog --since 2026-09-01 --count 50 --out changelog.json
linkedin-member-data domains
linkedin-member-data auth
linkedin-member-data version
```

Use `-h` or `--help` to print usage. The DOMAIN argument is upcased, so `snapshot connections` works. The token comes from `--token TOKEN` (before the command) or `LINKEDIN_ACCESS_TOKEN`. Data goes to stdout or `--out FILE`. Progress and errors go to stderr. `--since` takes an ISO date (midnight UTC) or an ISO datetime.

`snapshot --all` writes one `<DOMAIN>.json` per domain. Without `--out-dir DIR` it is a usage error (exit 2). A failing domain is reported and the run continues. The exit code is 1 at the end. Unauthorized and Forbidden stop the run, because a bad token fails every domain.

`auth` exits 1 with "No authorization found for this token" when none exists.

Exit codes: 0 success, 1 API error, network error or file write error, 2 usage error.

## Development

```bash
bin/setup
bundle exec rake               # tests + rubocop
bundle exec rake branchproof   # MC/DC coverage (Ruby 4.0+)
bundle exec rake quality       # quality_gate fast, verify, audit
```

## License

MIT
