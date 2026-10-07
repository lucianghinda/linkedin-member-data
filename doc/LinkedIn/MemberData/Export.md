# Class LinkedIn::MemberData::Export <a id="class-LinkedIn-MemberData-Export"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Defined in** | lib/linkedin/member_data/export.rb, lib/linkedin/member_data/export/entry.rb, lib/linkedin/member_data/export/manifest.rb |

Downloads every snapshot domain into a directory: one `<DOMAIN>.json` per
domain plus <code>manifest.json</code>. Built by {Client#export}.

Domains are fetched in order. A domain that fails with an API or network error
is recorded as <code>:failed</code> and the run goes on. `Unauthorized` and
`Forbidden` stop the run at once (a bad token fails every domain the same
way); the manifest is still written before the error propagates.

## Constants
### `DOMAIN_NAME` <a id="constant-DOMAIN_NAME"></a> <a id="DOMAIN_NAME-constant"></a>
Allowed domain names. Keeps odd names such as <code>../x</code> away from file
paths.
- **@return** [Regexp]

### `MANIFEST_FILE` <a id="constant-MANIFEST_FILE"></a> <a id="MANIFEST_FILE-constant"></a>
File name of the manifest written next to the domain files.
- **@return** [String]

## Attributes
### `dir` [R] <a id="attribute-i-dir"></a> <a id="dir-instance_method"></a>
- **@return** [String] export directory.

### `domains` [R] <a id="attribute-i-domains"></a> <a id="domains-instance_method"></a>
- **@return** [Array<String>] normalized domain names, in request order.

## Public Instance Methods
### `initialize(client, dir, domains: = Domains::ALL)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@param** `client` [Client]
- **@param** `dir` [String] directory to write into. Created when missing.
- **@param** `domains` [Array<Symbol, String>] domains to export. Symbols are upcased. Duplicates are dropped.
- **@raise** [ArgumentError] when a domain is nil, blank, or not made of A-Z, 0-9 and _.
- **@return** [Export] a new instance of Export

### `run(&progress)` <a id="method-i-run"></a> <a id="run-instance_method"></a>
Runs the export. Not thread-safe: build one Export per run. Yields twice per
domain when a block is given: an entry with status <code>:fetching</code>,
then the final entry.
- **@raise** [Unauthorized, Forbidden] when the token is rejected; the manifest is written first.
- **@raise** [SystemCallError] when a file cannot be written.
- **@return** [Manifest]
- **@yieldparam** `entry` [Entry]
