# Class LinkedIn::MemberData::Client <a id="class-LinkedIn-MemberData-Client"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/client.rb |

Entry point of the gem. Holds one `Connection`.

**@example Create a client and read a snapshot**
```ruby
client = LinkedIn::MemberData::Client.new(access_token: ENV["LINKEDIN_ACCESS_TOKEN"])
client.snapshot(:connections).each { |row| puts row["First Name"] }
```

## Constants
### `AUTHORIZATIONS_PATH` <a id="constant-AUTHORIZATIONS_PATH"></a> <a id="AUTHORIZATIONS_PATH-constant"></a>
API path of the member authorizations resource.
- **@return** [String]

## Attributes
### `connection` [R] <a id="attribute-i-connection"></a> <a id="connection-instance_method"></a>
The HTTP connection used for every request.
- **@api** private
- **@return** [Connection]

## Public Instance Methods
### `authorization()` <a id="method-i-authorization"></a> <a id="authorization-instance_method"></a>
Fetches the authorization record of the token. Sends one request.
- **@raise** [ApiError] on a non-2xx response, for example `Unauthorized` for a bad token.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [Authorization, nil] `nil` when LinkedIn returns no authorization.

**@example**
```ruby
authorization = client.authorization
puts authorization.regulated_at if authorization
```

### `changelog(since: = nil, count: = Changelog::DEFAULT_COUNT)` <a id="method-i-changelog"></a> <a id="changelog-instance_method"></a>
Returns a lazy view over the changelog of the last 28 days. No request is sent
until you iterate.
- **@param** `since` [Time, Date, Integer, nil] first `processedAt` to fetch.
Integer is epoch milliseconds. A Date is midnight UTC. `nil` starts at the oldest event.
- **@param** `count` [Integer] events per request, from 1 to 50.
- **@raise** [ArgumentError] when `count` is outside 1..50 or `since` has an unsupported type.
Raised before any request.
- **@return** [Changelog]

**@example Events of the last 7 days**
```ruby
client.changelog(since: Time.now - 7 * 86_400).each do |event|
  puts "#{event.method} #{event.resource_name} at #{event.processed_at}"
end
```

**@example Resume from the last event you saw**
```ruby
last_seen = client.changelog.to_a.last&.processed_at_ms
client.changelog(since: last_seen).each { |event| puts event.id }
```

### `enable_changelog!()` <a id="method-i-enable_changelog-21"></a> <a id="enable_changelog!-instance_method"></a>
Starts changelog archiving for the member. LinkedIn usually does this by
itself.
- **@raise** [ApiError] on a non-2xx response.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [true] always true. API failures raise.

**@example**
```ruby
client.enable_changelog!  # => true
```

### `initialize(access_token:, retries: = 3, timeout: = 30, logger: = nil, connection: = nil)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
Builds a client. No request is sent.
- **@param** `access_token` [String] OAuth token with scope `r_dma_portability_self_serve`.
Leading and trailing spaces are removed.
- **@param** `retries` [Integer] retries on 429, 5xx and network errors, with backoff. `0` turns retries off.
- **@param** `timeout` [Integer, Float] open, read and write timeout in seconds.
- **@param** `logger` [Logger, nil] gets one debug line per request: `GET url -> status`.
- **@param** `connection` [Connection, nil] ready-made connection. When given, `retries`, `timeout`
and `logger` are not used. Meant for tests.
- **@raise** [ConfigurationError] when `access_token` is nil or blank.
- **@return** [Client] a new instance of Client

### `snapshot(domain = nil)` <a id="method-i-snapshot"></a> <a id="snapshot-instance_method"></a>
Returns a lazy view over snapshot data. No request is sent until you iterate.
- **@param** `domain` [Symbol, String, nil] a name from `Domains::ALL`. A Symbol is upcased.
A String is sent as given, because the API is case sensitive. `nil` means all domains.
- **@raise** [ArgumentError] when `domain` is not a Symbol, a String or nil.
- **@return** [Snapshot]

**@example One domain, symbol or string**
```ruby
client.snapshot(:profile).first     # symbol is upcased: "PROFILE"
client.snapshot("ALL_COMMENTS").to_a
```

**@example All domains**
```ruby
client.snapshot.each { |row| puts row.keys.inspect }
```
