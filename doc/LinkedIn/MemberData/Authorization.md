# Class LinkedIn::MemberData::Authorization <a id="class-LinkedIn-MemberData-Authorization"></a>

|  |  |
| --- | --- |
| **Inherits** | Data |
| **Defined in** | lib/linkedin/member_data/authorization.rb |

The member's authorization record from `memberAuthorizations`. Immutable.

## Attributes
### `developer_application` [R] <a id="attribute-i-developer_application"></a> <a id="developer_application-instance_method"></a>
- **@return** [String, nil] developer application, as sent by the API.

### `member` [R] <a id="attribute-i-member"></a> <a id="member-instance_method"></a>
- **@return** [String, nil] member, as sent by the API.

### `raw` [R] <a id="attribute-i-raw"></a> <a id="raw-instance_method"></a>
- **@return** [Hash] the original element from the API.

### `regulated_at` [R] <a id="attribute-i-regulated_at"></a> <a id="regulated_at-instance_method"></a>
- **@return** [Time, nil] when the member gave consent. UTC.

### `scopes` [R] <a id="attribute-i-scopes"></a> <a id="scopes-instance_method"></a>
- **@return** [Array<String>] granted scopes. Empty when the API sends none.

## Public Class Methods
### `from_api(hash)` <a id="method-c-from_api"></a> <a id="from_api-class_method"></a>
Builds an authorization from one element of the API response.
- **@param** `hash` [Hash] one element of `elements` from the `memberAuthorizations` response.
- **@return** [Authorization]
