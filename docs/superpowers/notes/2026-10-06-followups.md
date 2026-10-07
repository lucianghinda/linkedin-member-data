# Follow-ups noted during implementation

Items raised by reviewers that were deliberately deferred. Revisit before 0.1.0.

- Errors: `ApiError` and subclasses require a positional message and `status:`.
  A bare `raise LinkedIn::MemberData::Unauthorized` fails with ArgumentError.
  Decide whether to allow `message = nil, status: nil` for user-raised errors
  or document that these classes are built by `ApiError.from_response`.
- Errors: a JSON body with `"message": null` yields a nil message instead of
  the `HTTP <status>` fallback. Consider a String check in `message_from`.
- Errors: `Retry-After` may be an HTTP-date; `.to_i` then gives 0. Treat 0 or
  nil as "use backoff" in `Connection`.
- Tooling: the `rubocop` timeout in `.quality_gate.yml` is 10s (generated
  default). Raise it if CI cold caches time out.
- Connection: POST requests are retried on 5xx/timeouts like GETs. Only
  `POST /rest/memberAuthorizations` (idempotent) exists today. Revisit if a
  non-idempotent write is ever added.
- Connection: debug log lines include the query string. Fine for now; mask if
  member ids ever appear in queries.
- Connection: no `Accept: application/json` header is sent. Add if LinkedIn
  ever starts content negotiation.
- CLI: `snapshot --help` (per-command help) is not handled; it exits 2 as an
  unknown option. Add per-command banners and `-h` if users ask.
- CLI: leftover positional arguments are ignored (`domains extra`,
  `snapshot A B`). Consider raising a usage error.
- CLI: `--all` with `--out`, or DOMAIN with `--out-dir`, is silently ignored.
- CLI: `rescue ArgumentError` maps every ArgumentError to a usage error
  (exit 2). Narrow it later with dedicated subclasses (for example
  `Changelog::InvalidCount < ArgumentError`) or validate `--count` and
  DOMAIN in the CLI before calling the library.
- Export: rows of one domain are held in memory (`to_a`) and then pretty
  printed, so a large domain such as INBOX peaks at about twice its size.
  A follow-up could stream pages into the JSON array file.
