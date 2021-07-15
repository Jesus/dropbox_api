# frozen_string_literal: true
module DropboxApi::Endpoints::Files
  class PaperCreate < DropboxApi::Endpoints::RpcUpload
    Method      = :post
    Path        = '/2/files/paper/create'
    ResultType  = DropboxApi::Metadata::File
    ErrorType   = DropboxApi::Errors::UploadError

    include DropboxApi::OptionsValidator

    add_endpoint :paper_create do |path, content, options = {}|
      validate_options([
        :import_format
      ], options)

      options[:path] = path
      commit_info = DropboxApi::Metadata::CommitInfo.build_from_options options
      perform_request(commit_info.to_hash, content)
    end
  end
end
