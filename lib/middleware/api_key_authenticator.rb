module Middleware
  class ApiKeyAuthenticator
    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) if unauthenticated?(env)

      token = extract_token(env)
      return unauthorized("Missing Authorization header") unless token

      merchant = Merchant.find_by(api_key_digest: Digest::SHA256.hexdigest(token))
      return unauthorized("Invalid API key") unless merchant

      env["current_merchant"] = merchant
      @app.call(env)
    end

    private

    def unauthenticated?(env)
      env["PATH_INFO"] == "/up" ||
      (env["PATH_INFO"] == "/api/v1/merchants" && env["REQUEST_METHOD"] == "POST") ||
      env["PATH_INFO"].start_with?("/api-docs")
    end

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
