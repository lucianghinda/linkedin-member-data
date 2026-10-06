# Class LinkedIn::MemberData::ApiError <a id="class-LinkedIn-MemberData-ApiError"></a>

|  |  |
| --- | --- |
| **Inherits** | [LinkedIn::MemberData::Error](Error.md) |
| **Defined in** | lib/linkedin/member_data/errors.rb |

Defined last because the classes must exist first.

## Constants
### `STATUS_CLASSES` <a id="constant-STATUS_CLASSES"></a> <a id="STATUS_CLASSES-constant"></a>
HTTP status => error class. Other statuses use `ServerError` (5xx) or
`ApiError`.
- **@api** private

## Attributes
### `body` [R] <a id="attribute-i-body"></a> <a id="body-instance_method"></a>
Details of the failed response. `status` is the HTTP status code (Integer).
`code` is `serviceErrorCode` or `code` from the body (Integer or String, nil
when the body has neither). `body` is the parsed JSON body (nil when the body
is empty, not JSON, or not an object).
- **@return** [Integer, String, Hash, nil] `status`, `code` or `body`.

### `code` [R] <a id="attribute-i-code"></a> <a id="code-instance_method"></a>
Details of the failed response. `status` is the HTTP status code (Integer).
`code` is `serviceErrorCode` or `code` from the body (Integer or String, nil
when the body has neither). `body` is the parsed JSON body (nil when the body
is empty, not JSON, or not an object).
- **@return** [Integer, String, Hash, nil] `status`, `code` or `body`.

### `status` [R] <a id="attribute-i-status"></a> <a id="status-instance_method"></a>
Details of the failed response. `status` is the HTTP status code (Integer).
`code` is `serviceErrorCode` or `code` from the body (Integer or String, nil
when the body has neither). `body` is the parsed JSON body (nil when the body
is empty, not JSON, or not an object).
- **@return** [Integer, String, Hash, nil] `status`, `code` or `body`.

## Public Instance Methods
### `initialize(message, status:, code: = nil, body: = nil)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@param** `message` [String] `message` from the body, or "HTTP <status>".
- **@param** `status` [Integer] HTTP status code.
- **@param** `code` [Integer, String, nil] error code from the body.
- **@param** `body` [Hash, nil] parsed response body.
- **@return** [ApiError] a new instance of ApiError

### `retry_after()` <a id="method-i-retry_after"></a> <a id="retry_after-instance_method"></a>
Only RateLimited knows a Retry-After. Others let the backoff decide.
- **@return** [nil]

### `retryable?()` <a id="method-i-retryable-3F"></a> <a id="retryable?-instance_method"></a>
Tells if a retry may help. False for most API errors.
- **@return** [Boolean]
