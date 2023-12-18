# frozen_string_literal: true

module DropboxApi::Metadata
  class SearchMatchTypeV2 < DropboxApi::Metadata::Tag
    # both_filename_and_content is undocumented, but it's returned by the API.
    VALID_VALUES = %i[
      filename
      file_content
      filename_and_content
      both_filename_and_content
      image_content
    ].freeze

    def self.valid_values
      VALID_VALUES
    end
  end
end
