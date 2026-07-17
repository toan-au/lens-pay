class AddProviderReferenceToDisputes < ActiveRecord::Migration[8.1]
  def change
    add_column :disputes, :provider_reference, :string
    add_index :disputes, :provider_reference, unique: true
  end
end
