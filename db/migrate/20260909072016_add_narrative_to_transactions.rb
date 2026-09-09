class AddNarrativeToTransactions < ActiveRecord::Migration[8.1]
  # Cached AI narrative for the payment detail view. `narrative` holds the
  # structured JSON ({ headline, timeline }); `narrative_generated_at` doubles
  # as the "is it cached" flag — state-changing actions null it to force a
  # regenerate. `narrative_model` records which model produced it. All null
  # until first generated; the feature is off by default.
  def change
    add_column :transactions, :narrative, :jsonb
    add_column :transactions, :narrative_generated_at, :datetime
    add_column :transactions, :narrative_model, :string
  end
end
