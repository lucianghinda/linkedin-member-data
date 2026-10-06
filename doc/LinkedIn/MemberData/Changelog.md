# Class LinkedIn::MemberData::Changelog <a id="class-LinkedIn-MemberData-Changelog"></a>

|  |  |
| --- | --- |
| **Inherits** | Object |
| **Includes** | Enumerable |
| **Defined in** | lib/linkedin/member_data/changelog.rb, lib/linkedin/member_data/changelog/page.rb |

Lazy view over `GET /rest/memberChangeLogs` (last 28 days). Nothing is fetched
until you iterate. Each iteration starts a new walk.

The cursor is `startTime` = last `processedAt` seen. LinkedIn returns the
cursor event again on the next page, so events already seen are skipped and
iteration stops when a page brings nothing new, or when the last event has no
processedAt (the cursor cannot move).

Known limit: if more than `count` events share one processedAt, the ones
beyond the first page are not reachable through the cursor. A higher `count`
(max 50) makes this less likely.

It includes `Enumerable`, so `first`, `to_a`, `lazy`, `select` and the rest
work on events.

**@example Print recent events**
```ruby
client.changelog(since: Time.now - 7 * 86_400).each do |event|
  puts "#{event.method} #{event.resource_name} at #{event.processed_at}"
end
```

## Constants
### `COUNT_RANGE` <a id="constant-COUNT_RANGE"></a> <a id="COUNT_RANGE-constant"></a>
Allowed values for `count`.
- **@return** [Range<Integer>]

### `DEFAULT_COUNT` <a id="constant-DEFAULT_COUNT"></a> <a id="DEFAULT_COUNT-constant"></a>
Default for `count`.
- **@return** [Integer]

### `PATH` <a id="constant-PATH"></a> <a id="PATH-constant"></a>
API path of the changelog resource.
- **@return** [String]

## Attributes
### `count` [R] <a id="attribute-i-count"></a> <a id="count-instance_method"></a>
Settings of this view. `since` is the first `processedAt` to fetch, in epoch
milliseconds (`nil` starts at the oldest event). `count` is the number of
events per request, from 1 to 50.
- **@return** [Integer, nil] `since` or `count`. `count` is never nil.

### `since` [R] <a id="attribute-i-since"></a> <a id="since-instance_method"></a>
Settings of this view. `since` is the first `processedAt` to fetch, in epoch
milliseconds (`nil` starts at the oldest event). `count` is the number of
events per request, from 1 to 50.
- **@return** [Integer, nil] `since` or `count`. `count` is never nil.

## Public Instance Methods
### `each(&block)` <a id="method-i-each"></a> <a id="each-instance_method"></a>
Yields every new event of every page, oldest first. Pages are fetched one by
one while you iterate.
- **@raise** [ApiError] on a non-2xx response.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [Changelog] self, when a block is given.
- **@return** [Enumerator<Event>] when no block is given.
- **@yieldparam** `event` [Event] one changelog event. Events already seen in the overlap are skipped.

**@example**
```ruby
client.changelog(count: 50).each { |event| puts event.id }
```

**@example Without a block, you get an Enumerator**
```ruby
client.changelog.each.first(5)
```

### `page(start_time)` <a id="method-i-page"></a> <a id="page-instance_method"></a>
Fetches one raw page. No overlap handling, so the cursor event comes back
again.
- **@param** `start_time` [Integer, nil] cursor in epoch milliseconds. `nil` starts at the oldest event.
- **@raise** [ApiError] on a non-2xx response.
- **@raise** [ConnectionError] on a network failure after all retries.
- **@return** [Changelog::Page]

### `pages()` <a id="method-i-pages"></a> <a id="pages-instance_method"></a>
Lazy Enumerator of pages with already-seen events removed. Stops on the first
page with no new events, or when the last event has no `processedAt`. A
yielded Page has filtered `events` but the unfiltered `raw` response.
- **@raise** [ApiError] while iterating, on a non-2xx response.
- **@raise** [ConnectionError] while iterating, on a network failure after all retries.
- **@return** [Enumerator<Changelog::Page>]

**@example Cursor of each page**
```ruby
client.changelog.pages.each { |page| puts "#{page.events.size} events, next #{page.next_start_time}" }
```
