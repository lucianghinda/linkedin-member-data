# Class LinkedIn::MemberData::Connection <a id="class-LinkedIn-MemberData-Connection"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/connection.rb |

One HTTP door to api.linkedin.com. Adds headers, parses JSON, maps statuses to
errors and retries 429/5xx/network failures.

- **@api** private

## Constants
### `API_VERSION` <a id="constant-API_VERSION"></a> <a id="API_VERSION-constant"></a>
Value of the <code>Linkedin-Version</code> header.
- **@api** private
- **@return** [String]

### `BASE_URL` <a id="constant-BASE_URL"></a> <a id="BASE_URL-constant"></a>
- **@api** private
- **@return** [String]

### `HEADERS` <a id="constant-HEADERS"></a> <a id="HEADERS-constant"></a>
- **@api** private

### `MAX_RETRY_AFTER` <a id="constant-MAX_RETRY_AFTER"></a> <a id="MAX_RETRY_AFTER-constant"></a>
Upper limit for a server-sent Retry-After, in seconds.
- **@api** private
- **@return** [Integer]

### `RETRYABLE_EXCEPTIONS` <a id="constant-RETRYABLE_EXCEPTIONS"></a> <a id="RETRYABLE_EXCEPTIONS-constant"></a>
Network errors that become a `ConnectionError`.
- **@api** private
- **@return** [Array<Class>]

## Public Instance Methods
### `get(path, params = {})` <a id="method-i-get"></a> <a id="get-instance_method"></a>
Sends a GET request.
- **@api** private
- **@param** `path` [String] must start with a single `/`.
- **@param** `params` [Hash] query parameters. Nil values are dropped.
- **@raise** [ArgumentError] when `path` does not start with a single `/`.
- **@raise** [ApiError] on a non-2xx response, or when a 2xx body is not JSON.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [Hash] parsed JSON body. `{}` for an empty body.

### `initialize(access_token:, retries: = 3, timeout: = 30, logger: = nil, sleeper: = Kernel.method(:sleep), transport: = NetHttpTransport.new(timeout: timeout))` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@api** private
- **@param** `access_token` [String] OAuth token. Sent as a Bearer header.
- **@param** `retries` [Integer] retries on 429, 5xx and network errors. `0` turns retries off.
- **@param** `timeout` [Integer, Float] timeout in seconds for the default transport.
- **@param** `logger` [Logger, nil] gets one debug line per request.
- **@param** `sleeper` [#call] called with the seconds to wait between retries.
- **@param** `transport` [#call] takes `(request, uri)` and returns a response. Replaced in tests.
- **@return** [Connection] a new instance of Connection

### `inspect()` <a id="method-i-inspect"></a> <a id="inspect-instance_method"></a>
Hides the token.
- **@api** private
- **@return** [String]

### `post(path, body = {})` <a id="method-i-post"></a> <a id="post-instance_method"></a>
Sends a POST request with a JSON body.
- **@api** private
- **@param** `path` [String] must start with a single `/`.
- **@param** `body` [Hash] sent as JSON.
- **@raise** [ArgumentError] when `path` does not start with a single `/`.
- **@raise** [ApiError] on a non-2xx response, or when a 2xx body is not JSON.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [Hash] parsed JSON body. `{}` for an empty body.
