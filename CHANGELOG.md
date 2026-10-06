## [Unreleased]

## [0.1.0] - 2026-10-06

- Initial release: Client, Snapshot, Changelog, Authorization, CLI.
- Retries on 429, 5xx and network errors. `Retry-After` is capped at 60 seconds.
- `ConnectionError` for network failures after retries.
- `Changelog` skips the overlap event and resumes with `Event#processed_at_ms`.
- CLI exit codes: 0 success, 1 API error, 2 usage error.
