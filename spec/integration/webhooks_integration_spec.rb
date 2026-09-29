# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"
require "openssl"
require "json"

RSpec.describe "Webhooks Integration", :integration do

  let!(:shared_webhook) do
    client.webhooks.create(
      url: "https://webhook.site/#{SecureRandom.hex(8)}",
      events: ["payment_intent.succeeded", "customer.created"]
    )
  end

  after(:all) do
    begin; client.webhooks.delete(shared_webhook[:id]); rescue StandardError; nil; end
  end

  describe "#create" do
    it "creates a webhook endpoint" do
      wh = client.webhooks.create(
        url: "https://webhook.site/#{SecureRandom.hex(8)}",
        events: ["payment_intent.succeeded"]
      )

      expect(wh[:id]).not_to be_empty
      client.webhooks.delete(wh[:id])
    end
  end

  describe "#retrieve" do
    it "retrieves a webhook by id" do
      retrieved = client.webhooks.retrieve(shared_webhook[:id])
      expect(retrieved[:id]).to eq(shared_webhook[:id])
    end
  end

  describe "#list" do
    it "returns paginated data" do
      result = client.webhooks.list
      expect(result).to have_key(:data)
    end
  end

  describe "#roll_secret" do
    it "rolls the signing secret" do
      result = client.webhooks.roll_secret(shared_webhook[:id])
      expect(result[:id]).to eq(shared_webhook[:id])
    end
  end

  describe "#list_deliveries" do
    it "returns delivery history" do
      result = client.webhooks.list_deliveries(shared_webhook[:id])
      expect(result).to have_key(:data)
    end
  end

  describe "error handling" do
    it "raises SanghoNotFoundError on nonexistent webhook" do
      expect {
        client.webhooks.retrieve("wh_doesnotexist000")
      }.to raise_error(Sangho::SanghoNotFoundError)
    end
  end

  # ── Signature verification (offline) ─────────────────────────────────────

  describe ".construct_event" do
    let(:secret) { "whsec_test_integration_ruby" }

    it "verifies a valid signature and returns the event" do
      payload = JSON.dump(event: "payment_intent.succeeded")
      ts      = Time.now.to_i
      sig     = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{ts}.#{payload}")
      header  = "t=#{ts},v1=#{sig}"

      event = Sangho::Resources::Webhooks.construct_event(payload, header, secret)
      expect(event[:event]).to eq("payment_intent.succeeded")
    end

    it "raises SanghoError on wrong secret" do
      payload = '{"event":"test"}'
      ts      = Time.now.to_i
      sig     = OpenSSL::HMAC.hexdigest("SHA256", "correct_secret", "#{ts}.#{payload}")
      header  = "t=#{ts},v1=#{sig}"

      expect {
        Sangho::Resources::Webhooks.construct_event(payload, header, "wrong_secret")
      }.to raise_error(Sangho::SanghoError, /mismatch/)
    end

    it "raises SanghoError on stale timestamp" do
      old_ts  = Time.now.to_i - 600
      payload = '{"event":"test"}'
      sig     = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{old_ts}.#{payload}")
      header  = "t=#{old_ts},v1=#{sig}"

      expect {
        Sangho::Resources::Webhooks.construct_event(payload, header, secret, tolerance: 300)
      }.to raise_error(Sangho::SanghoError, /old/)
    end
  end
end
