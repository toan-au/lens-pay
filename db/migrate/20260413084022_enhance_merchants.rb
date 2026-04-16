class EnhanceMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :email, :string, null: false
    add_column :merchants, :country, :string, null: false, limit: 2 # ISO 3166-1 alpha-2
    add_column :merchants, :currency, :string, null: false, limit: 3 # ISO 4217
    add_column :merchants, :webhook_url, :string
    add_column :merchants, :status, :integer, null: false, default: 0

    add_index :merchants, :email, unique: true
    add_index :merchants, :status
  end
end
