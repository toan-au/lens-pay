class AddCustomerSnapshotToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :customer_name, :string
    add_column :transactions, :customer_email, :string
  end
end
