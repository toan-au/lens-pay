module Middleware
  class ApiKeyAuthenticator
    UNAUTHENTICATED_PATHS = %w[/up].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) if UNAUTHENTICATED_PATHS.include?(env["PATH_INFO"])

      token = extract_token(env)
      return unauthorized("Missing Authorization header") unless token

      merchant = Merchant.find_by(api_key_digest: Digest::SHA256.hexdigest(token))
      return unauthorized("Invalid API key") unless merchant

      env["current_merchant"] = merchant
      @app.call(env)
    end

    private

    def extract_token(env)
      header = env["HTTP_AUTHORIZATION"]
      return nil unless header&.start_with?("Bearer ")
      header.split(" ", 2).last
    end

    def unauthorized(message)
      body = JSON.generate({ error: message })
      [ 401, { "Content-Type" => "application/json" }, [ body ] ]
    end
  end
end
