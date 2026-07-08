Rack::Attack.throttle("api/ip", limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?("/api/")
end

Rack::Attack.throttle("api/merchants/create", limit: 10, period: 1.hour) do |req|
  req.ip if req.path == "/api/v1/merchants" && req.post?
end

# Keyed on the presented bearer token, not the authenticated merchant —
# this middleware runs before ApiKeyAuthenticator, so `current_merchant`
# is not available yet. Digested so raw keys never enter the cache.
Rack::Attack.throttle("api/key", limit: 300, period: 5.minutes) do |req|
  auth = req.env["HTTP_AUTHORIZATION"]
  if req.path.start_with?("/api/") && auth&.start_with?("Bearer ")
    Digest::SHA256.hexdigest(auth)
  end
end

Rack::Attack.throttled_responder = lambda do |_req|
  body = JSON.generate({ error: "Too many requests. Please retry later." })
  [ 429, { "Content-Type" => "application/json" }, [ body ] ]
end
