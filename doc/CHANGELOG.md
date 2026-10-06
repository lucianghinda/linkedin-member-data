## [Unreleased]

- README: step-by-step guide to request API access and generate a token.

## [0.1.1] - 2026-10-06

- Reject changelog counts outside 2..50 so a count of 1 cannot silently truncate iteration at the cursor event.
- Disable Net::HTTP's internal retries so the client's `retries` setting controls all attempts.
- Reject negative and noninteger retry counts before any request instead of silently skipping requests.

## [0.1.0] - 2026-10-06

- Initial release: Client, Snapshot, Changelog, Authorization, CLI.
- Retries on 429, 5xx and network errors. `Retry-After` is capped at 60 seconds.
- `ConnectionError` for network failures after retries.
- `Changelog` skips the overlap event and resumes with `Event#processed_at_ms`.
- CLI exit codes: 0 success, 1 API error, 2 usage error.
