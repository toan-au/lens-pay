class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :uid
      t.string :name
      t.string :email
      t.jsonb :metadata
      t.datetime :deleted_at
      t.references :merchant, null: false, foreign_key: true

      t.timestamps
    end

    add_index :customers, :uid, unique: true
    add_index :customers, [ :merchant_id, :uid ]
    add_index :customers, [ :merchant_id, :email ]
  end
end
