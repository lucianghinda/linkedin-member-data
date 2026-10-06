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

Tokens last 60 days. At the time of writing, only members in the EEA and Switzerland can consent.

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

snap.page(0)                           # one page by index, no walking

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

Known limit: if more than `count` events share one `processedAt`, the extra events cannot be reached with the cursor. Use a larger `count` (up to 50) if you see this.

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

Retries wait for the `Retry-After` header when LinkedIn sends one. The wait is capped at 60 seconds. Otherwise the wait grows with each try (exponential backoff).

## Errors

```
LinkedIn::MemberData::Error
  ConfigurationError           # missing token
  ConnectionError              # network failure after retries
  ApiError                     # status, code, body
    Unauthorized Forbidden NotFound VersionError RateLimited ServerError
```

`ConnectionError` covers timeouts, reset connections, DNS and TLS failures. `RateLimited` also has `retry_after` (seconds or nil).

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

The token comes from `--token TOKEN` (before the command) or `LINKEDIN_ACCESS_TOKEN`. Data goes to stdout or `--out FILE`. Progress and errors go to stderr. `--since` takes an ISO date (midnight UTC) or an ISO datetime.

`snapshot --all` needs `--out-dir DIR` and writes one `<DOMAIN>.json` per domain. A domain that fails is reported and the run goes on, and the exit code is 1 at the end. The run stops at once on `Unauthorized` or `Forbidden`, because a bad token fails every domain.

Exit codes: 0 success, 1 API or network error, 2 usage error.

## Development

```bash
bin/setup
bundle exec rake               # tests + rubocop
bundle exec rake branchproof   # MC/DC coverage (Ruby 4.0+)
bundle exec rake quality       # quality_gate fast, verify, audit
```

## License

MIT
