class CreateDisputeResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :dispute_responses do |t|
      t.references :dispute, null: false, foreign_key: true
      t.jsonb :evidence, null: false, default: {}
      t.timestamps
    end

    add_index :dispute_responses, [:dispute_id, :created_at]
  end
end
