class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :uid, null: false
      t.bigint :amount, null: false
      t.string :currency, null: false, limit: 3 # Standard ISO length
      t.integer :status, null: false, default: 0
      t.string :idempotency_key, null: false
      t.string :provider_reference
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :transactions, :uid, unique: true
    add_index :transactions, :idempotency_key, unique: true
  end
end
