# frozen_string_literal: true
module DropboxApi
  class ConnectionBuilder
    attr_accessor :namespace_id

    def initialize(oauth_bearer)
      @oauth_bearer = oauth_bearer
    end

    def middleware
      @middleware ||= MiddleWare::Stack.new
    end

    def build(url)
      Faraday.new(url) do |connection|
        connection.use DropboxApi::MiddleWare::PathRoot, {
          namespace_id: self.namespace_id
        }
        middleware.apply(connection) do
          connection.authorization :Bearer, @oauth_bearer.is_a?(DropboxApi::Token) ? @oauth_bearer.short_lived_token : @oauth_bearer
          yield connection
        end
      end
    end
  end
end
