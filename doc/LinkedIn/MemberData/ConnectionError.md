# Class LinkedIn::MemberData::ConnectionError <a id="class-LinkedIn-MemberData-ConnectionError"></a>

|  |  |
| --- | --- |
| **Inherits** | [LinkedIn::MemberData::Error](Error.md) |
| **Defined in** | lib/linkedin/member_data/errors.rb |

Network failure after all retries (timeouts, reset connections).

## Public Instance Methods
### `retry_after()` <a id="method-i-retry_after"></a> <a id="retry_after-instance_method"></a>
- **@return** [nil] there is no Retry-After header, so the backoff decides.

### `retryable?()` <a id="method-i-retryable-3F"></a> <a id="retryable?-instance_method"></a>
- **@return** [true] network errors are worth a retry.
