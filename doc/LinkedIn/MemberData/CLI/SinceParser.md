# Class LinkedIn::MemberData::CLI::SinceParser <a id="class-LinkedIn-MemberData-CLI-SinceParser"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/cli/since_parser.rb |

Reads --since: an ISO datetime, or an ISO date (midnight UTC).

- **@api** private

## Public Class Methods
### `call(value)` <a id="method-c-call"></a> <a id="call-class_method"></a>
- **@api** private
- **@param** `value` [String] ISO 8601 datetime or date.
- **@raise** [UsageError] when `value` is neither.
- **@return** [Time]
