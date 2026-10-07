# Class LinkedIn::MemberData::Export::Entry <a id="class-LinkedIn-MemberData-Export-Entry"></a>

|  |  |
| --- | --- |
| **Inherits** | Data |
| **Defined in** | lib/linkedin/member_data/export/entry.rb |

What happened to one domain during an export.

## Attributes
### `domain` [R] <a id="attribute-i-domain"></a> <a id="domain-instance_method"></a>
- **@return** [String] domain name, for example `"CONNECTIONS"`.

### `error` [R] <a id="attribute-i-error"></a> <a id="error-instance_method"></a>
- **@return** [String, nil] error message when failed.

### `file` [R] <a id="attribute-i-file"></a> <a id="file-instance_method"></a>
- **@return** [String, nil] file name relative to the export directory; nil unless saved or empty.

### `rows` [R] <a id="attribute-i-rows"></a> <a id="rows-instance_method"></a>
- **@return** [Integer, nil] rows written; nil while fetching or when failed.

### `status` [R] <a id="attribute-i-status"></a> <a id="status-instance_method"></a>
- **@return** [Symbol] `:fetching`, `:saved`, `:empty` or `:failed`.

## Public Class Methods
### `failed(domain, error)` <a id="method-c-failed"></a> <a id="failed-class_method"></a>
- **@param** `domain` [String]
- **@param** `error` [Exception]
- **@return** [Entry] status `:failed` with the error message.

### `fetching(domain)` <a id="method-c-fetching"></a> <a id="fetching-class_method"></a>
- **@param** `domain` [String]
- **@return** [Entry] status `:fetching`.

### `saved(domain, rows)` <a id="method-c-saved"></a> <a id="saved-class_method"></a>
- **@param** `domain` [String]
- **@param** `rows` [Integer] rows written to the file.
- **@return** [Entry] status `:empty` when rows is zero, else `:saved`.

## Public Instance Methods
### `failed?()` <a id="method-i-failed-3F"></a> <a id="failed?-instance_method"></a>
- **@return** [Boolean]

### `to_manifest()` <a id="method-i-to_manifest"></a> <a id="to_manifest-instance_method"></a>
Hash for manifest.json: string keys and status, nil values dropped.
- **@return** [Hash{String => Object}]
