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
