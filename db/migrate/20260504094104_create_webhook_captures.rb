class CreateWebhookCaptures < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_captures do |t|
      t.references :merchant, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false
      t.timestamps
    end
  end
end
