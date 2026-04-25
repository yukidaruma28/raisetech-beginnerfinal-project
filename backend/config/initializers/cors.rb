# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.
#
# Read more: https://github.com/cyu/rack-cors

# 開発時は Next.js の dev サーバ (http://localhost:3000) を許可。
# 本番では EC2 のフロント配信オリジンを ALLOWED_ORIGINS で注入する想定。
allowed_origins =
  if Rails.env.production?
    ENV.fetch("ALLOWED_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
  else
    %w[http://localhost:3000]
  end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: [],
             max_age: 600
  end
end
