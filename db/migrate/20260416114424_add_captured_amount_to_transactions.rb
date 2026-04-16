class AddCapturedAmountToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :captured_amount, :bigint

    add_index :transactions, [ :merchant_id, :status ]
    add_index :transactions, [ :merchant_id, :created_at ]
  end
end
