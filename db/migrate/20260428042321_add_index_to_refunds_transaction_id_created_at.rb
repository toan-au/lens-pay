class AddIndexToRefundsTransactionIdCreatedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :refunds, [ :transaction_id, :created_at ]
  end
end
