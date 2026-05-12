class RenameWebhookCapturesToWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    rename_table :webhook_captures, :webhook_events
  end
end
