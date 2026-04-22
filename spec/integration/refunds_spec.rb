require 'swagger_helper'

RSpec.describe 'Refunds API', type: :request do
  let(:merchant) { create(:merchant) }
  let(:Authorization) { "Bearer #{merchant.raw_api_key}" }

  path '/api/v1/refunds' do
    get 'List all refunds' do
      tags 'Refunds'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :cursor, in: :query, type: :string, required: false, description: 'Pagination cursor (uid of last refund in previous page)'
      parameter name: :status, in: :query, type: :string, required: false, description: 'Filter by status (pending, succeeded, declined)'
      parameter name: :limit, in: :query, type: :integer, required: false, description: 'Number of results per page (default: 25, max: 100)'

      response '200', 'refunds listed' do
        before do
          payment = create(:transaction, :succeeded, captured_amount: 1000, merchant: merchant)
          create(:refund, payment: payment, amount: 500)
        end
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end
  end
end
