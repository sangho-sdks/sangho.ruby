# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"

RSpec.describe "Refunds Integration", :integration do

  describe "#list" do
    it "returns a paginated list" do
      result = client.refunds.list(page_size: 5)
      expect(result).to have_key(:count)
      expect(result[:data]).to be_an(Array)
    end
  end

  describe "error handling" do
    it "raises SanghoNotFoundError on nonexistent refund" do
      expect { client.refunds.retrieve("ref_doesnotexist000") }
        .to raise_error(Sangho::SanghoNotFoundError)
    end
  end
end
