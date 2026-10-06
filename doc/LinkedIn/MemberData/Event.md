# Class LinkedIn::MemberData::Event <a id="class-LinkedIn-MemberData-Event"></a>

|  |  |
| --- | --- |
| **Inherits** | Data |
| **Defined in** | lib/linkedin/member_data/event.rb |

One Member Changelog event. Immutable. Times are UTC. `activity` and friends
stay raw. Fields missing in the API response are `nil`.

`method` is the API field (`CREATE`, `UPDATE`, ...). It shadows Ruby's
`Object#method` on purpose, so `event.method(:name)` does not work on an
Event.

## Attributes
### `activity` [R] <a id="attribute-i-activity"></a> <a id="activity-instance_method"></a>
- **@return** [Hash, nil] raw activity payload.

### `activity_id` [R] <a id="attribute-i-activity_id"></a> <a id="activity_id-instance_method"></a>
- **@return** [String, nil] value as sent by the API.

### `activity_status` [R] <a id="attribute-i-activity_status"></a> <a id="activity_status-instance_method"></a>
- **@return** [String, nil] value as sent by the API.

### `actor` [R] <a id="attribute-i-actor"></a> <a id="actor-instance_method"></a>
- **@return** [String, nil] who did the action, as sent by the API.

### `captured_at` [R] <a id="attribute-i-captured_at"></a> <a id="captured_at-instance_method"></a>
- **@return** [Time, nil] when LinkedIn captured the event. UTC.

### `config_version` [R] <a id="attribute-i-config_version"></a> <a id="config_version-instance_method"></a>
- **@return** [Object, nil] value as sent by the API.

### `id` [R] <a id="attribute-i-id"></a> <a id="id-instance_method"></a>
- **@return** [String, nil] event id. Used to skip events seen on the previous page.

### `method` [R] <a id="attribute-i-method"></a> <a id="method-instance_method"></a>
- **@return** [String, nil] API method, for example `CREATE` or `UPDATE`.

### `method_name` [R] <a id="attribute-i-method_name"></a> <a id="method_name-instance_method"></a>
- **@return** [String, nil] value as sent by the API.

### `owner` [R] <a id="attribute-i-owner"></a> <a id="owner-instance_method"></a>
- **@return** [String, nil] owner of the event, as sent by the API.

### `parent_sibling_activities` [R] <a id="attribute-i-parent_sibling_activities"></a> <a id="parent_sibling_activities-instance_method"></a>
- **@return** [Array<Hash>, nil] raw parent sibling activities.

### `processed_activity` [R] <a id="attribute-i-processed_activity"></a> <a id="processed_activity-instance_method"></a>
- **@return** [Hash, nil] raw processed activity payload.

### `processed_at` [R] <a id="attribute-i-processed_at"></a> <a id="processed_at-instance_method"></a>
- **@return** [Time, nil] when LinkedIn processed the event. UTC. Used as the cursor.

### `raw` [R] <a id="attribute-i-raw"></a> <a id="raw-instance_method"></a>
- **@return** [Hash] the original event Hash from the API.

### `resource_id` [R] <a id="attribute-i-resource_id"></a> <a id="resource_id-instance_method"></a>
- **@return** [String, nil] value as sent by the API.

### `resource_name` [R] <a id="attribute-i-resource_name"></a> <a id="resource_name-instance_method"></a>
- **@return** [String, nil] kind of resource that changed.

### `resource_uri` [R] <a id="attribute-i-resource_uri"></a> <a id="resource_uri-instance_method"></a>
- **@return** [String, nil] value as sent by the API.

### `sibling_activities` [R] <a id="attribute-i-sibling_activities"></a> <a id="sibling_activities-instance_method"></a>
- **@return** [Array<Hash>, nil] raw sibling activities.

## Public Class Methods
### `from_api(hash)` <a id="method-c-from_api"></a> <a id="from_api-class_method"></a>
Builds an event from one element of the API response.
- **@param** `hash` [Hash] one element of `elements` from the changelog response.
- **@return** [Event]

**@example**
```ruby
event = LinkedIn::MemberData::Event.from_api(
  "id" => "1", "method" => "CREATE", "processedAt" => 1_788_000_000_000
)
event.method        # => "CREATE"
event.processed_at  # => 2026-08-29 10:40:00 UTC
event.processed_at_ms # => 1788000000000
```

## Public Instance Methods
### `processed_at_ms()` <a id="method-i-processed_at_ms"></a> <a id="processed_at_ms-instance_method"></a>
Raw epoch milliseconds, used as the next `startTime` cursor. Pass it as
<code>since:</code> to `Client#changelog` to resume.
- **@return** [Integer, nil] `nil` when the event has no `processedAt`.
