# frozen_string_literal: true
module DropboxApi
  class ConnectionBuilder
    attr_accessor :namespace_id

    def initialize(oauth_bearer = nil, access_token: nil, on_token_refreshed: nil)
      if access_token
        if !access_token.is_a?(OAuth2::AccessToken)
          raise ArgumentError, "access_token should be an OAuth2::AccessToken"
        end

        @access_token = access_token
        @on_token_refreshed = on_token_refreshed
      elsif oauth_bearer
        @oauth_bearer = oauth_bearer
      else
        raise ArgumentError, "Either oauth_bearer or access_token should be set"
      end
    end

    def middleware
      @middleware ||= MiddleWare::Stack.new
    end

    def can_refresh_access_token?
      @access_token && @access_token.refresh_token
    end

    def refresh_access_token
      @access_token = @access_token.refresh!
      @on_token_refreshed.call(@access_token.to_hash) if @on_token_refreshed
    end

    private def bearer
      @oauth_bearer or oauth_bearer_from_access_token
    end

    private def oauth_bearer_from_access_token
      refresh_access_token if @access_token.expired?

      @access_token.token
    end

    def build(url)
      Faraday.new(url) do |connection|
        connection.use DropboxApi::MiddleWare::PathRoot, {
          namespace_id: self.namespace_id
        }
        middleware.apply(connection) do
          connection.request :authorization, 'Bearer', bearer
          yield connection
        end
      end
    end
  end
end
