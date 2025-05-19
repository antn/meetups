# frozen_string_literal: true

module OmniAuth
  module Strategies
    class Concat < OmniAuth::Strategies::OAuth2
      option :name, "concat"

      option :client_options, {
        site: "https://reg.offkaiexpo.com",
        authorize_url: "/oauth/authorize",
        token_url: "/api/oauth/token",
      }

      uid { raw_info["id"] }

      info do
        {
          username: raw_info["username"],
          email: raw_info["email"]
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get("api/users/current").parsed
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
