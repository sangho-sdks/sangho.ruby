# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "integration_helper"

RSpec.describe "Subscriptions Integration", :integration do

  describe "#list" do
    it "returns a paginated list" do
      result = client.subscriptions.list(page_size: 5)
      expect(result).to have_key(:count)
      expect(result[:data]).to be_an(Array)
    end
  end

  describe "error handling" do
    it "raises SanghoNotFoundError on nonexistent subscription" do
      expect { client.subscriptions.retrieve("sub_doesnotexist000") }
        .to raise_error(Sangho::SanghoNotFoundError)
    end
  end
end
