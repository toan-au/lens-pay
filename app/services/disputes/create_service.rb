module Disputes
  class CreateService < ApplicationService
    Result = Data.define(:dispute, :status)

    def initialize(transaction, params)
      @transaction = transaction
      @params      = params
    end

    def perform
      # Networks retry their webhooks; the same case must not open twice.
      existing = Dispute.find_by(provider_reference: @params[:case_reference])
      return Result.new(dispute: existing, status: :ok) if existing

      validate!

      @dispute = @transaction.disputes.new(
        merchant:   @transaction.merchant,
        reason:     @params[:reason],
        amount:     @params[:amount],
        currency:   @params[:currency],
        provider_reference: @params[:case_reference],
        respond_by: 7.days.from_now
      )

      raise DisputeError::ValidationFailed, @dispute.errors.full_messages unless @dispute.save

      WebhookDeliveryJob.perform_later(@transaction.merchant_id, "dispute.opened", "Dispute", @dispute.id, request_id: Current.request_id)

      Result.new(dispute: @dispute, status: :created)
    end

    def event_name
      "dispute.opened"
    end

    def log_context
      { merchant_uid: @transaction.merchant.uid, transaction_uid: @transaction.uid }
    end

    private

    def validate!
      raise DisputeError::InvalidPayment unless @transaction.succeeded?
      raise DisputeError::ValidationFailed, [ "Amount must be greater than 0" ] if @params[:amount].to_i <= 0
      raise DisputeError::ValidationFailed, [ "Amount exceeds transaction amount" ] if @params[:amount].to_i > @transaction.amount
      raise DisputeError::MismatchedCurrency if @params[:currency] != @transaction.currency
      raise DisputeError::InvalidReason unless Dispute::REASONS.include?(@params[:reason])
      raise DisputeError::AlreadyDisputed if @transaction.disputes.where(status: %i[open merchant_responded]).exists?
    end
  end
end
