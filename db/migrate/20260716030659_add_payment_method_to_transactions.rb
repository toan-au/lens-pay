class AddPaymentMethodToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :payment_method, :integer, default: 0, null: false
    add_index :transactions, [ :merchant_id, :payment_method ]
  end
end
