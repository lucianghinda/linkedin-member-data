# Class LinkedIn::MemberData::RateLimited <a id="class-LinkedIn-MemberData-RateLimited"></a>

|  |  |
| --- | --- |
| **Inherits** | [LinkedIn::MemberData::ApiError](ApiError.md) |
| **Defined in** | lib/linkedin/member_data/errors.rb |

HTTP 429. Retryable.

## Attributes
### `retry_after` [R] <a id="attribute-i-retry_after"></a> <a id="retry_after-instance_method"></a>
Seconds to wait, from the <code>Retry-After</code> header.
- **@return** [Integer, nil] `nil` when the header is absent, is not a positive number, or is an HTTP date.

## Public Instance Methods
### `initialize(message, status:, code: = nil, body: = nil, retry_after: = nil)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@param** `message` [String] error message.
- **@param** `status` [Integer] HTTP status code.
- **@param** `code` [Integer, String, nil] error code from the body.
- **@param** `body` [Hash, nil] parsed response body.
- **@param** `retry_after` [Integer, nil] seconds from the `Retry-After` header.
- **@return** [RateLimited] a new instance of RateLimited

### `retryable?()` <a id="method-i-retryable-3F"></a> <a id="retryable?-instance_method"></a>
- **@return** [true] a rate limit is worth a retry.
