module Refunds
  class ListByPaymentService < ApplicationService
  Result = Data.define(:refunds, :status)

  def initialize(transaction)
    @transaction = transaction
  end

  def perform
    @refunds = @transaction.refunds
    Result.new(refunds: @refunds, status: :ok)
  end

  def event_name
    "refund.listed"
  end

  def log_context
    {
      transaction_uid: @transaction&.uid,
      refunds: @refunds
    }
  end
  end
end
