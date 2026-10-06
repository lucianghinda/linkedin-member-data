# Class LinkedIn::MemberData::Snapshot::Page <a id="class-LinkedIn-MemberData-Snapshot-Page"></a>

|  |  |
| --- | --- |
| **Inherits** | Data |
| **Defined in** | lib/linkedin/member_data/snapshot/page.rb |

One response page of snapshot data. Immutable.

## Attributes
### `count` [R] <a id="attribute-i-count"></a> <a id="count-instance_method"></a>
- **@return** [Integer, nil] page size from the `paging` object.

### `domain` [R] <a id="attribute-i-domain"></a> <a id="domain-instance_method"></a>
- **@return** [String, nil] `snapshotDomain` of the first element. An all-domains call may return several.

### `has_next` [R] <a id="attribute-i-has_next"></a> <a id="has_next-instance_method"></a>
- **@return** [Boolean] true when `paging.links` has a link with rel `next`.

### `raw` [R] <a id="attribute-i-raw"></a> <a id="raw-instance_method"></a>
- **@return** [Hash] the parsed response body.

### `rows` [R] <a id="attribute-i-rows"></a> <a id="rows-instance_method"></a>
- **@return** [Array<Hash{String => Object}>] rows of every element on this page. Keys differ per domain.

### `start` [R] <a id="attribute-i-start"></a> <a id="start-instance_method"></a>
- **@return** [Integer, nil] page index from the `paging` object.

### `total` [R] <a id="attribute-i-total"></a> <a id="total-instance_method"></a>
- **@return** [Integer, nil] total number of items from the `paging` object.

## Public Class Methods
### `from_api(raw)` <a id="method-c-from_api"></a> <a id="from_api-class_method"></a>
Builds a page from a parsed response body. Missing keys give empty or nil
values.
- **@param** `raw` [Hash] parsed JSON body of the API response.
- **@return** [Snapshot::Page]

## Public Instance Methods
### `next?()` <a id="method-i-next-3F"></a> <a id="next?-instance_method"></a>
Tells if another page may follow. Same value as <code>#has_next</code>. The
last page can still carry a `next` link, so an empty next page is possible.
- **@return** [Boolean]
