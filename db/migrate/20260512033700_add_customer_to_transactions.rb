class AddCustomerToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :customer, null: true, foreign_key: true
  end
end
