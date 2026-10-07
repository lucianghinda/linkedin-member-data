# Module LinkedIn::MemberData <a id="module-LinkedIn-MemberData"></a>

|  |  |
| --- | --- |
| **Defined in** | lib/linkedin/member_data/version.rb, lib/linkedin/member_data/cli.rb, lib/linkedin/member_data/util.rb, lib/linkedin/member_data/event.rb, lib/linkedin/member_data/client.rb, lib/linkedin/member_data/errors.rb, lib/linkedin/member_data/export.rb, lib/linkedin/member_data/domains.rb, lib/linkedin/member_data/snapshot.rb, lib/linkedin/member_data/changelog.rb, lib/linkedin/member_data/connection.rb, lib/linkedin/member_data/cli/command.rb, lib/linkedin/member_data/cli/support.rb, lib/linkedin/member_data/export/entry.rb, lib/linkedin/member_data/authorization.rb, lib/linkedin/member_data/snapshot/page.rb, lib/linkedin/member_data/changelog/page.rb, lib/linkedin/member_data/export/manifest.rb, lib/linkedin/member_data/cli/since_parser.rb, lib/linkedin/member_data/cli/global_options.rb, lib/linkedin/member_data/cli/simple_commands.rb, lib/linkedin/member_data/cli/snapshot_command.rb, lib/linkedin/member_data/cli/changelog_command.rb |

Ruby client and CLI for the LinkedIn Member Data Portability (Member) API.
Start with `Client`.

**@example**
```ruby
client = LinkedIn::MemberData::Client.new(access_token: ENV["LINKEDIN_ACCESS_TOKEN"])
client.snapshot(:connections).each { |row| puts row["First Name"] }
```

## Constants
### `EVENT_KEYS` <a id="constant-EVENT_KEYS"></a> <a id="EVENT_KEYS-constant"></a>
Data member name => JSON key. Time fields are handled separately.
- **@api** private

### `VERSION` <a id="constant-VERSION"></a> <a id="VERSION-constant"></a>
Gem version.
- **@return** [String]

# Documentation

- [MemberData/ApiError.md](MemberData/ApiError.md)
- [MemberData/Authorization.md](MemberData/Authorization.md)
- [MemberData/Changelog/Page.md](MemberData/Changelog/Page.md)
- [MemberData/Changelog.md](MemberData/Changelog.md)
- [MemberData/Client.md](MemberData/Client.md)
- [MemberData/ConfigurationError.md](MemberData/ConfigurationError.md)
- [MemberData/ConnectionError.md](MemberData/ConnectionError.md)
- [MemberData/Domains.md](MemberData/Domains.md)
- [MemberData/Error.md](MemberData/Error.md)
- [MemberData/Event.md](MemberData/Event.md)
- [MemberData/Export/Entry.md](MemberData/Export/Entry.md)
- [MemberData/Export/Manifest.md](MemberData/Export/Manifest.md)
- [MemberData/Export.md](MemberData/Export.md)
- [MemberData/Forbidden.md](MemberData/Forbidden.md)
- [MemberData/NotFound.md](MemberData/NotFound.md)
- [MemberData/RateLimited.md](MemberData/RateLimited.md)
- [MemberData/ServerError.md](MemberData/ServerError.md)
- [MemberData/Snapshot/Page.md](MemberData/Snapshot/Page.md)
- [MemberData/Snapshot.md](MemberData/Snapshot.md)
- [MemberData/Unauthorized.md](MemberData/Unauthorized.md)
- [MemberData/VersionError.md](MemberData/VersionError.md)
