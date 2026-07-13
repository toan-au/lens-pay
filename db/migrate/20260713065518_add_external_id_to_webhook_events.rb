class AddExternalIdToWebhookEvents < ActiveRecord::Migration[8.1]
  # The sender's delivery id (X-LensPay-Id). Unique per merchant so retried
  # deliveries dedup instead of storing the same event twice; null allowed for
  # events that arrive without one.
  def change
    add_column :webhook_events, :external_id, :string
    add_index :webhook_events, [ :merchant_id, :external_id ], unique: true
  end
end
