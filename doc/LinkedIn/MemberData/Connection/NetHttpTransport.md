# Class LinkedIn::MemberData::Connection::NetHttpTransport <a id="class-LinkedIn-MemberData-Connection-NetHttpTransport"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/connection.rb |

Default transport: a real Net::HTTP call. Replaced in tests.

- **@api** private

## Public Instance Methods
### `call(request, uri)` <a id="method-i-call"></a> <a id="call-instance_method"></a>
- **@api** private
- **@param** `request` [Net::HTTPRequest]
- **@param** `uri` [URI::HTTPS]
- **@return** [Net::HTTPResponse]

### `initialize(timeout:)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@api** private
- **@param** `timeout` [Integer, Float] open, read and write timeout in seconds.
- **@return** [NetHttpTransport] a new instance of NetHttpTransport
