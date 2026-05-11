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

    NON_API_PATHS = %w[/up /api-docs].freeze

    PUBLIC_ROUTES = [
      [ "POST", "/api/v1/merchants" ],
      [ "POST", %r{\A/api/v1/webhooks/mch_} ]
    ].freeze

    def unauthenticated?(env)
      path = env["PATH_INFO"]
      return true unless path.start_with?("/api")
      return true if NON_API_PATHS.any? { |p| path.start_with?(p) }

      PUBLIC_ROUTES.any? do |method, pattern|
        env["REQUEST_METHOD"] == method &&
          (pattern.is_a?(Regexp) ? pattern.match?(path) : path == pattern)
      end
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
