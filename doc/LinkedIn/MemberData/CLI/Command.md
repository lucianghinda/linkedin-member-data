# Class LinkedIn::MemberData::CLI::Command <a id="class-LinkedIn-MemberData-CLI-Command"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/cli/command.rb |

Base for commands. A command parses its own options, then runs. `run` returns
the exit code.

- **@api** private

## Constants
### `MAX_ARGUMENTS` <a id="constant-MAX_ARGUMENTS"></a> <a id="MAX_ARGUMENTS-constant"></a>
Positional arguments the command accepts.
- **@api** private
- **@return** [Integer]

### `OPTIONS` <a id="constant-OPTIONS"></a> <a id="OPTIONS-constant"></a>
Option specs for OptionParser#on. Subclasses override.
- **@api** private
- **@return** [Array<Array>]

## Public Instance Methods
### `initialize(context, argv)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@api** private
- **@param** `context` [Context]
- **@param** `argv` [Array<String>] arguments after the command name. Options are removed from it.
- **@return** [Command] a new instance of Command

### `run()` <a id="method-i-run"></a> <a id="run-instance_method"></a>
Parses options, checks arguments and executes.
- **@api** private
- **@raise** [UsageError] on bad arguments.
- **@return** [Integer] exit code.
