class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants do |t|
      t.string :uid, null: false
      t.string :name, null: false
      t.string :api_key_digest, null: false

      t.timestamps
    end
    add_index :merchants, :uid, unique: true
  end
end
