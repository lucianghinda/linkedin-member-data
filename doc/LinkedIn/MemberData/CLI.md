# Class LinkedIn::MemberData::CLI <a id="class-LinkedIn-MemberData-CLI"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/cli.rb, lib/linkedin/member_data/cli/command.rb, lib/linkedin/member_data/cli/support.rb, lib/linkedin/member_data/cli/since_parser.rb, lib/linkedin/member_data/cli/global_options.rb, lib/linkedin/member_data/cli/simple_commands.rb, lib/linkedin/member_data/cli/snapshot_command.rb, lib/linkedin/member_data/cli/changelog_command.rb |

Command line entry point. Data goes to stdout or files, progress and errors go
to stderr. Exit codes: 0 ok, 1 API error, 2 usage error.

- **@api** private

## Constants
### `COMMANDS` <a id="constant-COMMANDS"></a> <a id="COMMANDS-constant"></a>
Command name => command class.
- **@api** private
- **@return** [Hash{String => Class}]

### `DEFAULT_CLIENT_FACTORY` <a id="constant-DEFAULT_CLIENT_FACTORY"></a> <a id="DEFAULT_CLIENT_FACTORY-constant"></a>
Builds a `Client` from a token.
- **@api** private
- **@return** [Proc]

### `USAGE` <a id="constant-USAGE"></a> <a id="USAGE-constant"></a>
Help text.
- **@api** private
- **@return** [String]

## Public Instance Methods
### `initialize(argv, stdout: = $stdout, stderr: = $stderr, env: = ENV, client_factory: = DEFAULT_CLIENT_FACTORY)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@api** private
- **@param** `argv` [Array<String>] command line arguments. Not changed.
- **@param** `stdout` [IO] where data goes.
- **@param** `stderr` [IO] where progress and errors go.
- **@param** `env` [Hash, #[]] environment, read for `LINKEDIN_ACCESS_TOKEN`.
- **@param** `client_factory` [#call] takes a token and returns a `Client`.
- **@return** [CLI] a new instance of CLI

### `run()` <a id="method-i-run"></a> <a id="run-instance_method"></a>
Runs the command.
- **@api** private
- **@return** [Integer] exit code: 0 ok, 1 API, network or file error, 2 usage error.
