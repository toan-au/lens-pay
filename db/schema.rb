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

ActiveRecord::Schema[8.1].define(version: 2026_04_24_193600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "merchants", force: :cascade do |t|
    t.string "api_key_digest", null: false
    t.string "country", limit: 2, null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, null: false
    t.string "email", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.string "webhook_url"
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
    t.index ["idempotency_key"], name: "index_refunds_on_idempotency_key", unique: true
    t.index ["uid"], name: "index_refunds_on_uid", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "amount", null: false
    t.bigint "captured_amount"
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, null: false
    t.string "idempotency_key", null: false
    t.bigint "merchant_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "provider_reference"
    t.integer "status", default: 0, null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_transactions_on_idempotency_key", unique: true
    t.index ["merchant_id", "created_at"], name: "index_transactions_on_merchant_id_and_created_at"
    t.index ["merchant_id", "status"], name: "index_transactions_on_merchant_id_and_status"
    t.index ["merchant_id"], name: "index_transactions_on_merchant_id"
    t.index ["uid"], name: "index_transactions_on_uid", unique: true
  end

  add_foreign_key "refunds", "transactions"
  add_foreign_key "transactions", "merchants"
end
