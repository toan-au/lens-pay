class CreateRefunds < ActiveRecord::Migration[8.1]
  def change
    create_table :refunds do |t|
      t.bigint :transaction_id, null: false
      t.bigint :amount, null: false
      t.integer :status, default: 0, null: false
      t.string :uid, null: false

      t.timestamps
    end

    add_foreign_key :refunds, :transactions
    add_index :refunds, :uid, unique: true
  end
end
