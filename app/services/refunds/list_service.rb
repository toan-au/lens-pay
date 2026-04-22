module Refunds
  class ListService < ApplicationService
  Result = Data.define(:refunds, :next_cursor, :status)

  def initialize(merchant, cursor: nil, status: nil, limit: nil)
    default_limit = 25

    @merchant = merchant
    @cursor = cursor
    @status = status
    @limit = limit&.nonzero? || default_limit
  end

  def perform
    @refunds = Refund.joins(:payment).where(transactions: { merchant_id: @merchant.id })

    @refunds = @refunds.where(status: @status) if @status.present?

    if @cursor.present?
      cursor_record = @refunds.find_by!(uid: @cursor)
      # Paginate results before the given cursor (created_at, id) for keyset pagination
      @refunds = @refunds.where("(refunds.created_at, refunds.id) < (?, ?)", cursor_record.created_at, cursor_record.id)
    end

    @refunds = @refunds.order("refunds.created_at": :desc, "refunds.id": :desc)
    @refunds = @refunds.limit(@limit + 1)

    next_cursor = nil
    if @refunds.length > @limit
      @refunds = @refunds.first(@limit)
      last = @refunds.last
      next_cursor = last.uid
    end

    Result.new(refunds: @refunds, next_cursor:, status: :ok)
  end

  def event_name
    "refund.listed"
  end

  def log_context
    {
      merchant_uid: @merchant&.uid,
      refunds_count: @refunds&.count
    }
  end
  end
end
