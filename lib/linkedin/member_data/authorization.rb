# frozen_string_literal: true

module LinkedIn
  module MemberData
    # The member's authorization record from memberAuthorizations.
    Authorization = Data.define(:member, :developer_application, :regulated_at, :scopes, :raw) do
      def self.from_api(hash)
        key = hash.fetch("memberComplianceAuthorizationKey", {})
        new(member: key["member"], developer_application: key["developerApplication"],
            regulated_at: Util.time_from_ms(hash["regulatedAt"]),
            scopes: hash.fetch("memberComplianceScopes", []), raw: hash)
      end
    end
  end
end
