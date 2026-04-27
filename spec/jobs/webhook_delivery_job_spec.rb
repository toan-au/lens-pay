require 'rails_helper'

RSpec.describe WebhookDeliveryJob do
  let(:merchant) { create(:merchant, webhook_url: "https://example.com/webhooks") }
  let(:transaction) { create(:transaction, :succeeded, merchant: merchant) }

  describe "#perform" do
    context "when the merchant has a webhook_url" do
      before { stub_request(:post, merchant.webhook_url).to_return(status: 200) }

      it "posts to the merchant's webhook_url" do
        described_class.perform_now(merchant.id, "payment.succeeded", "Transaction", transaction.id)

        expect(a_request(:post, merchant.webhook_url)).to have_been_made.once
      end

      it "sends the correct headers" do
        described_class.perform_now(merchant.id, "payment.succeeded", "Transaction", transaction.id)

        expect(a_request(:post, merchant.webhook_url).with(
          headers: {
            "Content-Type"    => "application/json",
            "User-Agent"      => "LensPay-Webhook",
            "X-Lenspay-Event" => "payment.succeeded"
          }
        )).to have_been_made.once
      end

      it "signs the body with HMAC-SHA256 using the merchant's webhook_secret" do
        described_class.perform_now(merchant.id, "payment.succeeded", "Transaction", transaction.id)

        expect(a_request(:post, merchant.webhook_url).with { |req|
          expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", merchant.webhook_secret, req.body)
          req.headers["X-Lenspay-Signature"] == expected
        }).to have_been_made.once
      end

      it "logs a successful delivery to the audit log" do
        expect(AuditLogger).to receive(:log).with(
          event: "webhook.delivered",
          status: "succeeded",
          merchant_uid: merchant.uid,
          event_type: "payment.succeeded",
          webhook_url: merchant.webhook_url,
          resource_uid: transaction.uid
        )

        described_class.perform_now(merchant.id, "payment.succeeded", "Transaction", transaction.id)
      end
    end

    context "when the merchant has no webhook_url" do
      before { merchant.update!(webhook_url: nil) }

      it "makes no HTTP request" do
        described_class.perform_now(merchant.id, "payment.succeeded", "Transaction", transaction.id)

        expect(a_request(:any, //)).not_to have_been_made
      end
    end

    context "when the endpoint returns a non-2xx response" do
      before { stub_request(:post, merchant.webhook_url).to_return(status: 500) }

      it "raises WebhookError::DeliveryFailed" do
        job = described_class.new
        expect { job.perform(merchant.id, "payment.succeeded", "Transaction", transaction.id) }
          .to raise_error(WebhookError::DeliveryFailed, /HTTP 500/)
      end

      it "re-enqueues the job for retry" do
        expect {
          described_class.perform_now(merchant.id, "payment.succeeded", "Transaction", transaction.id)
        }.to have_enqueued_job(described_class)
      end
    end

    context "when the request times out" do
      before { stub_request(:post, merchant.webhook_url).to_timeout }

      it "raises WebhookError::DeliveryFailed" do
        job = described_class.new
        expect { job.perform(merchant.id, "payment.succeeded", "Transaction", transaction.id) }
          .to raise_error(WebhookError::DeliveryFailed)
      end

      it "re-enqueues the job for retry" do
        expect {
          described_class.perform_now(merchant.id, "payment.succeeded", "Transaction", transaction.id)
        }.to have_enqueued_job(described_class)
      end
    end

    context "when all retries are exhausted" do
      let(:exhausted_job) do
        job = described_class.new(merchant.id, "payment.succeeded", "Transaction", transaction.id)
        job.exception_executions = { "[WebhookError::DeliveryFailed]" => 2 }
        job
      end

      before { stub_request(:post, merchant.webhook_url).to_return(status: 500) }

      it "logs the permanent failure to the audit log" do
        expect(AuditLogger).to receive(:log).with(
          hash_including(
            event: "webhook.delivered",
            status: "failed",
            merchant_uid: merchant.uid,
            event_type: "payment.succeeded",
            webhook_url: merchant.webhook_url,
            resource_uid: transaction.uid
          )
        )

        exhausted_job.perform_now
      end

      it "does not re-enqueue the job" do
        allow(AuditLogger).to receive(:log)

        expect { exhausted_job.perform_now }.not_to have_enqueued_job(described_class)
      end
    end
  end
end
