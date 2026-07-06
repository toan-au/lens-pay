require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  before do
    @original_store = Rack::Attack.cache.store
    # Test env caches with :null_store, which never accumulates counters —
    # throttles need a real store to be observable.
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.cache.store = @original_store
  end

  describe "per-IP throttle" do
    it "throttles repeated requests with an invalid API key" do
      headers = { "Authorization" => "Bearer sk_invalid" }

      300.times { get("/api/v1/merchants/me", headers:) }
      expect(response).to have_http_status(:unauthorized)

      get("/api/v1/merchants/me", headers:)
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "per-API-key throttle" do
    it "throttles a single API key even when requests come from different IPs" do
      merchant = create(:merchant)
      headers = { "Authorization" => "Bearer #{merchant.raw_api_key}" }

      150.times { get("/api/v1/merchants/me", headers:, env: { "REMOTE_ADDR" => "10.0.0.1" }) }
      150.times { get("/api/v1/merchants/me", headers:, env: { "REMOTE_ADDR" => "10.0.0.2" }) }
      expect(response).to have_http_status(:ok)

      get("/api/v1/merchants/me", headers:, env: { "REMOTE_ADDR" => "10.0.0.3" })
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
