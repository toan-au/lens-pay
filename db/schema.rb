# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_16_071533) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email"
    t.bigint "merchant_id", null: false
    t.jsonb "metadata"
    t.string "name"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "email"], name: "index_customers_on_merchant_id_and_email"
    t.index ["merchant_id", "uid"], name: "index_customers_on_merchant_id_and_uid"
    t.index ["merchant_id"], name: "index_customers_on_merchant_id"
    t.index ["uid"], name: "index_customers_on_uid", unique: true
  end

  create_table "dispute_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dispute_id", null: false
    t.jsonb "evidence", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_id", "created_at"], name: "index_dispute_responses_on_dispute_id_and_created_at"
    t.index ["dispute_id"], name: "index_dispute_responses_on_dispute_id"
  end

  create_table "disputes", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.bigint "merchant_id", null: false
    t.string "provider_reference"
    t.string "reason", null: false
    t.datetime "resolved_at"
    t.datetime "respond_by"
    t.integer "status", default: 0, null: false
    t.bigint "transaction_id", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "created_at"], name: "index_disputes_on_merchant_id_and_created_at"
    t.index ["merchant_id"], name: "index_disputes_on_merchant_id"
    t.index ["provider_reference"], name: "index_disputes_on_provider_reference", unique: true
    t.index ["transaction_id"], name: "index_disputes_on_transaction_id"
    t.index ["uid"], name: "index_disputes_on_uid", unique: true
  end

  create_table "merchants", force: :cascade do |t|
    t.string "api_key_digest", null: false
    t.string "country", limit: 2, null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, null: false
    t.datetime "demo_expires_at"
    t.string "email", null: false
    t.boolean "is_demo", default: false, null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "webhook_secret"
    t.string "webhook_url"
    t.index ["demo_expires_at"], name: "index_merchants_on_demo_expires_at"
    t.index ["email"], name: "index_merchants_on_email", unique: true
    t.index ["status"], name: "index_merchants_on_status"
    t.index ["uid"], name: "index_merchants_on_uid", unique: true
  end

  create_table "refunds", force: :cascade do |t|
    t.bigint "amount", null: false
    t.datetime "created_at", null: false
    t.string "idempotency_key", null: false
    t.integer "status", default: 0, null: false
    t.bigint "transaction_id", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["transaction_id", "created_at"], name: "index_refunds_on_transaction_id_and_created_at"
    t.index ["transaction_id", "idempotency_key"], name: "index_refunds_on_transaction_id_and_idempotency_key", unique: true
    t.index ["uid"], name: "index_refunds_on_uid", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "amount", null: false
    t.bigint "captured_amount"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, null: false
    t.string "customer_email"
    t.bigint "customer_id"
    t.string "customer_name"
    t.datetime "expires_at"
    t.string "idempotency_key", null: false
    t.bigint "merchant_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "payment_method", default: 0, null: false
    t.string "provider_reference"
    t.integer "status", default: 0, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_transactions_on_customer_id"
    t.index ["merchant_id", "created_at"], name: "index_transactions_on_merchant_id_and_created_at"
    t.index ["merchant_id", "idempotency_key"], name: "index_transactions_on_merchant_id_and_idempotency_key", unique: true
    t.index ["merchant_id", "payment_method"], name: "index_transactions_on_merchant_id_and_payment_method"
    t.index ["merchant_id", "status"], name: "index_transactions_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_transactions_on_merchant_id"
    t.index ["provider_reference"], name: "index_transactions_on_provider_reference", unique: true
    t.index ["uid"], name: "index_transactions_on_uid", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "external_id"
    t.bigint "merchant_id", null: false
    t.jsonb "payload", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "external_id"], name: "index_webhook_events_on_merchant_id_and_external_id", unique: true
    t.index ["merchant_id"], name: "index_webhook_events_on_merchant_id"
  end

  add_foreign_key "customers", "merchants"
  add_foreign_key "dispute_responses", "disputes"
  add_foreign_key "disputes", "merchants"
  add_foreign_key "disputes", "transactions"
  add_foreign_key "refunds", "transactions"
  add_foreign_key "transactions", "customers"
  add_foreign_key "transactions", "merchants"
  add_foreign_key "webhook_events", "merchants"
end
