# Class LinkedIn::MemberData::Changelog::Page <a id="class-LinkedIn-MemberData-Changelog-Page"></a>

|  |  |
| --- | --- |
| **Inherits** | Data |
| **Defined in** | lib/linkedin/member_data/changelog/page.rb |

One response page of changelog events. Immutable.

## Attributes
### `events` [R] <a id="attribute-i-events"></a> <a id="events-instance_method"></a>
- **@return** [Array<Event>] events of this page, in API order (oldest first).

### `raw` [R] <a id="attribute-i-raw"></a> <a id="raw-instance_method"></a>
- **@return** [Hash] the parsed response body.

## Public Class Methods
### `from_api(raw)` <a id="method-c-from_api"></a> <a id="from_api-class_method"></a>
Builds a page from a parsed response body. A missing `elements` key gives no
events.
- **@param** `raw` [Hash] parsed JSON body of the API response.
- **@return** [Changelog::Page]

## Public Instance Methods
### `next_start_time()` <a id="method-i-next_start_time"></a> <a id="next_start_time-instance_method"></a>
Cursor for the next request: `processedAt` of the last event, in epoch
milliseconds.
- **@return** [Integer, nil] `nil` when the page has no events or the last event has no `processedAt`.
