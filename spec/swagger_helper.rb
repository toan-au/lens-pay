# frozen_string_literal: true

require 'rails_helper'

API_DESCRIPTION = <<~MD
  Payment processing API for LensPay. Covers merchant onboarding, customers,
  the full payment lifecycle (authorize, capture, cancel, expire), refunds,
  disputes, and signed webhook delivery.

  ## Authentication
  All endpoints except merchant registration, demo sessions, and webhook sinks
  require `Authorization: Bearer <api_key>`. API keys are shown once at
  registration and stored only as a SHA256 digest.

  ## Amounts
  All amounts are integers in the smallest currency unit (yen for JPY, cents
  for USD). Currencies are ISO 4217 codes.

  ## Idempotency
  Payment and refund creation require an `idempotency_key`. Retrying a request
  with the same key returns the original resource instead of creating a
  duplicate, so network timeouts never double-charge.

  ## Pagination
  List endpoints use cursor pagination. Pass the `next_cursor` from a response
  as the `cursor` query param to fetch the next page. A null `next_cursor`
  means there are no further pages.

  ## Rate limiting
  Requests are throttled per IP (300 per 5 minutes), per API key (300 per
  5 minutes), and per IP for merchant registration (10 per hour). Exceeding a
  limit returns `429 Too Many Requests`; retry after the window passes.

  ## Webhooks
  State transitions POST a signed JSON event to the merchant's `webhook_url`.
  The `X-LensPay-Signature` header carries `sha256=<hex>`, an HMAC-SHA256 of
  the raw request body using the merchant's `webhook_secret`. Verify with a
  constant-time comparison.
MD

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'LensPay API',
        version: 'v1',
        description: API_DESCRIPTION
      },
      paths: {},
      # Relative so Swagger UI's "Try it out" targets whichever host serves
      # the docs — localhost in development, the real domain in production.
      servers: [
        { url: '/' }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer
          }
        },
        schemas: {
          error: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Payment not found' }
            },
            required: %w[error]
          },
          validation_errors: {
            type: :object,
            properties: {
              errors: { type: :array, items: { type: :string }, example: [ 'Amount must be greater than 0' ] }
            },
            required: %w[errors]
          },
          payment_customer: {
            type: :object,
            nullable: true,
            description: 'Customer details snapshotted at payment creation',
            properties: {
              uid: { type: :string, nullable: true, example: 'cus_abc123' },
              name: { type: :string, example: 'Alice Johnson' },
              email: { type: :string, example: 'alice@example.com' }
            }
          },
          dispute_summary: {
            type: :object,
            nullable: true,
            description: 'Active dispute attached to the payment, if any',
            properties: {
              uid: { type: :string, example: 'dis_abc123' },
              status: { type: :string, enum: %w[open merchant_responded won lost] },
              reason: { type: :string, enum: Dispute::REASONS },
              amount: { type: :integer, example: 1000 },
              currency: { type: :string, example: 'JPY' },
              respond_by: { type: :string, format: 'date-time' },
              resolved_at: { type: :string, format: 'date-time', nullable: true }
            }
          },
          payment: {
            type: :object,
            properties: {
              uid: { type: :string, example: 'tr_abc123' },
              amount: { type: :integer, description: 'Amount in smallest currency unit', example: 1000 },
              currency: { type: :string, description: 'ISO 4217 code', example: 'JPY' },
              status: { type: :string, enum: %w[pending authorized processing succeeded declined cancelled expired] },
              captured_amount: { type: :integer, nullable: true, description: 'Set on capture; may be less than amount' },
              idempotency_key: { type: :string, example: 'order_abc_123' },
              customer_name: { type: :string, nullable: true, description: 'Snapshot taken at creation' },
              customer_email: { type: :string, nullable: true, description: 'Snapshot taken at creation' },
              provider_reference: { type: :string, nullable: true },
              metadata: { type: :object, nullable: true, description: 'Free-form merchant-supplied context' },
              customer: { '$ref' => '#/components/schemas/payment_customer' },
              dispute: { '$ref' => '#/components/schemas/dispute_summary' },
              dispute_status: { type: :string, nullable: true, enum: %w[open merchant_responded won lost], description: 'Present on list payloads when an active dispute exists' },
              expires_at: { type: :string, format: 'date-time', nullable: true },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[uid amount currency status idempotency_key created_at]
          },
          payment_list: {
            type: :object,
            properties: {
              payments: { type: :array, items: { '$ref' => '#/components/schemas/payment' } },
              next_cursor: { type: :string, nullable: true, description: 'uid of the last payment; null when no further pages' }
            },
            required: %w[payments next_cursor]
          },
          customer: {
            type: :object,
            properties: {
              uid: { type: :string, example: 'cus_abc123' },
              name: { type: :string, example: 'Alice Johnson' },
              email: { type: :string, example: 'alice@example.com' },
              metadata: { type: :object, nullable: true },
              deleted_at: { type: :string, format: 'date-time', nullable: true },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[uid name email created_at]
          },
          customer_list: {
            type: :object,
            properties: {
              customers: { type: :array, items: { '$ref' => '#/components/schemas/customer' } },
              next_cursor: { type: :string, nullable: true }
            },
            required: %w[customers next_cursor]
          },
          refund: {
            type: :object,
            properties: {
              uid: { type: :string, example: 're_abc123' },
              amount: { type: :integer, example: 500 },
              status: { type: :string, enum: %w[pending succeeded failed] },
              idempotency_key: { type: :string },
              payment_uid: { type: :string, description: 'Present on the merchant-wide refunds list' },
              currency: { type: :string, description: 'Present on the merchant-wide refunds list' },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[uid amount status created_at]
          },
          refund_list: {
            type: :object,
            properties: {
              refunds: { type: :array, items: { '$ref' => '#/components/schemas/refund' } },
              next_cursor: { type: :string, nullable: true }
            },
            required: %w[refunds]
          },
          dispute_response: {
            type: :object,
            description: 'Evidence submission; identified by integer id (no uid)',
            properties: {
              id: { type: :integer },
              evidence: { type: :object, example: { receipt: 'order_123' } },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id evidence created_at]
          },
          dispute: {
            type: :object,
            properties: {
              uid: { type: :string, example: 'dis_abc123' },
              amount: { type: :integer, example: 1000 },
              currency: { type: :string, example: 'JPY' },
              reason: { type: :string, enum: Dispute::REASONS },
              status: { type: :string, enum: %w[open merchant_responded won lost] },
              respond_by: { type: :string, format: 'date-time', description: 'Evidence deadline' },
              resolved_at: { type: :string, format: 'date-time', nullable: true },
              dispute_responses: { type: :array, items: { '$ref' => '#/components/schemas/dispute_response' }, description: 'Present on the dispute detail payload' },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[uid amount currency reason status respond_by created_at]
          },
          dispute_list: {
            type: :object,
            properties: {
              disputes: { type: :array, items: { '$ref' => '#/components/schemas/dispute' } },
              next_cursor: { type: :string, nullable: true }
            },
            required: %w[disputes next_cursor]
          },
          webhook_event: {
            type: :object,
            description: 'Received webhook event; identified by integer id (no uid)',
            properties: {
              id: { type: :integer },
              event_type: { type: :string, example: 'payment.succeeded' },
              payload: { type: :object },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id event_type payload created_at]
          },
          webhook_event_list: {
            type: :object,
            properties: {
              webhook_events: { type: :array, items: { '$ref' => '#/components/schemas/webhook_event' } },
              next_cursor: { type: :integer, nullable: true, description: 'id of the last event; null when no further pages. Absent on the per-payment event list.' }
            },
            required: %w[webhook_events]
          },
          merchant: {
            type: :object,
            properties: {
              uid: { type: :string, example: 'mch_abc123' },
              name: { type: :string, example: 'Demo Store' },
              email: { type: :string, example: 'store@example.com' },
              country: { type: :string, example: 'JP' },
              currency: { type: :string, example: 'JPY' },
              status: { type: :string, enum: %w[pending active suspended] },
              webhook_url: { type: :string, nullable: true },
              webhook_secret: { type: :string, description: 'Used to verify webhook signatures' }
            },
            required: %w[uid name email country currency status]
          },
          merchant_credentials: {
            type: :object,
            description: 'Returned once at registration; the api_key is never shown again',
            properties: {
              uid: { type: :string, example: 'mch_abc123' },
              api_key: { type: :string, example: 'sk_0123abcd...' },
              webhook_secret: { type: :string, example: 'whs_0123abcd...' }
            },
            required: %w[uid api_key webhook_secret]
          }
        }
      }, security: [ { bearer_auth: [] } ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
