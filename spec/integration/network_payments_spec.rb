require 'swagger_helper'

RSpec.describe 'Network Payments API', type: :request do
  path '/api/v1/webhooks/network/payments/confirm' do
    post 'Confirm a cash payment (card network)' do
      tags 'Network'
      consumes 'application/json'
      produces 'application/json'
      security [ { network_secret: [] } ]

      parameter name: :'X-Network-Secret', in: :header, type: :string, required: true,
                description: 'Shared secret authenticating the card network'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          reference: { type: :string, example: 'KNB-1A2B3C4D5E6F7788', description: "The network's reference for the payment (provider_reference)" }
        },
        required: %w[reference]
      }

      around { |ex| ClimateControl.modify(NETWORK_SECRET: 'test-secret') { ex.run } }

      response '200', 'payment confirmed' do
        schema '$ref' => '#/components/schemas/payment'
        let(:body) { { reference: create(:transaction, :konbini).provider_reference } }
        let(:'X-Network-Secret') { 'test-secret' }
        run_test!
      end

      response '422', 'not confirmable (card payment or wrong state)' do
        schema '$ref' => '#/components/schemas/error'
        let(:body) { { reference: create(:transaction).provider_reference } }
        let(:'X-Network-Secret') { 'test-secret' }
        run_test!
      end

      response '404', 'unknown reference' do
        schema '$ref' => '#/components/schemas/error'
        let(:body) { { reference: 'KNB-NOPE' } }
        let(:'X-Network-Secret') { 'test-secret' }
        run_test!
      end

      response '401', 'invalid network secret' do
        schema '$ref' => '#/components/schemas/error'
        let(:body) { { reference: 'KNB-ANY' } }
        let(:'X-Network-Secret') { 'wrong-secret' }
        run_test!
      end
    end
  end
end
