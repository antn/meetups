# OmniAuth authentication middleware.
#
# Add real providers by bundling a strategy gem (e.g. omniauth-google-oauth2,
# omniauth-github) and uncommenting a `provider` line below. Read credentials
# from the environment via dotenv (see .env / .env.example).
#
# omniauth-rails_csrf_protection (already bundled) requires auth requests to be
# POSTs, so link to providers with `button_to "/auth/:provider", method: :post`.
require Rails.root.join("lib", "omni_auth", "strategies", "concat")

Rails.application.config.middleware.use OmniAuth::Builder do
  # The built-in developer strategy gives you a fake login form in development.
  # Visit /auth/developer to use it. Never enable this in production.
  provider :developer if Rails.env.development?

  provider :concat, ENV["CONCAT_CLIENT_ID"], ENV["CONCAT_CLIENT_SECRET"],
    scope: "pii:basic pii:email"
end

OmniAuth.config.logger = Rails.logger
