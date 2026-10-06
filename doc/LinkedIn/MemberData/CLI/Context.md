# Class LinkedIn::MemberData::CLI::Context <a id="class-LinkedIn-MemberData-CLI-Context"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/cli/support.rb |

What every command needs: the output and a lazy client. The token is only
looked up when a command asks for the client.

- **@api** private

## Constants
### `TOKEN_ENV` <a id="constant-TOKEN_ENV"></a> <a id="TOKEN_ENV-constant"></a>
Name of the environment variable that holds the token.
- **@api** private
- **@return** [String]

## Attributes
### `output` [R] <a id="attribute-i-output"></a> <a id="output-instance_method"></a>
- **@api** private
- **@return** [Output]

## Public Instance Methods
### `client()` <a id="method-i-client"></a> <a id="client-instance_method"></a>
The client, built on first use.
- **@api** private
- **@raise** [ConfigurationError] when no token is set.
- **@return** [Client]

### `initialize(output:, env:, client_factory:, token:)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@api** private
- **@param** `output` [Output]
- **@param** `env` [Hash, #[]] environment.
- **@param** `client_factory` [#call] takes a token and returns a `Client`.
- **@param** `token` [String, nil] token from `--token`.
- **@return** [Context] a new instance of Context

### `use_token(value)` <a id="method-i-use_token"></a> <a id="use_token-instance_method"></a>
Replaces the token from <code>--token</code>.
- **@api** private
- **@param** `value` [String]
- **@return** [String]
