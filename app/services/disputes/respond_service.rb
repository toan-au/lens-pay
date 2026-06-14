module Disputes
  class RespondService < ApplicationService
    Result = Data.define(:dispute_response, :status)

    def initialize(dispute, evidence)
      @dispute  = dispute
      @evidence = evidence
    end

    def perform
      validate!

      @dispute_response = @dispute.dispute_responses.create!(evidence: @evidence)
      @dispute.respond! if @dispute.open?

      WebhookDeliveryJob.perform_later(@dispute.merchant_id, "dispute.responded", "Dispute", @dispute.id)

      Result.new(dispute_response: @dispute_response, status: :ok)
    end

    def event_name
      "dispute.responded"
    end

    def log_context
      { merchant_uid: @dispute.merchant.uid, dispute_uid: @dispute.uid }
    end

    private

    def validate!
      raise DisputeError::ValidationFailed, [ "Evidence must be a Hash" ] unless @evidence.is_a?(Hash)
      raise DisputeError::ValidationFailed, [ "Evidence cannot be empty" ] if @evidence.empty?
      raise DisputeError::InvalidTransition.new(from: @dispute.status, to: "merchant_responded") if @dispute.won? || @dispute.lost?
      raise DisputeError::RespondByPassed if Time.current >= @dispute.respond_by
    end
  end
end
