# frozen_string_literal: true

require_relative "changelog/page"

module LinkedIn
  module MemberData
    # Lazy view over `GET /rest/memberChangeLogs` (last 28 days).
    # Nothing is fetched until you iterate. Each iteration starts a new walk.
    #
    # The cursor is `startTime` = last `processedAt` seen. LinkedIn returns the
    # cursor event again on the next page, so events already seen are skipped
    # and iteration stops when a page brings nothing new, or when the last event
    # has no processedAt (the cursor cannot move).
    #
    # Known limit: if more than `count` events share one processedAt, the ones
    # beyond the first page are not reachable through the cursor.
    # A higher `count` (max 50) makes this less likely.
    #
    # It includes `Enumerable`, so `first`, `to_a`, `lazy`, `select` and the rest work on events.
    #
    # @example Print recent events
    #   client.changelog(since: Time.now - 7 * 86_400).each do |event|
    #     puts "#{event.method} #{event.resource_name} at #{event.processed_at}"
    #   end
    class Changelog
      include Enumerable

      # API path of the changelog resource.
      # @return [String]
      PATH = "/rest/memberChangeLogs"

      # Allowed values for `count`.
      # @return [Range<Integer>]
      COUNT_RANGE = (2..50)

      # Default for `count`.
      # @return [Integer]
      DEFAULT_COUNT = 10

      # Cursor state of one walk. A new one is built for every iteration.
      # @api private
      Walk = Struct.new(:start_time, :seen_ids) do
        # `page` is an undeduped Page. Returns a Page with only the fresh events
        # and moves the cursor; nil when nothing is new.
        def take(page)
          fresh = fresh_events(page)
          return if fresh.empty?

          advance(page)
          Page.new(events: fresh, raw: page.raw)
        end

        # Events of `page` whose id was not on the previous page.
        # @api private
        def fresh_events(page) = page.events.reject { |event| seen_ids.include?(event.id) }

        # Yields each start_time to the block to fetch a Page. Stops at the first
        # page with nothing new or when the cursor cannot move.
        def run(yielder)
          while (fresh_page = take(yield(start_time)))
            yielder << fresh_page
            break if start_time.nil?
          end
        end

        # Only the previous page is remembered: that is the documented overlap.
        def advance(page)
          self.seen_ids = page.events.map(&:id)
          self.start_time = page.next_start_time
        end
      end
      private_constant :Walk

      # Settings of this view. `since` is the first `processedAt` to fetch, in epoch milliseconds
      # (`nil` starts at the oldest event). `count` is the number of events per request, from 2 to 50.
      # @return [Integer, nil] `since` or `count`. `count` is never nil.
      attr_reader :since, :count

      # @api private
      # @param connection [Connection] used for every request.
      # @param since [Time, Date, Integer, nil] first `processedAt` to fetch.
      #   Integer is epoch milliseconds. A Date is midnight UTC.
      # @param count [Integer] events per request, from 2 to 50. One slot is needed for the cursor overlap.
      # @raise [ArgumentError] when `count` is outside 2..50 or `since` has an unsupported type.
      #   Raised before any request.
      def initialize(connection, since: nil, count: DEFAULT_COUNT)
        @count = count
        ensure_count
        @connection = connection
        @since = Util.epoch_ms(since)
      end

      # Yields every new event of every page, oldest first. Pages are fetched one by one while you iterate.
      #
      # @example
      #   client.changelog(count: 50).each { |event| puts event.id }
      # @example Without a block, you get an Enumerator
      #   client.changelog.each.first(5)
      # @yieldparam event [Event] one changelog event. Events already seen in the overlap are skipped.
      # @return [Changelog] self, when a block is given.
      # @return [Enumerator<Event>] when no block is given.
      # @raise [ApiError] on a non-2xx response.
      # @raise [ConnectionError] on a network failure after all retries.
      def each(&block)
        return enum_for(:each) unless block

        pages.each { |page| page.events.each(&block) }
        self
      end

      # Lazy Enumerator of pages with already-seen events removed.
      # Stops on the first page with no new events, or when the last event has no `processedAt`.
      # A yielded Page has filtered `events` but the unfiltered `raw` response.
      #
      # @example Cursor of each page
      #   client.changelog.pages.each { |page| puts "#{page.events.size} events, next #{page.next_start_time}" }
      # @return [Enumerator<Changelog::Page>]
      # @raise [ApiError] while iterating, on a non-2xx response.
      # @raise [ConnectionError] while iterating, on a network failure after all retries.
      def pages = Enumerator.new { |yielder| each_page(yielder) }

      # Fetches one raw page. No overlap handling, so the cursor event comes back again.
      #
      # @param start_time [Integer, nil] cursor in epoch milliseconds. `nil` starts at the oldest event.
      # @return [Changelog::Page]
      # @raise [ApiError] on a non-2xx response.
      # @raise [ConnectionError] on a network failure after all retries.
      def page(start_time)
        params = { q: "memberAndApplication", count: count, startTime: start_time }
        Page.from_api(@connection.get(PATH, params))
      end

      private

      def each_page(yielder)
        Walk.new(since, []).run(yielder) { |start_time| page(start_time) }
      end

      def ensure_count
        return if count.is_a?(Integer) && COUNT_RANGE.cover?(count)

        raise ArgumentError, "count must be between #{COUNT_RANGE.min} and #{COUNT_RANGE.max}, got #{count.inspect}"
      end
    end
  end
end
