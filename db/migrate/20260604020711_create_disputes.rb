class CreateDisputes < ActiveRecord::Migration[8.1]
  def change
    create_table :disputes do |t|
      t.timestamps
      t.string :uid, null: false
      t.references :transaction, null: false, foreign_key: true
      t.references :merchant, null: false, foreign_key: true
      t.string :reason, null: false
      t.integer :status, null: false, default: 0
      t.integer :amount, null: false
      t.string :currency, null: false
      t.datetime :respond_by
      t.datetime :resolved_at
    end

    add_index :disputes, :uid, unique: true
    add_index :disputes, [ :merchant_id, :created_at ]
  end
end
