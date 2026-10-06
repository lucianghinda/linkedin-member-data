# frozen_string_literal: true

module LinkedIn
  module MemberData
    # The member's authorization record from `memberAuthorizations`. Immutable.
    #
    # @!attribute [r] member
    #   @return [String, nil] member, as sent by the API.
    # @!attribute [r] developer_application
    #   @return [String, nil] developer application, as sent by the API.
    # @!attribute [r] regulated_at
    #   @return [Time, nil] when the member gave consent. UTC.
    # @!attribute [r] scopes
    #   @return [Array<String>] granted scopes. Empty when the API sends none.
    # @!attribute [r] raw
    #   @return [Hash] the original element from the API.
    Authorization = Data.define(:member, :developer_application, :regulated_at, :scopes, :raw) do
      # Builds an authorization from one element of the API response.
      #
      # @param hash [Hash] one element of `elements` from the `memberAuthorizations` response.
      # @return [Authorization]
      def self.from_api(hash)
        key = hash.fetch("memberComplianceAuthorizationKey", {})
        new(member: key["member"], developer_application: key["developerApplication"],
            regulated_at: Util.time_from_ms(hash["regulatedAt"]),
            scopes: hash.fetch("memberComplianceScopes", []), raw: hash)
      end
    end
  end
end
