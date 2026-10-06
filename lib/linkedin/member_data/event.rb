# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Data member name => JSON key. Time fields are handled separately.
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

    # One Member Changelog event. Times are UTC. `activity` and friends stay raw.
    Event = Data.define(
      *EVENT_KEYS.keys, :captured_at, :processed_at, :raw
    ) do
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
      def processed_at_ms = raw["processedAt"]
    end
  end
end
