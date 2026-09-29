# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"

RSpec.describe "Transactions Integration", :integration do

  describe "#list" do
    it "returns a paginated list" do
      result = client.transactions.list(page_size: 5)
      expect(result).to have_key(:count)
      expect(result[:data]).to be_an(Array)
      expect(result[:data].length).to be <= 5
    end

    it "supports ordering by created_at desc" do
      result = client.transactions.list(ordering: "-created_at", page_size: 10)
      expect(result).to have_key(:data)
    end
  end

  describe "error handling" do
    it "raises SanghoNotFoundError on nonexistent transaction" do
      expect { client.transactions.retrieve("trans_doesnotexist000") }
        .to raise_error(Sangho::SanghoNotFoundError)
    end
  end
end
