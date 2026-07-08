require "rails_helper"

# Routing-level assertion so CI doesn't need a Vite build to render the
# layout — the catch-all constraint is what these specs guard.
RSpec.describe "Frontend catch-all routing", type: :routing do
  it "routes HTML navigation paths to the SPA" do
    expect(get: "/payments/tr_something")
      .to route_to(controller: "frontend", action: "index", path: "payments/tr_something")
  end

  it "does not route non-HTML paths" do
    expect(get: "/cms/wp-includes/wlwmanifest.xml").not_to be_routable
  end
end

RSpec.describe "Frontend catch-all", type: :request do
  it "returns 404 for non-HTML scanner probes instead of 500" do
    get "/cms/wp-includes/wlwmanifest.xml"

    expect(response).to have_http_status(:not_found)
  end
end
