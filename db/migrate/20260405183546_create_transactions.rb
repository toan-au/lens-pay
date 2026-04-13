class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :uid
      t.bigint :amount
      t.string :currency
      t.integer :status
      t.string :idempotency_key
      t.string :provider_reference
      t.jsonb :metadata

      t.timestamps
    end

    add_index :transactions, :idempotency_key, unique: true
    add_index :transactions, :uid, unique: true
  end
end
