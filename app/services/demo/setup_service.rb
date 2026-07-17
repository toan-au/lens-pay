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
      seed_disputes

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
      @succeeded_with_refund = @merchant.transactions.create!(
        amount: 15000, currency: "JPY", status: :succeeded, captured_amount: 15000,
        idempotency_key: SecureRandom.uuid,
        customer: @alice, customer_name: @alice.name, customer_email: @alice.email,
        metadata: { order_id: "order_001" },
        created_at: 3.days.ago
      )
      emit_event("payment.authorized", @succeeded_with_refund, created_at: 3.days.ago)
      emit_event("payment.captured",   @succeeded_with_refund, created_at: 3.days.ago + 2.seconds)
      emit_event("payment.refunded",   @succeeded_with_refund, created_at: 2.days.ago)

      refund = @succeeded_with_refund.refunds.create!(
        amount: 15000, status: :succeeded, idempotency_key: SecureRandom.uuid,
        created_at: 2.days.ago
      )
      emit_event("payment.refund.created", refund, created_at: 2.days.ago)

      # Succeeded payment with a partial refund
      @succeeded_partial = @merchant.transactions.create!(
        amount: 8999, currency: "JPY", status: :succeeded, captured_amount: 8999,
        idempotency_key: SecureRandom.uuid,
        customer: @bob, customer_name: @bob.name, customer_email: @bob.email,
        metadata: { order_id: "order_002" },
        created_at: 2.days.ago
      )
      emit_event("payment.authorized", @succeeded_partial, created_at: 2.days.ago)
      emit_event("payment.captured",   @succeeded_partial, created_at: 2.days.ago + 2.seconds)
      emit_event("payment.refunded",   @succeeded_partial, created_at: 1.day.ago)

      partial_refund = @succeeded_partial.refunds.create!(
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

      # Pending konbini payment — customer hasn't paid at the store yet
      @merchant.transactions.create!(
        amount: 4500, currency: "JPY", status: :pending, payment_method: :konbini,
        idempotency_key: SecureRandom.uuid,
        customer: @alice, customer_name: @alice.name, customer_email: @alice.email,
        metadata: { order_id: "order_007" },
        created_at: 2.hours.ago
      )

      # Succeeded bank transfer — network confirmed the funds arrived
      bank_transfer = @merchant.transactions.create!(
        amount: 32000, currency: "JPY", status: :succeeded, captured_amount: 32000,
        payment_method: :bank_transfer,
        idempotency_key: SecureRandom.uuid,
        customer: @bob, customer_name: @bob.name, customer_email: @bob.email,
        metadata: { order_id: "order_008" },
        created_at: 2.days.ago
      )
      emit_event("payment.confirmed", bank_transfer, created_at: 1.day.ago)
      emit_event("payment.succeeded", bank_transfer, created_at: 1.day.ago + 2.seconds)
    end

    def seed_disputes
      # Won dispute — fraudulent chargeback, merchant provided evidence, bank sided with merchant
      won_dispute = @succeeded_with_refund.disputes.create!(
        provider_reference: "CASE-#{SecureRandom.hex(6).upcase}",
        merchant:   @merchant,
        reason:     "fraudulent",
        amount:     15000,
        currency:   "JPY",
        status:     :won,
        respond_by: 5.days.ago + 7.days,
        resolved_at: 2.days.ago,
        created_at: 5.days.ago
      )
      emit_event("dispute.opened",    won_dispute, created_at: 5.days.ago)
      emit_event("dispute.responded", won_dispute, created_at: 4.days.ago)
      emit_event("dispute.won",       won_dispute, created_at: 2.days.ago)

      # Merchant responded — unrecognized charge, evidence submitted, awaiting bank decision
      responded_dispute = @succeeded_partial.disputes.create!(
        provider_reference: "CASE-#{SecureRandom.hex(6).upcase}",
        merchant:   @merchant,
        reason:     "unrecognized",
        amount:     8999,
        currency:   "JPY",
        status:     :merchant_responded,
        respond_by: 3.days.from_now,
        created_at: 3.days.ago
      )
      responded_dispute.dispute_responses.create!(
        evidence: { customer_email: "bob@example.com", order_confirmation: "order_002" },
        created_at: 2.days.ago
      )
      emit_event("dispute.opened",    responded_dispute, created_at: 3.days.ago)
      emit_event("dispute.responded", responded_dispute, created_at: 2.days.ago)

      # Open dispute — product not received, merchant needs to respond (6 days left)
      open_payment = @merchant.transactions.create!(
        amount: 12000, currency: "JPY", status: :succeeded, captured_amount: 12000,
        idempotency_key: SecureRandom.uuid,
        customer: @alice, customer_name: @alice.name, customer_email: @alice.email,
        metadata: { order_id: "order_005" },
        created_at: 2.days.ago
      )
      emit_event("payment.authorized", open_payment, created_at: 2.days.ago)
      emit_event("payment.captured",   open_payment, created_at: 2.days.ago + 2.seconds)
      open_dispute = open_payment.disputes.create!(
        provider_reference: "CASE-#{SecureRandom.hex(6).upcase}",
        merchant:   @merchant,
        reason:     "product_not_received",
        amount:     12000,
        currency:   "JPY",
        status:     :open,
        respond_by: 6.days.from_now,
        created_at: 1.day.ago
      )
      emit_event("dispute.opened", open_dispute, created_at: 1.day.ago)

      # Lost dispute — duplicate charge claim, merchant lost, funds returned to cardholder
      lost_payment = @merchant.transactions.create!(
        amount: 6500, currency: "JPY", status: :succeeded, captured_amount: 6500,
        idempotency_key: SecureRandom.uuid,
        customer: @bob, customer_name: @bob.name, customer_email: @bob.email,
        metadata: { order_id: "order_006" },
        created_at: 10.days.ago
      )
      emit_event("payment.authorized", lost_payment, created_at: 10.days.ago)
      emit_event("payment.captured",   lost_payment, created_at: 10.days.ago + 2.seconds)
      lost_dispute = lost_payment.disputes.create!(
        provider_reference: "CASE-#{SecureRandom.hex(6).upcase}",
        merchant:   @merchant,
        reason:     "duplicate",
        amount:     6500,
        currency:   "JPY",
        status:     :lost,
        respond_by: 3.days.ago,
        resolved_at: 1.day.ago,
        created_at: 10.days.ago
      )
      emit_event("dispute.opened", lost_dispute, created_at: 10.days.ago)
      emit_event("dispute.lost",   lost_dispute, created_at: 1.day.ago)
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
