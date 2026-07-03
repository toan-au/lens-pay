require "rails_helper"

RSpec.describe "Frontend catch-all", type: :request do
  it "serves the SPA for HTML navigation requests" do
    get "/payments/tr_something", headers: { "Accept" => "text/html" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<div id="app">')
  end

  it "returns 404 for non-HTML scanner probes instead of 500" do
    get "/cms/wp-includes/wlwmanifest.xml"

    expect(response).to have_http_status(:not_found)
  end
end
