require 'swagger_helper'

RSpec.describe 'Customers API', type: :request do
  let(:merchant) { create(:merchant) }
  let(:Authorization) { "Bearer #{merchant.raw_api_key}" }

  path '/api/v1/customers' do
    post 'Create a customer' do
      tags 'Customers'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :customer, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Jane Doe' },
          email: { type: :string, example: 'jane@example.com' },
          metadata: { type: :object, example: { tier: 'gold' }, description: 'Arbitrary key-value data' }
        },
        required: %w[name email]
      }

      response '201', 'customer created' do
        let(:customer) { { name: 'Jane Doe', email: 'jane@example.com' } }
        run_test!
      end

      response '422', 'validation failed' do
        let(:customer) { { name: 'Jane Doe' } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:customer) { { name: 'Jane Doe', email: 'jane@example.com' } }
        run_test!
      end
    end

    get 'List customers' do
      tags 'Customers'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :cursor, in: :query, type: :string, required: false, description: 'Pagination cursor (uid of last customer in previous page)'
      parameter name: :limit, in: :query, type: :integer, required: false, description: 'Number of results per page (default: 25)'

      response '200', 'customers listed' do
        before { create_list(:customer, 3, merchant: merchant) }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/customers/{uid}' do
    parameter name: :uid, in: :path, type: :string, description: 'Customer UID', example: 'cus_abc123'

    get 'Fetch a customer' do
      tags 'Customers'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'customer found' do
        let(:uid) { create(:customer, merchant: merchant).uid }
        run_test!
      end

      response '404', 'customer not found' do
        let(:uid) { 'cus_nonexistent' }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'cus_any' }
        run_test!
      end
    end

    patch 'Update a customer' do
      tags 'Customers'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      parameter name: :customer, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: 'Jane Smith' },
          email: { type: :string, example: 'jane.smith@example.com' },
          metadata: { type: :object, example: { tier: 'platinum' } }
        }
      }

      response '200', 'customer updated' do
        let(:uid) { create(:customer, merchant: merchant).uid }
        let(:customer) { { name: 'Jane Smith' } }
        run_test!
      end

      response '422', 'validation failed' do
        let(:uid) { create(:customer, merchant: merchant).uid }
        let(:customer) { { email: 'not-an-email' } }
        run_test!
      end

      response '404', 'customer not found' do
        let(:uid) { 'cus_nonexistent' }
        let(:customer) { { name: 'X' } }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'cus_any' }
        let(:customer) { { name: 'X' } }
        run_test!
      end
    end

    delete 'Delete a customer' do
      tags 'Customers'
      produces 'application/json'
      security [ { bearer_auth: [] } ]

      response '200', 'customer deleted' do
        let(:uid) { create(:customer, merchant: merchant).uid }
        run_test!
      end

      response '404', 'customer not found' do
        let(:uid) { 'cus_nonexistent' }
        run_test!
      end

      response '401', 'unauthorized' do
        let(:Authorization) { 'Bearer invalid' }
        let(:uid) { 'cus_any' }
        run_test!
      end
    end
  end
end
