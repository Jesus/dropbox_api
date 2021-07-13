# frozen_string_literal: true
require 'oauth2'

module DropboxApi
  class Authenticator < OAuth2::Client
    def initialize(client_id, client_secret)
      super(client_id, client_secret, {
        authorize_url: 'https://www.dropbox.com/oauth2/authorize',
        token_url: 'https://api.dropboxapi.com/oauth2/token'
      })
    end
  end
end
