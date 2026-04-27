require 'swagger_helper'

RSpec.describe 'Merchants API', type: :request do
  let(:merchant) { create(:merchant) }
  let(:Authorization) { "Bearer #{merchant.raw_api_key}" }

  path '/api/v1/merchants' do
    post 'Create a merchant' do
      tags 'Merchants'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Acme Store' },
          email: { type: :string, example: 'store@acme.com' },
          country: { type: :string, example: 'JP', description: 'ISO 3166-1 alpha-2 country code' },
          currency: { type: :string, example: 'JPY', description: 'ISO 4217 currency code' },
          webhook_url: { type: :string, example: 'https://acme.com/webhooks', description: 'Optional URL to receive payment event notifications' }
        },
        required: %w[name email country currency]
      }

      response '201', 'merchant created' do
        let(:body) { { name: 'Acme Store', email: 'store@acme.com', country: 'JP', currency: 'JPY' } }
        run_test!
      end

      response '422', 'validation failed' do
        let(:body) { { name: 'Acme Store', email: 'invalid-email', country: 'JP', currency: 'JPY' } }
        run_test!
      end
    end
  end

  path '/api/v1/merchants/me' do
    get 'Fetch own merchant profile' do
      tags 'Merchants'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'merchant found' do
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end

    patch 'Update own merchant profile' do
      tags 'Merchants'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          webhook_url: { type: :string, example: 'https://acme.com/webhooks' }
        }
      }

      response '200', 'merchant updated' do
        let(:body) { { webhook_url: 'https://acme.com/webhooks' } }
        run_test!
      end

      response '422', 'validation failed' do
        let(:body) { { webhook_url: 'not-a-url' } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:body) { {} }
        run_test!
      end
    end
  end
end
