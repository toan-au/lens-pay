Rack::Attack.throttle("api/ip", limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?("/api/")
end

Rack::Attack.throttle("api/merchants/create", limit: 10, period: 1.hour) do |req|
  req.ip if req.path == "/api/v1/merchants" && req.post?
end

Rack::Attack.throttle("api/merchant", limit: 300, period: 5.minutes) do |req|
  merchant_id = req.env["current_merchant"]&.id
  merchant_id if req.path.start_with?("/api/")
end

Rack::Attack.throttled_responder = lambda do |_req|
  body = JSON.generate({ error: "Too many requests. Please retry later." })
  [ 429, { "Content-Type" => "application/json" }, [ body ] ]
end
