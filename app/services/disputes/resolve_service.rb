module Disputes
  class ResolveService < ApplicationService
    VALID_OUTCOMES = %w[won lost].freeze

    Result = Data.define(:dispute, :status)

    def initialize(dispute, outcome)
      @dispute = dispute
      @outcome = outcome
    end

    def perform
      validate!

      @dispute.with_lock do
        @outcome == "won" ? @dispute.win! : @dispute.lose!
        @dispute.update!(resolved_at: Time.current)
      end

      WebhookDeliveryJob.perform_later(@dispute.merchant_id, "dispute.#{@outcome}", "Dispute", @dispute.id, request_id: Current.request_id)

      Result.new(dispute: @dispute, status: :ok)
    end

    def event_name = "dispute.#{@outcome}"
    def log_context = { merchant_uid: @dispute.merchant.uid, dispute_uid: @dispute.uid }

    private

    def validate!
      raise DisputeError::ValidationFailed, [ "Outcome must be 'won' or 'lost'" ] unless VALID_OUTCOMES.include?(@outcome)
      raise DisputeError::AlreadyResolved if @dispute.won? || @dispute.lost?
    end
  end
end
