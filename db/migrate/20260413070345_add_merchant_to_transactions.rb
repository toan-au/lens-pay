class AddMerchantToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :merchant, null: false, foreign_key: true
  end
end
