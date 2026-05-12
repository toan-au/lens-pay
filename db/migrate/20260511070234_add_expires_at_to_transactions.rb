class AddExpiresAtToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :expires_at, :datetime
  end
end
