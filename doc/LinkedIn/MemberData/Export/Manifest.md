# Class LinkedIn::MemberData::Export::Manifest <a id="class-LinkedIn-MemberData-Export-Manifest"></a>

|  |  |
| --- | --- |
| **Inherits** | Data |
| **Defined in** | lib/linkedin/member_data/export/manifest.rb |

Result of an export: one entry per domain and the manifest.json path.

## Attributes
### `entries` [R] <a id="attribute-i-entries"></a> <a id="entries-instance_method"></a>
- **@return** [Array<Entry>] one final entry per domain, in request order.

### `exported_at` [R] <a id="attribute-i-exported_at"></a> <a id="exported_at-instance_method"></a>
- **@return** [Time] UTC time the manifest was built.

### `gem_version` [R] <a id="attribute-i-gem_version"></a> <a id="gem_version-instance_method"></a>
- **@return** [String]

### `path` [R] <a id="attribute-i-path"></a> <a id="path-instance_method"></a>
- **@return** [String] path of manifest.json.

## Public Class Methods
### `build(dir, entries)` <a id="method-c-build"></a> <a id="build-class_method"></a>
- **@param** `dir` [String] export directory.
- **@param** `entries` [Array<Entry>]
- **@return** [Manifest]

## Public Instance Methods
### `as_json()` <a id="method-i-as_json"></a> <a id="as_json-instance_method"></a>
- **@return** [Hash{String => Object}] the manifest.json content (not `to_h`, which is the Data member hash).

### `failed()` <a id="method-i-failed"></a> <a id="failed-instance_method"></a>
- **@return** [Array<Entry>] entries with status `:failed`.

### `success?()` <a id="method-i-success-3F"></a> <a id="success?-instance_method"></a>
- **@return** [Boolean] true when no domain failed.

### `write()` <a id="method-i-write"></a> <a id="write-instance_method"></a>
Writes manifest.json as pretty JSON with a trailing newline.
- **@return** [Integer] bytes written.
