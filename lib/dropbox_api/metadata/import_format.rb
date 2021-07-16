# frozen_string_literal: true
module DropboxApi::Metadata
  class ImportFormat < Base
    VALID_IMPORT_FORMAT = [
      :html,
      :markdown,
      :plain_text
    ]
  end
end
