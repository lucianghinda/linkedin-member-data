# Module LinkedIn::MemberData::Domains <a id="module-LinkedIn-MemberData-Domains"></a>

|  |  |
| --- | --- |
| **Defined in** | lib/linkedin/member_data/domains.rb |

Snapshot domains documented at
https://learn.microsoft.com/en-us/linkedin/dma/member-data-portability/shared/
snapshot-domain The API is case sensitive. Strings are sent as given; symbols
are upcased.

## Constants
### `ALL` <a id="constant-ALL"></a> <a id="ALL-constant"></a>
Names of all snapshot domains. Pass one to `Client#snapshot`.
- **@return** [Array<String>]

## Public Class Methods
### `normalize(domain)` <a id="method-c-normalize"></a> <a id="normalize-class_method"></a>
Turns a domain argument into the name sent to the API.
- **@param** `domain` [Symbol, String, nil] a Symbol is upcased. A String is returned as given. `nil` stays `nil`.
- **@raise** [ArgumentError] when `domain` is not a Symbol, a String or nil.
- **@return** [String, nil]
