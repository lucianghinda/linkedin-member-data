# Class LinkedIn::MemberData::Snapshot <a id="class-LinkedIn-MemberData-Snapshot"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Includes** | Enumerable |
| **Defined in** | lib/linkedin/member_data/snapshot.rb, lib/linkedin/member_data/snapshot/page.rb |

Lazy view over `GET /rest/memberSnapshotData` for one domain (or all). Nothing
is fetched until you iterate. Each iteration starts a new walk from the first
page.

Pages are indexed by `start` (0, 1, 2, ...). The API says to keep going until
it answers "No data found for this memberId", so that error ends iteration
instead of raising. A page with no rows also ends iteration.

It includes `Enumerable`, so `first`, `to_a`, `lazy`, `select` and the rest
work on rows. `first` fetches one page only.

**@example Walk all rows of one domain**
```ruby
snapshot = client.snapshot(:connections)
snapshot.each { |row| puts row["First Name"] }
snapshot.first                                       # fetches one page
snapshot.lazy.select { |row| row["Company"] }.first(5)
```

## Constants
### `NO_DATA_MESSAGE` <a id="constant-NO_DATA_MESSAGE"></a> <a id="NO_DATA_MESSAGE-constant"></a>
Text of the API error that means "no more data". It ends iteration.
- **@return** [String]

### `PATH` <a id="constant-PATH"></a> <a id="PATH-constant"></a>
API path of the snapshot resource.
- **@return** [String]

## Attributes
### `domain` [R] <a id="attribute-i-domain"></a> <a id="domain-instance_method"></a>
The domain name sent to the API. `nil` means all domains.
- **@return** [String, nil]

## Public Instance Methods
### `each(&block)` <a id="method-i-each"></a> <a id="each-instance_method"></a>
Yields every row of every page. Pages are fetched one by one while you
iterate. Rows are plain Hashes with the keys LinkedIn returns. Keys differ per
domain.
- **@raise** [ApiError] on a non-2xx response, except the "No data found" answer.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [Snapshot] self, when a block is given.
- **@return** [Enumerator<Hash>] when no block is given.
- **@yieldparam** `row` [Hash{String => Object}] one row of snapshot data.

**@example Block form**
```ruby
client.snapshot(:connections).each { |row| puts row["First Name"] }
```

**@example Without a block, you get an Enumerator**
```ruby
client.snapshot(:connections).each.first(3)
```

### `initialize(connection, domain)` <a id="method-i-initialize"></a> <a id="initialize-instance_method"></a>
- **@api** private
- **@param** `connection` [Connection] used for every request.
- **@param** `domain` [String, nil] domain name as sent to the API. `nil` means all domains.
- **@return** [Snapshot] a new instance of Snapshot

### `page(start)` <a id="method-i-page"></a> <a id="page-instance_method"></a>
Fetches one page by index. Does not walk. Does not hide the "No data found"
error.
- **@param** `start` [Integer] zero-based page index.
- **@raise** [NotFound] past the end of the data.
- **@raise** [ApiError] on any other non-2xx response.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [Snapshot::Page]

**@example**
```ruby
client.snapshot(:profile).page(0).rows
```

### `pages()` <a id="method-i-pages"></a> <a id="pages-instance_method"></a>
Lazy Enumerator of pages. The walk stops at the first page without a `next`
link. It also stops at an empty page or at the "No data found" answer. Any
other API error raises.
- **@raise** [ApiError] while iterating, on a non-2xx response except "No data found".
- **@raise** [ConnectionError] while iterating, on a network failure after all retries.
- **@return** [Enumerator<Snapshot::Page>]

**@example Inspect paging data**
```ruby
client.snapshot(:profile).pages.each do |page|
  puts "#{page.domain}: #{page.rows.size} rows, total #{page.total}"
end
```
