module Narratives
  # Turns a Transaction into a plain hash of facts for the narrator to work
  # from. Pure: no network, no writes, no logging. Timestamps are ISO8601
  # strings; everything time-ordered is oldest-first.
  class PaymentContext
    def self.call(payment) = new(payment).call

    def initialize(payment)
      @payment = payment
    end

    def call
      {
        payment: payment_facts,
        customer: customer_facts,
        refunds: refund_facts,
        dispute: dispute_facts,
        timeline: timeline,
        metadata: @payment.metadata
      }
    end

    private

    def payment_facts
      {
        amount: @payment.amount,
        captured_amount: @payment.captured_amount,
        currency: @payment.currency,
        payment_method: @payment.payment_method,
        status: @payment.status,
        created_at: @payment.created_at.iso8601,
        expires_at: @payment.expires_at&.iso8601,
        provider_reference: @payment.provider_reference
      }
    end

    def customer_facts
      customer = @payment.customer
      return nil unless customer

      {
        name: customer.name,
        email: customer.email,
        returning: customer.payments.where.not(id: @payment.id).exists?
      }
    end

    def refund_facts
      @payment.refunds.order(:created_at).map do |refund|
        {
          amount: refund.amount,
          status: refund.status,
          created_at: refund.created_at.iso8601
        }
      end
    end

    def dispute_facts
      dispute = @payment.disputes.order(:created_at).first
      return nil unless dispute

      {
        reason: dispute.reason,
        amount: dispute.amount,
        currency: dispute.currency,
        status: dispute.status,
        respond_by: dispute.respond_by&.iso8601,
        resolved_at: dispute.resolved_at&.iso8601,
        responses: dispute.dispute_responses.order(:created_at).map do |response|
          { evidence: response.evidence, created_at: response.created_at.iso8601 }
        end
      }
    end

    def timeline
      @payment.merchant.webhook_events
        .where("payload->'data'->>'id' = ? OR payload->'data'->>'transaction_uid' = ?", @payment.uid, @payment.uid)
        .order(:created_at)
        .map { |event| { event: event.event_type, at: event.created_at.iso8601 } }
    end
  end
end
