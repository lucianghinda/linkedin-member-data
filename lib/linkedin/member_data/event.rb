# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Data member name => JSON key. Time fields are handled separately.
    # @api private
    EVENT_KEYS = {
      id: "id",
      activity_id: "activityId",
      activity_status: "activityStatus",
      config_version: "configVersion",
      owner: "owner",
      actor: "actor",
      resource_name: "resourceName",
      resource_id: "resourceId",
      resource_uri: "resourceUri",
      # Shadows Object#method on purpose; it is the API field name.
      method: "method",
      method_name: "methodName",
      activity: "activity",
      processed_activity: "processedActivity",
      sibling_activities: "siblingActivities",
      parent_sibling_activities: "parentSiblingActivities"
    }.freeze
    private_constant :EVENT_KEYS

    # One Member Changelog event. Immutable. Times are UTC. `activity` and friends stay raw.
    # Fields missing in the API response are `nil`.
    #
    # `method` is the API field (`CREATE`, `UPDATE`, ...). It shadows Ruby's `Object#method` on purpose,
    # so `event.method(:name)` does not work on an Event.
    #
    # @!attribute [r] id
    #   @return [String, nil] event id. Used to skip events seen on the previous page.
    # @!attribute [r] activity_id
    #   @return [String, nil] value as sent by the API.
    # @!attribute [r] activity_status
    #   @return [String, nil] value as sent by the API.
    # @!attribute [r] config_version
    #   @return [Object, nil] value as sent by the API.
    # @!attribute [r] owner
    #   @return [String, nil] owner of the event, as sent by the API.
    # @!attribute [r] actor
    #   @return [String, nil] who did the action, as sent by the API.
    # @!attribute [r] resource_name
    #   @return [String, nil] kind of resource that changed.
    # @!attribute [r] resource_id
    #   @return [String, nil] value as sent by the API.
    # @!attribute [r] resource_uri
    #   @return [String, nil] value as sent by the API.
    # @!attribute [r] method
    #   @return [String, nil] API method, for example `CREATE` or `UPDATE`.
    # @!attribute [r] method_name
    #   @return [String, nil] value as sent by the API.
    # @!attribute [r] captured_at
    #   @return [Time, nil] when LinkedIn captured the event. UTC.
    # @!attribute [r] processed_at
    #   @return [Time, nil] when LinkedIn processed the event. UTC. Used as the cursor.
    # @!attribute [r] activity
    #   @return [Hash, nil] raw activity payload.
    # @!attribute [r] processed_activity
    #   @return [Hash, nil] raw processed activity payload.
    # @!attribute [r] sibling_activities
    #   @return [Array<Hash>, nil] raw sibling activities.
    # @!attribute [r] parent_sibling_activities
    #   @return [Array<Hash>, nil] raw parent sibling activities.
    # @!attribute [r] raw
    #   @return [Hash] the original event Hash from the API.
    Event = Data.define(
      *EVENT_KEYS.keys, :captured_at, :processed_at, :raw
    ) do
      # Builds an event from one element of the API response.
      #
      # @example
      #   event = LinkedIn::MemberData::Event.from_api(
      #     "id" => "1", "method" => "CREATE", "processedAt" => 1_788_000_000_000
      #   )
      #   event.method        # => "CREATE"
      #   event.processed_at  # => 2026-08-29 10:40:00 UTC
      #   event.processed_at_ms # => 1788000000000
      # @param hash [Hash] one element of `elements` from the changelog response.
      # @return [Event]
      def self.from_api(hash)
        attributes = EVENT_KEYS.transform_values { |key| hash[key] }
        new(**attributes, **times_from(hash), raw: hash)
      end

      def self.times_from(hash)
        { captured_at: Util.time_from_ms(hash["capturedAt"]),
          processed_at: Util.time_from_ms(hash["processedAt"]) }
      end
      private_class_method :times_from

      # Raw epoch milliseconds, used as the next `startTime` cursor.
      # Pass it as `since:` to `Client#changelog` to resume.
      #
      # @return [Integer, nil] `nil` when the event has no `processedAt`.
      def processed_at_ms = raw["processedAt"]
    end
  end
end
