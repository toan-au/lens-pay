require 'rails_helper'

RSpec.describe AuditLogger do
  describe ".log" do
    it "includes request_id from Current in the log payload" do
      Current.request_id = "test-request-id"

      expect(Rails.logger).to receive(:info) do |json|
        payload = JSON.parse(json)
        expect(payload["request_id"]).to eq("test-request-id")
      end

      described_class.log(event: "payment.created", status: "succeeded")
    end

    it "includes nil request_id when called outside a request" do
      expect(Rails.logger).to receive(:info) do |json|
        payload = JSON.parse(json)
        expect(payload["request_id"]).to be_nil
      end

      described_class.log(event: "payment.created", status: "succeeded")
    end

    it "includes event, status, and timestamp in every log line" do
      expect(Rails.logger).to receive(:info) do |json|
        payload = JSON.parse(json)
        expect(payload["event"]).to eq("payment.created")
        expect(payload["status"]).to eq("succeeded")
        expect(payload["timestamp"]).to be_present
      end

      described_class.log(event: "payment.created", status: "succeeded")
    end

    it "logs errors at error level with error_class and error_message" do
      error = RuntimeError.new("something went wrong")

      expect(Rails.logger).to receive(:error) do |json|
        payload = JSON.parse(json)
        expect(payload["status"]).to eq("failed")
        expect(payload["error_class"]).to eq("RuntimeError")
        expect(payload["error_message"]).to eq("something went wrong")
      end

      described_class.log(event: "payment.created", status: "failed", error: error)
    end
  end
end
