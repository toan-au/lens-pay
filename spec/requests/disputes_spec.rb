require 'rails_helper'

RSpec.describe "Disputes API", type: :request do
  let(:merchant)       { create(:merchant) }
  let(:other_merchant) { create(:merchant) }
  let(:auth_headers)   { { 'Authorization' => "Bearer #{merchant.raw_api_key}" } }

end
