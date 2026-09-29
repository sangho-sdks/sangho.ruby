# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"

RSpec.describe "Invoices Integration", :integration do

  let!(:shared_customer) do
    client.customers.create(email: unique_email("inv"), name: "Invoice Integration Customer")
  end

  after(:all) do
    begin; client.customers.delete(shared_customer[:id]); rescue StandardError; nil; end
  end

  describe "#create" do
    it "creates an invoice" do
      invoice = client.invoices.create(customer: shared_customer[:id], amount: 10_000)

      expect(invoice[:id]).not_to be_empty
      expect(invoice[:amount]).to eq(10_000)
      expect(invoice[:customer]).to eq(shared_customer[:id])

      client.invoices.delete(invoice[:id])
    end
  end

  describe "#retrieve" do
    it "retrieves an invoice by id" do
      invoice   = client.invoices.create(customer: shared_customer[:id], amount: 5_000)
      retrieved = client.invoices.retrieve(invoice[:id])

      expect(retrieved[:id]).to eq(invoice[:id])
      client.invoices.delete(invoice[:id])
    end
  end

  describe "#list" do
    it "returns paginated invoices" do
      result = client.invoices.list(page_size: 5)
      expect(result).to have_key(:count)
      expect(result[:data]).to be_an(Array)
    end
  end

  describe "#void" do
    it "voids an invoice" do
      invoice = client.invoices.create(customer: shared_customer[:id], amount: 3_000)
      voided  = client.invoices.void(invoice[:id])
      expect(voided[:status].to_s).to eq("void")
    end
  end

  describe "#delete" do
    it "deletes a draft invoice" do
      invoice = client.invoices.create(customer: shared_customer[:id], amount: 1_500)
      client.invoices.delete(invoice[:id])

      expect { client.invoices.retrieve(invoice[:id]) }
        .to raise_error(Sangho::SanghoNotFoundError)
    end
  end

  describe "error handling" do
    it "raises SanghoNotFoundError on nonexistent invoice" do
      expect { client.invoices.retrieve("inv_doesnotexist000") }
        .to raise_error(Sangho::SanghoNotFoundError)
    end
  end
end
