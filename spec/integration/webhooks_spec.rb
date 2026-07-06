require 'swagger_helper'

RSpec.describe 'Webhooks API', type: :request do
  let(:merchant) { create(:merchant) }
  let(:Authorization) { "Bearer #{merchant.raw_api_key}" }

  path '/api/v1/webhooks' do
    get 'List webhook events' do
      tags 'Webhooks'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'webhook events listed' do
        schema '$ref' => '#/components/schemas/webhook_event_list'
        before { create(:webhook_event, merchant: merchant) }
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/webhooks/ping' do
    post 'Fire a test ping webhook' do
      tags 'Webhooks'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'ping enqueued' do
        run_test!
      end

      response '401', 'unauthorized' do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/webhooks/{merchant_uid}' do
    parameter name: :merchant_uid, in: :path, type: :string, description: 'Merchant UID'

    post 'Receive a signed webhook event' do
      tags 'Webhooks'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :'X-LensPay-Signature', in: :header, type: :string, required: false,
                description: 'HMAC-SHA256 signature: sha256=<hex digest of raw body using webhook_secret>'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          type: { type: :string, example: 'payment.succeeded' },
          data: { type: :object }
        },
        required: %w[type]
      }

      response '200', 'event stored' do
        let(:merchant_uid) { merchant.uid }
        let(:body) { { type: 'payment.succeeded', data: {} } }
        let(:'X-LensPay-Signature') do
          "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", merchant.webhook_secret, body.to_json)
        end
        run_test!
      end

      response '401', 'invalid signature' do
        schema '$ref' => '#/components/schemas/error'
        let(:merchant_uid) { merchant.uid }
        let(:body) { { type: 'payment.succeeded', data: {} } }
        let(:'X-LensPay-Signature') { 'sha256=invalidsignature' }
        run_test!
      end

      response '404', 'merchant not found' do
        schema '$ref' => '#/components/schemas/error'
        let(:merchant_uid) { 'mer_nonexistent' }
        let(:body) { { type: 'payment.succeeded', data: {} } }
        run_test!
      end
    end
  end
end
