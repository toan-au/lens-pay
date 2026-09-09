require "rails_helper"

RSpec.describe Narratives::PaymentContext do
  describe ".call" do
    it "returns the core payment facts" do
      payment = create(:transaction, :succeeded, :konbini, amount: 1000, currency: "JPY", captured_amount: 1000)

      context = described_class.call(payment)

      expect(context[:payment]).to include(
        amount: 1000,
        captured_amount: 1000,
        currency: "JPY",
        payment_method: "konbini",
        status: "succeeded",
        provider_reference: payment.provider_reference
      )
    end

    it "formats timestamps as ISO8601 strings" do
      payment = create(:transaction)

      context = described_class.call(payment)

      expect(context[:payment][:created_at]).to eq(payment.created_at.iso8601)
      expect(context[:payment][:expires_at]).to eq(payment.expires_at.iso8601)
    end

    it "lists refunds oldest first" do
      payment = create(:transaction, :succeeded, captured_amount: 1000)
      older = create(:refund, :succeeded, payment: payment, amount: 200, created_at: 2.days.ago)
      newer = create(:refund, :succeeded, payment: payment, amount: 300, created_at: 1.day.ago)

      context = described_class.call(payment)

      expect(context[:refunds]).to eq([
        { amount: 200, status: "succeeded", created_at: older.created_at.iso8601 },
        { amount: 300, status: "succeeded", created_at: newer.created_at.iso8601 }
      ])
    end

    it "returns nil for customer and dispute when there are none" do
      context = described_class.call(create(:transaction))

      expect(context[:customer]).to be_nil
      expect(context[:dispute]).to be_nil
    end

    it "includes the customer with a returning flag when they have prior payments" do
      customer = create(:customer)
      create(:transaction, merchant: customer.merchant, customer: customer)
      payment = create(:transaction, merchant: customer.merchant, customer: customer)

      context = described_class.call(payment)

      expect(context[:customer]).to eq(
        name: "Jane Doe",
        email: "jane@example.com",
        returning: true
      )
    end

    it "marks a first-time customer as not returning" do
      customer = create(:customer)
      payment = create(:transaction, merchant: customer.merchant, customer: customer)

      context = described_class.call(payment)

      expect(context[:customer][:returning]).to be(false)
    end

    it "includes the dispute with its responses" do
      payment = create(:transaction, :succeeded, captured_amount: 1000)
      dispute = create(:dispute, :won, payment: payment, reason: "fraudulent", amount: 1000, currency: "JPY")
      create(:dispute_response, dispute: dispute, evidence: { "note" => "shipped on time" })

      context = described_class.call(payment)

      expect(context[:dispute]).to include(
        reason: "fraudulent",
        amount: 1000,
        currency: "JPY",
        status: "won"
      )
      expect(context[:dispute][:responses].first).to include(evidence: { "note" => "shipped on time" })
    end

    it "builds the timeline from webhook events, oldest first" do
      payment = create(:transaction)
      merchant = payment.merchant
      create(:webhook_event, merchant: merchant, event_type: "payment.captured",
             payload: { "data" => { "id" => payment.uid } }, created_at: 1.hour.ago)
      create(:webhook_event, merchant: merchant, event_type: "payment.created",
             payload: { "data" => { "id" => payment.uid } }, created_at: 2.hours.ago)

      context = described_class.call(payment)

      expect(context[:timeline].map { |entry| entry[:event] }).to eq([ "payment.created", "payment.captured" ])
    end

    it "matches timeline events keyed by transaction_uid too" do
      payment = create(:transaction)
      create(:webhook_event, merchant: payment.merchant, event_type: "payment.refunded",
             payload: { "data" => { "transaction_uid" => payment.uid } })

      context = described_class.call(payment)

      expect(context[:timeline].map { |entry| entry[:event] }).to eq([ "payment.refunded" ])
    end

    it "does not pull another payment's webhook events into the timeline" do
      payment = create(:transaction)
      other = create(:transaction, merchant: payment.merchant)
      create(:webhook_event, merchant: payment.merchant, event_type: "payment.captured",
             payload: { "data" => { "id" => other.uid } })

      context = described_class.call(payment)

      expect(context[:timeline]).to be_empty
    end

    it "passes metadata through untouched" do
      payment = create(:transaction, metadata: { "order_id" => "order_42" })

      expect(described_class.call(payment)[:metadata]).to eq("order_id" => "order_42")
    end
  end
end
