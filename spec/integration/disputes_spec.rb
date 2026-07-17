require 'swagger_helper'

RSpec.describe 'Disputes API', type: :request do
  let(:merchant) { create(:merchant) }
  let(:Authorization) { "Bearer #{merchant.raw_api_key}" }

  path '/api/v1/disputes' do
    get 'List disputes' do
      tags 'Disputes'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :cursor, in: :query, type: :string, required: false, description: 'Pagination cursor'
      parameter name: :status, in: :query, type: :string, required: false, description: 'Filter by status (open, merchant_responded, won, lost)'
      parameter name: :limit, in: :query, type: :integer, required: false, description: 'Results per page (default: 25, max: 100)'

      response '200', 'disputes listed' do
        schema '$ref' => '#/components/schemas/dispute_list'
        before { create(:dispute, merchant: merchant) }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/disputes/{uid}' do
    parameter name: :uid, in: :path, type: :string, description: 'Dispute UID'

    get 'Fetch a dispute' do
      tags 'Disputes'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'dispute found' do
        schema '$ref' => '#/components/schemas/dispute'
        let(:uid) { create(:dispute, merchant: merchant).uid }
        run_test!
      end

      response '404', 'dispute not found' do
        schema '$ref' => '#/components/schemas/error'
        let(:uid) { 'dis_nonexistent' }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'dis_any' }
        run_test!
      end
    end
  end

  path '/api/v1/disputes/{uid}/respond' do
    parameter name: :uid, in: :path, type: :string, description: 'Dispute UID'

    patch 'Submit evidence for a dispute' do
      tags 'Disputes'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          evidence: {
            type: :object,
            description: 'Free-form key-value evidence (tracking numbers, order confirmations, etc.)',
            example: { tracking_number: '1Z999AA', order_date: '2026-01-01' }
          }
        },
        required: %w[evidence]
      }

      response '200', 'evidence submitted' do
        schema '$ref' => '#/components/schemas/dispute_response'
        let(:uid) { create(:dispute, merchant: merchant).uid }
        let(:body) { { evidence: { tracking_number: '1Z999AA' } } }
        run_test!
      end

      response '422', 'invalid submission' do
        schema '$ref' => '#/components/schemas/error'
        let(:uid) { create(:dispute, :won, merchant: merchant).uid }
        let(:body) { { evidence: { tracking_number: '1Z999AA' } } }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'dis_any' }
        let(:body) { { evidence: {} } }
        run_test!
      end
    end
  end

  path '/api/v1/webhooks/network/disputes' do
    post 'Open a dispute (card network)' do
      tags 'Network'
      consumes 'application/json'
      produces 'application/json'
      security [ { network_secret: [] } ]

      parameter name: :'X-Network-Secret', in: :header, type: :string, required: true,
                description: 'Shared secret authenticating the card network'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          payment_reference: { type: :string, example: 'CRD-1A2B3C4D5E6F7788', description: "The network's reference for the payment (transaction provider_reference)" },
          case_reference:    { type: :string, example: 'CASE-2026-0001', description: "The network's case number; retries with the same case return the existing dispute" },
          reason:            { type: :string, enum: %w[fraudulent unrecognized duplicate product_not_received product_unacceptable] },
          amount:            { type: :integer, example: 5000 },
          currency:          { type: :string, example: 'JPY' }
        },
        required: %w[payment_reference case_reference reason amount currency]
      }

      around { |ex| ClimateControl.modify(NETWORK_SECRET: 'test-secret') { ex.run } }

      response '201', 'dispute opened' do
        schema '$ref' => '#/components/schemas/dispute'
        let(:payment) { create(:transaction, :succeeded, amount: 5000, currency: 'JPY') }
        let(:body) { { payment_reference: payment.provider_reference, case_reference: 'CASE-0100', reason: 'fraudulent', amount: 5000, currency: 'JPY' } }
        let(:'X-Network-Secret') { 'test-secret' }
        run_test!
      end

      response '401', 'invalid network secret' do
        schema '$ref' => '#/components/schemas/error'
        let(:payment) { create(:transaction, :succeeded, amount: 5000, currency: 'JPY') }
        let(:body) { { payment_reference: payment.provider_reference, case_reference: 'CASE-0100', reason: 'fraudulent', amount: 5000, currency: 'JPY' } }
        let(:'X-Network-Secret') { 'wrong-secret' }
        run_test!
      end

      response '422', 'invalid dispute' do
        schema '$ref' => '#/components/schemas/error'
        let(:payment) { create(:transaction, amount: 5000, currency: 'JPY') }
        let(:body) { { payment_reference: payment.provider_reference, case_reference: 'CASE-0100', reason: 'fraudulent', amount: 5000, currency: 'JPY' } }
        let(:'X-Network-Secret') { 'test-secret' }
        run_test!
      end
    end
  end

  path '/api/v1/webhooks/network/disputes/resolve' do
    post 'Resolve a dispute (card network)' do
      tags 'Network'
      consumes 'application/json'
      produces 'application/json'
      security [ { network_secret: [] } ]

      parameter name: :'X-Network-Secret', in: :header, type: :string, required: true,
                description: 'Shared secret authenticating the card network'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          case_reference: { type: :string, example: 'CASE-2026-0001', description: "The network's case number from dispute opening" },
          outcome: { type: :string, enum: %w[won lost], example: 'won' }
        },
        required: %w[case_reference outcome]
      }

      around { |ex| ClimateControl.modify(NETWORK_SECRET: 'test-secret') { ex.run } }

      response '200', 'dispute resolved' do
        schema '$ref' => '#/components/schemas/dispute'
        let(:body) { { case_reference: create(:dispute, merchant: merchant).provider_reference, outcome: 'won' } }
        let(:'X-Network-Secret') { 'test-secret' }
        run_test!
      end

      response '401', 'invalid network secret' do
        schema '$ref' => '#/components/schemas/error'
        let(:body) { { case_reference: create(:dispute, merchant: merchant).provider_reference, outcome: 'won' } }
        let(:'X-Network-Secret') { 'wrong-secret' }
        run_test!
      end

      response '422', 'already resolved' do
        schema '$ref' => '#/components/schemas/error'
        let(:body) { { case_reference: create(:dispute, :won, merchant: merchant).provider_reference, outcome: 'lost' } }
        let(:'X-Network-Secret') { 'test-secret' }
        run_test!
      end
    end
  end
end
