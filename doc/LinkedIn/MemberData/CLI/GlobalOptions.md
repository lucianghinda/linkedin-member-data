# Class LinkedIn::MemberData::CLI::GlobalOptions <a id="class-LinkedIn-MemberData-CLI-GlobalOptions"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/cli/global_options.rb |

Options that come before the command name: --token and --help.

- **@api** private

## Public Class Methods
### `parse(argv)` <a id="method-c-parse"></a> <a id="parse-class_method"></a>
- **@api** private
- **@param** `argv` [Array<String>] arguments. Global options are removed from it.
- **@raise** [OptionParser::ParseError] on an unknown option.
- **@return** [Hash{Symbol => Object}] options found, for example `{ token: "...", help: true }`.
