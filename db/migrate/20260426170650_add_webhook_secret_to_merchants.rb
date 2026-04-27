class AddWebhookSecretToMerchants < ActiveRecord::Migration[8.1]
  def change
    add_column :merchants, :webhook_secret, :string
  end
end
