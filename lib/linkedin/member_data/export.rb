# frozen_string_literal: true

module LinkedIn
  module MemberData
    # Downloads every snapshot domain into a directory: one `<DOMAIN>.json`
    # per domain plus `manifest.json`. Built by {Client#export}.
    class Export
      # File name of the manifest written next to the domain files.
      # @return [String]
      MANIFEST_FILE = "manifest.json"
    end
  end
end

require_relative "export/entry"
require_relative "export/manifest"
