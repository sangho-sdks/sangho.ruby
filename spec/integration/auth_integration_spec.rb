# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"

RSpec.describe "Authentication Integration", :integration do

  describe "valid secret key" do
    it "authenticates and returns data" do
      result = client.customers.list(page_size: 1)
      expect(result).to have_key(:data)
    end
  end

  describe "invalid key" do
    it "raises SanghoAuthError on 401" do
      bad_client = Sangho.new(
        "sk_test_invalidkeyXXXXXXXXXXXX",
        base_url: IntegrationHelper.base_url
      )
      expect {
        bad_client.customers.list
      }.to raise_error(Sangho::SanghoAuthError) do |e|
        expect(e.status_code).to eq(401)
      end
    end
  end

  describe "public key restrictions" do
    it "raises SanghoPublicKeyError on write operations" do
      expect { pub_client.customers.list }.to raise_error(Sangho::SanghoPublicKeyError)
      expect { pub_client.products.list  }.to raise_error(Sangho::SanghoPublicKeyError)
    end
  end

  describe "key format validation" do
    it "raises ArgumentError on invalid prefix (no network call)" do
      expect {
        Sangho.new("bad_key_no_prefix")
      }.to raise_error(ArgumentError, /Invalid API key/)
    end

    it "accepts all 4 valid prefixes without error" do
      %w[sk_prod_ sk_test_ pk_prod_ pk_test_].each do |prefix|
        expect {
          Sangho.new(prefix + "x" * 20, base_url: IntegrationHelper.base_url)
        }.not_to raise_error
      end
    end
  end
end
