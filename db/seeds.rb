# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating seed merchant..."

merchant = Merchant.find_or_create_by!(email: "seed@lenspay.dev") do |m|
  m.name = "Seed Merchant"
  m.country = "JP"
  m.currency = "JPY"
end

if merchant.previously_new_record?
  puts "Merchant created!"
  puts "  UID:     #{merchant.uid}"
  puts "  API Key: #{merchant.raw_api_key}"
  puts "  (API key is only shown once — save it now)"
else
  puts "Merchant already exists (uid: #{merchant.uid})"
  puts "  (API key cannot be retrieved — delete and re-seed if you need a new one)"
end

puts "\nCreating seed transactions..."

transactions = [
  { amount: 1000, currency: "JPY", idempotency_key: "seed_pending_1", status: :pending },
  { amount: 2500, currency: "JPY", idempotency_key: "seed_authorized_1", status: :authorized },
  { amount: 5000, currency: "JPY", idempotency_key: "seed_processing_1", status: :processing, captured_amount: 5000 },
  { amount: 3000, currency: "JPY", idempotency_key: "seed_succeeded_1", status: :succeeded, captured_amount: 3000 },
  { amount: 3000, currency: "JPY", idempotency_key: "seed_succeeded_2", status: :succeeded, captured_amount: 2000 },
  { amount: 1500, currency: "JPY", idempotency_key: "seed_declined_1", status: :declined },
]

transactions.each do |attrs|
  t = Transaction.find_or_create_by!(idempotency_key: attrs[:idempotency_key]) do |tx|
    tx.amount = attrs[:amount]
    tx.currency = attrs[:currency]
    tx.status = attrs[:status]
    tx.captured_amount = attrs[:captured_amount]
    tx.merchant = merchant
  end
  puts "  #{t.status.ljust(12)} uid: #{t.uid}  amount: #{t.amount}  captured: #{t.captured_amount || "-"}"
end

puts "\nDone!"
