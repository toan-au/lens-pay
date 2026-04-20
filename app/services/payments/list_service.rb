module Payments
  class ListService
    Result = Data.define(:transactions, :next_cursor, :status)

    def self.call(current_merchant, cursor: nil, status: nil, limit: nil)
      new(current_merchant, cursor:, status:, limit:).call
    end

    def initialize(current_merchant, cursor:, status:, limit:)
      default_limit = 25

      @current_merchant = current_merchant
      @cursor = cursor
      @status = status
      @limit = limit&.nonzero? || default_limit
    end

    def call
      transactions = @current_merchant.transactions

      transactions = transactions.where(status: @status) if @status.present?

      if @cursor.present?
        cursor_record = @current_merchant.transactions.find_by!(uid: @cursor)
        # Paginate results before the given cursor (created_at, id) for keyset pagination
        transactions = transactions.where("(created_at, id) < (?, ?)", cursor_record.created_at, cursor_record.id)
      end

      transactions = transactions.order(created_at: :desc, id: :desc)
      transactions = transactions.limit(@limit + 1)

      next_cursor = nil
      if transactions.length > @limit
        transactions = transactions.first(@limit)
        last = transactions.last
        next_cursor = last.uid
      end

      Result.new(transactions:, next_cursor:, status: :ok)
    end
  end
end
