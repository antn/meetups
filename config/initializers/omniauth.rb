# frozen_string_literal: true

require Rails.root.join("lib/omniauth/strategies/concat")

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :concat, ENV["CONCAT_CLIENT_ID"], ENV["CONCAT_CLIENT_SECRET"],
    scope: "pii:basic pii:email"
end
