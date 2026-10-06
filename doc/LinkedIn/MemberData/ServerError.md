# Class LinkedIn::MemberData::ServerError <a id="class-LinkedIn-MemberData-ServerError"></a>

|  |  |
| --- | --- |
| **Inherits** | [LinkedIn::MemberData::ApiError](ApiError.md) |
| **Defined in** | lib/linkedin/member_data/errors.rb |

HTTP 5xx. Retryable.

## Public Instance Methods
### `retryable?()` <a id="method-i-retryable-3F"></a> <a id="retryable?-instance_method"></a>
- **@return** [true] server errors are worth a retry.
