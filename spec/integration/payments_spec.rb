require 'swagger_helper'

RSpec.describe 'Payments API', type: :request do
  let(:merchant) { create(:merchant) }
  let(:Authorization) { "Bearer #{merchant.raw_api_key}" }

  path '/api/v1/payments' do
    post 'Create a payment' do
      tags 'Payments'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :payment, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :integer, example: 1000, description: 'Amount in smallest currency unit (e.g. yen)' },
          currency: { type: :string, example: 'JPY', description: 'ISO 4217 currency code' },
          idempotency_key: { type: :string, example: 'order_abc_123', description: 'Unique key to prevent duplicate payments' }
        },
        required: %w[amount currency idempotency_key]
      }

      response '201', 'payment created' do
        let(:payment) { { amount: 1000, currency: 'JPY', idempotency_key: 'order_123' } }
        run_test!
      end

      response '400', 'invalid currency' do
        let(:payment) { { amount: 1000, currency: 'INVALID', idempotency_key: 'order_123' } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:payment) { { amount: 1000, currency: 'JPY', idempotency_key: 'order_123' } }
        run_test!
      end
    end

    get 'List payments' do
      tags 'Payments'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :cursor, in: :query, type: :string, required: false, description: 'Pagination cursor (uid of last payment in previous page)'
      parameter name: :status, in: :query, type: :string, required: false, description: 'Filter by status (pending, authorized, processing, succeeded, declined)'
      parameter name: :limit, in: :query, type: :integer, required: false, description: 'Number of results per page (default: 25, max: 100)'

      response '200', 'payments listed' do
        before { create_list(:transaction, 3, merchant: merchant) }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/payments/{uid}' do
    parameter name: :uid, in: :path, type: :string, description: 'Payment UID', example: 'tr_abc123'

    get 'Fetch a payment' do
      tags 'Payments'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'payment found' do
        let(:uid) { create(:transaction, merchant: merchant).uid }
        run_test!
      end

      response '404', 'payment not found' do
        let(:uid) { 'tr_nonexistent' }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'tr_any' }
        run_test!
      end
    end
  end

  path '/api/v1/payments/{uid}/authorize' do
    parameter name: :uid, in: :path, type: :string, description: 'Payment UID'

    post 'Authorize a payment' do
      tags 'Payment Transitions'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'payment authorized' do
        let(:uid) { create(:transaction, merchant: merchant).uid }
        run_test!
      end

      response '422', 'invalid transition' do
        let(:uid) { create(:transaction, :authorized, merchant: merchant).uid }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'tr_any' }
        run_test!
      end
    end
  end

  path '/api/v1/payments/{uid}/capture' do
    parameter name: :uid, in: :path, type: :string, description: 'Payment UID'

    post 'Capture a payment' do
      tags 'Payment Transitions'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, required: false, schema: {
        type: :object,
        properties: {
          captured_amount: { type: :integer, example: 800, description: 'Amount to capture (defaults to full authorized amount)' }
        }
      }

      response '200', 'payment captured' do
        let(:uid) { create(:transaction, :authorized, amount: 1000, merchant: merchant).uid }
        let(:body) { { captured_amount: 800 } }
        run_test!
      end

      response '422', 'invalid transition' do
        let(:uid) { create(:transaction, merchant: merchant).uid }
        let(:body) { {} }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'tr_any' }
        let(:body) { {} }
        run_test!
      end
    end
  end

  path '/api/v1/payments/{uid}/complete' do
    parameter name: :uid, in: :path, type: :string, description: 'Payment UID'

    post 'Complete a payment' do
      tags 'Payment Transitions'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'payment succeeded' do
        let(:uid) { create(:transaction, :processing, merchant: merchant).uid }
        run_test!
      end

      response '422', 'invalid transition' do
        let(:uid) { create(:transaction, merchant: merchant).uid }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'tr_any' }
        run_test!
      end
    end
  end

  path '/api/v1/payments/{uid}/decline' do
    parameter name: :uid, in: :path, type: :string, description: 'Payment UID'

    post 'Decline a payment' do
      tags 'Payment Transitions'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'payment declined' do
        let(:uid) { create(:transaction, merchant: merchant).uid }
        run_test!
      end

      response '422', 'invalid transition' do
        let(:uid) { create(:transaction, :succeeded, merchant: merchant).uid }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'tr_any' }
        run_test!
      end
    end
  end

  path '/api/v1/payments/{payment_uid}/refunds' do
    parameter name: :payment_uid, in: :path, type: :string, description: 'Payment UID'

    post 'Create a refund' do
      tags 'Refunds'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :refund, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :integer, example: 500, description: 'Amount to refund in smallest currency unit' }
        },
        required: %w[amount]
      }

      response '201', 'refund created' do
        let(:payment_uid) { create(:transaction, :succeeded, captured_amount: 1000, merchant: merchant).uid }
        let(:refund) { { amount: 500, idempotency_key: "duck_duck_goose" } }
        run_test!
      end

      response '422', 'payment not succeeded' do
        let(:payment_uid) { create(:transaction, merchant: merchant).uid }
        let(:refund) { { amount: 500, idempotency_key: "duck_duck_goose" } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:payment_uid) { 'tr_any' }
        let(:refund) { { amount: 500, idempotency_key: "duck_duck_goose" } }
        run_test!
      end
    end

    get 'List refunds for a payment' do
      tags 'Refunds'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'refunds listed' do
        let(:payment_uid) do
          payment = create(:transaction, :succeeded, captured_amount: 1000, merchant: merchant)
          create(:refund, payment: payment, amount: 500)
          payment.uid
        end
        run_test!
      end

      response '404', 'payment not found' do
        let(:payment_uid) { 'tr_nonexistent' }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:payment_uid) { 'tr_any' }
        run_test!
      end
    end
  end
end
