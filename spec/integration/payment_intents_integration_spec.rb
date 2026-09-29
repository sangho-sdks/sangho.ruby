# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"

RSpec.describe "PaymentIntents Integration", :integration do

  let!(:shared_customer) do
    client.customers.create(email: unique_email("pi"), name: "PI Integration Customer")
  end

  after(:all) do
    begin; client.customers.delete(shared_customer[:id]); rescue StandardError; nil; end
  end

  describe "#create" do
    it "creates a payment intent with correct fields" do
      intent = client.payment_intents.create(
        amount: 10_000,
        customer: shared_customer[:id],
        description: "Integration test"
      )

      expect(intent[:id]).not_to be_empty
      expect(intent[:amount]).to eq(10_000)
      expect(intent[:customer]).to eq(shared_customer[:id])
      expect(intent).to have_key(:status)

      client.payment_intents.cancel(intent[:id])
    end
  end

  describe "#retrieve" do
    it "retrieves an existing payment intent" do
      intent    = client.payment_intents.create(amount: 5_000, customer: shared_customer[:id])
      retrieved = client.payment_intents.retrieve(intent[:id])

      expect(retrieved[:id]).to eq(intent[:id])
      expect(retrieved[:amount]).to eq(5_000)

      client.payment_intents.cancel(intent[:id])
    end
  end

  describe "#list" do
    it "returns a paginated list" do
      result = client.payment_intents.list(page_size: 5)

      expect(result).to have_key(:count)
      expect(result[:data]).to be_an(Array)
    end
  end

  describe "#cancel" do
    it "cancels a payment intent" do
      intent   = client.payment_intents.create(amount: 2_500, customer: shared_customer[:id])
      canceled = client.payment_intents.cancel(intent[:id])

      expect(canceled[:status]).to eq("canceled")
      expect(canceled[:id]).to eq(intent[:id])
    end
  end

  describe "error handling" do
    it "raises SanghoNotFoundError on nonexistent intent" do
      expect {
        client.payment_intents.retrieve("pay_doesnotexist000")
      }.to raise_error(Sangho::SanghoNotFoundError)
    end
  end
end
