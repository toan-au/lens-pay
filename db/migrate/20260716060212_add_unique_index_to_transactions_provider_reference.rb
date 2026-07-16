class AddUniqueIndexToTransactionsProviderReference < ActiveRecord::Migration[8.1]
  def change
    add_index :transactions, :provider_reference, unique: true
  end
end
