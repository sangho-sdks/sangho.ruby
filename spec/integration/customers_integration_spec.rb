# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"
require "securerandom"

RSpec.describe "Customers Integration", :integration do

  # Fixture partagée : client créé une fois pour tout le groupe
  let!(:shared_customer) do
    client.customers.create(
      email: unique_email("shared"),
      name: "Shared Integration Customer"
    )
  end

  after(:all) do
    begin
      client.customers.delete(shared_customer[:id])
    rescue StandardError
      nil
    end
  end

  # ── CRUD ────────────────────────────────────────────────────────────────────

  describe "#create" do
    it "creates a customer and returns expected fields" do
      email    = unique_email("create")
      customer = client.customers.create(email: email, name: "Jean Ondo", phone: "+24177000001")

      expect(customer[:id]).not_to be_empty
      expect(customer[:email]).to eq(email)
      expect(customer[:name]).to eq("Jean Ondo")
      expect(customer).to have_key(:created_at)
      expect(customer).to have_key(:status)

      client.customers.delete(customer[:id])
    end
  end

  describe "#retrieve" do
    it "retrieves a customer by id" do
      retrieved = client.customers.retrieve(shared_customer[:id])

      expect(retrieved[:id]).to eq(shared_customer[:id])
      expect(retrieved[:email]).to eq(shared_customer[:email])
    end
  end

  describe "#list" do
    it "returns a paginated response" do
      result = client.customers.list(page_size: 5)

      expect(result).to have_key(:count)
      expect(result).to have_key(:data)
      expect(result).to have_key(:next)
      expect(result[:data]).to be_an(Array)
      expect(result[:data].length).to be <= 5
    end

    it "filters by status active" do
      result = client.customers.list(status: "active", page_size: 10)

      result[:data].each do |c|
        expect(c[:status]).to eq("active")
      end
    end

    it "finds customer by email search" do
      result = client.customers.list(search: shared_customer[:email])
      ids    = result[:data].map { |c| c[:id] }

      expect(ids).to include(shared_customer[:id])
    end
  end

  describe "#update" do
    it "updates the customer phone number" do
      updated = client.customers.update(shared_customer[:id], phone: "+24177999999")

      expect(updated[:id]).to eq(shared_customer[:id])
      expect(updated[:phone]).to eq("+24177999999")
    end
  end

  describe "#delete" do
    it "deletes a customer and returns nil (HTTP 204)" do
      customer = client.customers.create(email: unique_email("del"), name: "À supprimer")
      result   = client.customers.delete(customer[:id])

      expect(result).to be_nil

      expect {
        client.customers.retrieve(customer[:id])
      }.to raise_error(Sangho::SanghoNotFoundError)
    end
  end

  # ── Erreurs ──────────────────────────────────────────────────────────────────

  describe "error handling" do
    it "raises SanghoNotFoundError on nonexistent customer" do
      expect {
        client.customers.retrieve("cust_doesnotexist000")
      }.to raise_error(Sangho::SanghoNotFoundError) do |e|
        expect(e.status_code).to eq(404)
      end
    end

    it "raises SanghoValidationError on duplicate email" do
      expect {
        client.customers.create(email: shared_customer[:email], name: "Duplicate")
      }.to raise_error(Sangho::SanghoValidationError) do |e|
        expect(e.status_code).to eq(422)
      end
    end

    it "raises SanghoValidationError with field_errors on invalid email" do
      expect {
        client.customers.create(email: "not-an-email", name: "Bad")
      }.to raise_error(Sangho::SanghoValidationError) do |e|
        expect(e.field_errors).to have_key(:email)
      end
    end

    it "raises SanghoPublicKeyError when listing with a public key" do
      expect {
        pub_client.customers.list
      }.to raise_error(Sangho::SanghoPublicKeyError)
    end
  end

  describe "#options" do
    it "returns DRF schema metadata" do
      schema = client.customers.options
      expect(schema).to be_a(Hash)
    end
  end
end
