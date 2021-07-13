# frozen_string_literal: true
require 'oauth2'

module DropboxApi
  class Token
    extend Forwardable
    def_delegators :@token, :token, :refresh_token, :expired

    def initialize(authenticator, token_hash = nil)
      @authenticator = authenticator
      load_token(token_hash) if token_hash
    end

    def self.get_token(authenticator, code, params = {})
      self.new(authenticator, authenticator.auth_code.get_token(code, params))
    end

    def load_token(token_hash)
      if token_hash.is_a?(OAuth2::AccessToken)
        @token = token_hash
      else
        @token = OAuth2::AccessToken.from_hash(@authenticator, token_hash)
      end
    end

    def refresh_token()
      @token = @token.refresh!
      save!
    end

    def save_token(token_hash); end

    def save!
      save_token(@token.to_hash)
    end

    def short_lived_token()
      refresh_token if @token.expired?
      @token.token
    end
  end
end
