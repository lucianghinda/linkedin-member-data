# Class LinkedIn::MemberData::CLI::Output <a id="class-LinkedIn-MemberData-CLI-Output"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/cli/support.rb |

Data goes to a file or stdout. Progress and errors go to stderr.

- **@api** private

## Public Instance Methods
### `error(text)` <a id="method-i-error"></a> <a id="error-instance_method"></a>
Prints a line to stderr.
- **@api** private
- **@param** `text` [String]
- **@return** [void]

### `initialize(stdout, stderr)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@api** private
- **@param** `stdout` [IO]
- **@param** `stderr` [IO]
- **@return** [Output] a new instance of Output

### `line(text)` <a id="method-i-line"></a> <a id="line-instance_method"></a>
Prints a line to stdout.
- **@api** private
- **@param** `text` [String, Array<String>]
- **@return** [void]

### `write(data, path = nil)` <a id="method-i-write"></a> <a id="write-instance_method"></a>
Files get the same bytes as stdout, including the final newline.
- **@api** private
- **@param** `data` [Object] anything JSON can encode.
- **@param** `path` [String, nil] file to write. `nil` means stdout.
- **@return** [void]
