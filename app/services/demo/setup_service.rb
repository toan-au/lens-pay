module Demo
  class SetupService < ApplicationService
    Result = Data.define(:merchant, :api_key)

    def perform
      @merchant = Merchant.create!(
        name: "Demo Store",
        email: "demo_#{SecureRandom.hex(8)}@lenspay.demo",
        country: "JP",
        currency: "JPY",
        is_demo: true,
        demo_expires_at: 24.hours.from_now
      )

      api_key = @merchant.raw_api_key

      seed_customers
      seed_payments

      Result.new(merchant: @merchant, api_key:)
    end

    def event_name = "demo.setup"
    def log_context = {}

    private

    def seed_customers
      @alice = @merchant.customers.create!(name: "Alice Johnson", email: "alice@example.com")
      @bob   = @merchant.customers.create!(name: "Bob Smith",     email: "bob@example.com")
    end

    def seed_payments
      # Succeeded payment with a full refund
      succeeded_with_refund = @merchant.transactions.create!(
        amount: 15000, currency: "JPY", status: :succeeded, captured_amount: 15000,
        idempotency_key: SecureRandom.uuid,
        customer: @alice, customer_name: @alice.name, customer_email: @alice.email,
        metadata: { order_id: "order_001" },
        created_at: 3.days.ago
      )
      emit_event("payment.authorized", succeeded_with_refund, created_at: 3.days.ago)
      emit_event("payment.captured",   succeeded_with_refund, created_at: 3.days.ago + 2.seconds)
      emit_event("payment.refunded",   succeeded_with_refund, created_at: 2.days.ago)

      refund = succeeded_with_refund.refunds.create!(
        amount: 15000, status: :succeeded, idempotency_key: SecureRandom.uuid,
        created_at: 2.days.ago
      )
      emit_event("payment.refund.created", refund, created_at: 2.days.ago)

      # Succeeded payment with a partial refund
      succeeded_partial = @merchant.transactions.create!(
        amount: 8999, currency: "JPY", status: :succeeded, captured_amount: 8999,
        idempotency_key: SecureRandom.uuid,
        customer: @bob, customer_name: @bob.name, customer_email: @bob.email,
        metadata: { order_id: "order_002" },
        created_at: 2.days.ago
      )
      emit_event("payment.authorized", succeeded_partial, created_at: 2.days.ago)
      emit_event("payment.captured",   succeeded_partial, created_at: 2.days.ago + 2.seconds)
      emit_event("payment.refunded",   succeeded_partial, created_at: 1.day.ago)

      partial_refund = succeeded_partial.refunds.create!(
        amount: 3000, status: :succeeded, idempotency_key: SecureRandom.uuid,
        created_at: 1.day.ago
      )
      emit_event("payment.refund.created", partial_refund, created_at: 1.day.ago)

      # Authorized payment waiting to be captured
      authorized = @merchant.transactions.create!(
        amount: 20000, currency: "JPY", status: :authorized, captured_amount: nil,
        idempotency_key: SecureRandom.uuid,
        metadata: { order_id: "order_003" },
        created_at: 1.hour.ago
      )
      emit_event("payment.authorized", authorized, created_at: 1.hour.ago)

      # Cancelled payment
      cancelled = @merchant.transactions.create!(
        amount: 5000, currency: "JPY", status: :cancelled, captured_amount: nil,
        idempotency_key: SecureRandom.uuid,
        customer: @alice, customer_name: @alice.name, customer_email: @alice.email,
        created_at: 4.days.ago
      )
      emit_event("payment.authorized", cancelled, created_at: 4.days.ago)
      emit_event("payment.cancelled",  cancelled, created_at: 4.days.ago + 1.minute)

      # Declined payment (rejected by card network)
      declined = @merchant.transactions.create!(
        amount: 9999, currency: "JPY", status: :declined, captured_amount: nil,
        idempotency_key: SecureRandom.uuid,
        customer: @bob, customer_name: @bob.name, customer_email: @bob.email,
        metadata: { order_id: "order_004" },
        created_at: 1.day.ago
      )
      emit_event("payment.authorized", declined, created_at: 1.day.ago)
      emit_event("payment.failed",     declined, created_at: 1.day.ago + 3.seconds)
    end

    def emit_event(event_type, resource, created_at:)
      event_id = "evt_#{SecureRandom.hex(16)}"
      payload = JSON.parse(
        Webhooks::BuildPayloadService.call(event_type:, resource:, event_id:)
      )
      @merchant.webhook_events.create!(
        event_type:,
        payload:,
        created_at:
      )
    end
  end
end
