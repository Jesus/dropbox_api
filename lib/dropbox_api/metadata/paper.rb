# frozen_string_literal: true
module DropboxApi::Metadata
  class Paper < Base
    field :url, String
    field :result_path, String
    field :file_id, String
    field :paper_revision, Integer
  end
end
