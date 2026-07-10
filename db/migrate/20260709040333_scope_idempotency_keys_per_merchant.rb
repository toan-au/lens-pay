class ScopeIdempotencyKeysPerMerchant < ActiveRecord::Migration[8.1]
  # Merchants choose their own idempotency keys, so uniqueness must be scoped
  # per merchant (per payment for refunds) — a global unique index lets one
  # merchant's key block another's and leaks key existence across accounts.
  def change
    remove_index :transactions, :idempotency_key, unique: true
    add_index :transactions, [ :merchant_id, :idempotency_key ], unique: true

    remove_index :refunds, :idempotency_key, unique: true
    add_index :refunds, [ :transaction_id, :idempotency_key ], unique: true
  end
end
