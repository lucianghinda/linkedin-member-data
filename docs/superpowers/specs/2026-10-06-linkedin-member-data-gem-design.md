# linkedin-member-data gem design

Date: 2026-10-06

## Goal

A small Ruby gem with a good developer experience for the LinkedIn
Member Data Portability (Member) API:
https://learn.microsoft.com/en-us/linkedin/dma/member-data-portability/member-data-portability-member/?view=li-dma-data-portability-2026-08

Users of the gem are LinkedIn members (EEA/Switzerland) who want to download
their own data, and developers who build tools on top of that data.

## API facts that shape the design

- Base URL `https://api.linkedin.com`. Three endpoints only:
  - `GET /rest/memberSnapshotData?q=criteria&domain=<DOMAIN>&start=<n>`
    (66 domains, paginated)
  - `GET /rest/memberChangeLogs?q=memberAndApplication&startTime=<epoch_ms>&count=<1..50>`
    (events from the last 28 days)
  - `GET /rest/memberAuthorizations?q=memberAndApplication` and
    `POST /rest/memberAuthorizations` with body `{}`
- Header `Linkedin-Version: 202312` is mandatory. Any other value returns
  `426 NONEXISTENT_VERSION`. The gem hardcodes it and does not expose it.
- Snapshot `paging.total` is unreliable. Keep requesting `start+1` until the
  API returns an error whose message contains "No data found for this
  memberId". That error means end of data, not failure.
- Snapshot `elements` always has one element:
  `{ "snapshotDomain": "PROFILE", "snapshotData": [rows] }`.
  Rows are hashes with human readable keys that differ per domain.
- Changelog events have a fixed schema: `id`, `capturedAt`, `processedAt`,
  `owner`, `actor`, `resourceName`, `resourceId`, `resourceUri`, `method`,
  `methodName`, `activity`, `processedActivity`, `siblingActivities`,
  `parentSiblingActivities`, `activityId`, `activityStatus`, `configVersion`.
- Changelog cursoring: next `startTime` = latest `processedAt` of the
  previous page. The event at the cursor is returned again on the next page.
  Recommended `count=10`, max 50. `count` outside 1..50 returns 400.
- Tokens for the Member product come from the Developer Portal OAuth tool
  (scope `r_dma_portability_self_serve`). Tokens live 60 days.

## Decisions

1. Gem name `linkedin-member-data`, namespace `LinkedIn::MemberData`,
   require path `linkedin/member_data`.
   Rationale: matches the product name, short to type. The scaffold
   `linkedin-members-apis` / `Linkedin::Members::Apis` is renamed, including
   the directory `gems/linkedin-members-apis` -> `gems/linkedin-member-data`.
2. HTTP via `Net::HTTP`, zero runtime dependencies.
   Rationale: three calls do not need an adapter; easy to install anywhere.
3. Token only in v1. No OAuth helpers.
   Rationale: Member product tokens come from the portal tool. OAuth can be
   added later without changing the client interface.
4. Snapshot rows are plain `Hash`. Changelog events are `Data` objects.
   Rationale: snapshot keys vary per domain; changelog schema is fixed.
5. Development tooling: `branchproof` and `quality_gate` in the development
   group, both wired into Rake and CI.
6. Pagination: lazy `Enumerable` of rows/events; `.pages` exposes raw pages
   with paging info.
   Rationale: `each`/`first`/`to_a` is the Ruby way; big domains like INBOX
   stay memory-safe.
7. Bounded retry with exponential backoff on 429 and 5xx, honoring
   `Retry-After`. Default 3 retries, `retries: 0` disables. Raises
   `RateLimited` or `ServerError` after exhausting.
   Rationale: page loops hit rate limits; callers should not re-implement this.
8. Ship a small CLI (`exe/linkedin-member-data`) built on `OptionParser` only.
   Rationale: the main use case is "download my data"; a CLI makes that a
   one-liner.
9. `changelog(since:)` accepts `Time`, `Date`, or `Integer` epoch milliseconds.
   `Event#processed_at` and `#captured_at` return `Time`.
   Rationale: friendly input, exact cursoring via `processed_at`.
10. Architecture: `Client` + small resource objects (`Snapshot`, `Changelog`,
    `Authorization`) + one `Connection` for HTTP.
    Rationale: each file has one job and is testable with a fake transport.
    Rejected: one fat `Client` (two pagination rules in one class), and
    dynamic per-domain methods (66 generated methods, hard to document and
    brittle when LinkedIn adds a domain).
11. Ruby `>= 3.2` (needed for `Data.define`).

## Public interface

```ruby
require "linkedin/member_data"

client = LinkedIn::MemberData::Client.new(
  access_token: ENV["LINKEDIN_ACCESS_TOKEN"],  # required; ConfigurationError if nil/empty
  retries: 3,                                  # 0 disables
  timeout: 30,                                 # seconds, open and read
  logger: nil                                  # any Logger-like; logs request line + status at debug
)

# Snapshot
client.snapshot(:connections)          # => Snapshot (Enumerable, lazy); symbol upcased to "CONNECTIONS"
client.snapshot("MEMBER_SHARE_INFO")   # strings passed through as-is
client.snapshot                        # no domain param: API returns all domains
snap.each { |row| row["First Name"] }  # rows are Hashes
snap.first(5); snap.to_a; snap.lazy.map { ... }
snap.domain                            # => "CONNECTIONS" or nil
snap.pages.each { |page| page.domain; page.rows; page.start; page.next?; page.raw }
LinkedIn::MemberData::Domains::ALL     # frozen Array of the 66 domain strings

# Changelog
client.changelog(since: Time.now - 86_400, count: 10)   # since: optional; count: 1..50, default 10
log.each { |event| event.resource_name; event.method; event.processed_at }
log.pages.each { |page| page.events; page.next_start_time }

# Authorizations
client.authorization        # => Authorization or nil when elements is empty
client.enable_changelog!    # POST memberAuthorizations with {} ; returns true
```

Domain argument rules: a `Symbol` is converted with `to_s.upcase`; a `String`
is used verbatim. The gem does not validate against `Domains::ALL`, so new
LinkedIn domains work without a gem release. `Domains::ALL` exists for
discovery and for the CLI `--all` mode.

## Components

```
lib/linkedin/member_data.rb            # requires, top-level module, VERSION
lib/linkedin/member_data/version.rb
lib/linkedin/member_data/client.rb     # config + factory for resources
lib/linkedin/member_data/connection.rb # Net::HTTP, headers, JSON, errors, retries
lib/linkedin/member_data/errors.rb
lib/linkedin/member_data/domains.rb    # Domains::ALL
lib/linkedin/member_data/snapshot.rb   # Snapshot, Snapshot::Page
lib/linkedin/member_data/changelog.rb  # Changelog, Changelog::Page
lib/linkedin/member_data/event.rb      # Event = Data.define(...)
lib/linkedin/member_data/authorization.rb
lib/linkedin/member_data/cli.rb
exe/linkedin-member-data
```

### Client

Holds `access_token`, `retries`, `timeout`, `logger`. Builds one `Connection`.
Methods: `snapshot(domain = nil)`, `changelog(since: nil, count: 10)`,
`authorization`, `enable_changelog!`. Accepts an optional `connection:`
keyword for tests.

### Connection

- `get(path, params)` and `post(path, body)` return parsed JSON (`Hash`).
- Headers: `Authorization: Bearer <token>`, `Linkedin-Version: 202312`,
  `X-Restli-Protocol-Version: 2.0.0`, `Content-Type: application/json`,
  `User-Agent: linkedin-member-data/<VERSION>`.
- Status mapping: 2xx returns body; 401 `Unauthorized`; 403 `Forbidden`;
  404 `NotFound`; 426 `VersionError`; 429 `RateLimited`; 5xx `ServerError`;
  other 4xx `ApiError`.
- Retry: on 429 and 5xx, and on `Net::OpenTimeout`/`Net::ReadTimeout`/
  `Errno::ECONNRESET`, up to `retries` times. Sleep `Retry-After` seconds when
  present, else `0.5 * 2**attempt` with jitter. After the last attempt the
  mapped error is raised.
- Errors carry `status`, `code` (from body `serviceErrorCode`/`code` when
  present), `message` (from body `message`), and `body` (raw parsed Hash).
- Transport is injectable (`transport:`) so tests never open sockets.

### Snapshot

`Snapshot.new(connection, domain)` includes `Enumerable`.

- `each` walks pages from `start=0` and yields each row of `snapshotData` from every element (docs say one element per page, but the all-domains call is not documented, so iterate all).
- `pages` returns an `Enumerator` of `Snapshot::Page`.
- Stop rule: stop after a page whose `paging.links` has no `rel: "next"`,
  when a page has no rows (such a page is not emitted; this guards against an
  endless chain of `next` links), or when the next request raises an
  `ApiError` whose message includes "No data found for this memberId". That
  error is swallowed inside `each` and `pages`.
- `Snapshot::Page` is a `Data` with `domain`, `rows`, `start`, `count`,
  `total`, `next?`, `raw`.

### Changelog

`Changelog.new(connection, since:, count:)` includes `Enumerable`.

- `since` is normalized to epoch milliseconds: `Time` -> `(t.to_f * 1000).to_i`,
  `Date` -> midnight UTC, `Integer` -> as-is, `nil` -> omitted.
- `count` outside 1..50 raises `ArgumentError` before any request.
- `each` fetches a page, yields events, then sets `startTime` to the last
  event's `processedAt`. Events whose `id` appeared on the previous page are
  skipped (cursor overlap; several events can share a `processedAt`). Stops
  when a page has no new events.
- `pages` returns an `Enumerator` of `Changelog::Page` with `events`,
  `next_start_time`, `raw`.

### Event

`Data.define` with snake_case members for every documented field.
`captured_at` and `processed_at` are `Time` (UTC). `activity`,
`processed_activity`, `sibling_activities`, `parent_sibling_activities` stay
raw `Hash`/`Array`. `Event.from_api(hash)` builds it; unknown keys are
ignored, missing keys become `nil`. `raw` keeps the original Hash.

### Authorization

`Data.define(:member, :developer_application, :regulated_at, :scopes, :raw)`.
`regulated_at` is a `Time`. Built from `elements.first`.

### CLI

```
linkedin-member-data snapshot DOMAIN [--out FILE]        # JSON array of rows to FILE or stdout
linkedin-member-data snapshot --all --out-dir DIR        # one <DOMAIN>.json per domain in Domains::ALL
linkedin-member-data changelog [--since DATE] [--count N] [--out FILE]
linkedin-member-data domains                             # one domain per line
linkedin-member-data auth                                # prints authorization as JSON
linkedin-member-data version
```

Token from `--token TOKEN` or `LINKEDIN_ACCESS_TOKEN`. Progress goes to
stderr, data to stdout or the file. Exit codes: 0 success, 1 API error
(message printed to stderr), 2 usage or configuration error. In `--all`
mode a failing domain is reported to stderr and the run continues; exit 1
at the end if any domain failed.

## Error hierarchy

```
LinkedIn::MemberData::Error < StandardError
  ConfigurationError            # missing or empty token
  ApiError                      # attrs: status, code, message, body
    Unauthorized   (401)
    Forbidden      (403)
    NotFound       (404)
    VersionError   (426)
    RateLimited    (429)        # attr: retry_after
    ServerError    (5xx)
```

## Testing

- Minitest, no live HTTP. `Connection` takes a `transport:` object that
  responds to `call(Net::HTTPRequest) -> response-like (code, body, headers)`.
  Tests use a `FakeTransport` that queues canned responses and records
  requests.
- Fixtures under `test/fixtures/*.json` copied from the docs: snapshot
  PROFILE page, paginated page with next/prev, "No data found" error,
  changelog page, authorization response.
- Cover: header set, status to error mapping, retry on 429 with
  `Retry-After`, retries exhausted, snapshot stop rules (no next link and
  "No data found"), changelog cursor and overlap skip, `since:` conversions,
  `count` validation, `Event` time conversion, CLI argument parsing and exit
  codes (CLI tests inject a fake client).
- `branchproof` with `minimum mcdc=90` on `lib/**/*.rb`.
- `quality_gate init --profile ruby`; `fast`, `verify`, `audit` run in CI.
- GitHub Actions: matrix Ruby 3.2, 3.3, 3.4, 4.0; steps: test, branchproof,
  quality_gate.

## Out of scope for v1

- OAuth authorization code flow and token refresh.
- Typed models per snapshot domain.
- Persisting or diffing exports.
- The `r_dma_portability_3rd_party` product specifics (same endpoints, so
  the gem works with those tokens, but no extra support).
