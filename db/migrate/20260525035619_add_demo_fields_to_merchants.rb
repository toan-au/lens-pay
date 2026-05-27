class AddDemoFieldsToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :is_demo, :boolean, default: false, null: false
    add_column :merchants, :demo_expires_at, :datetime
    add_index :merchants, :demo_expires_at
  end
end
