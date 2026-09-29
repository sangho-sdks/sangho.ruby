# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe Sangho::Resources::Customers do
  let(:api_key) { 'sk_test_abc123456789' }
  let(:client)  { Sangho.new(api_key) }
  let(:base_url) { 'https://api.sangho.ga/v1' }

  describe '#list' do
    it 'returns paginated customers' do
      stub_request(:get, "#{base_url}/customers/")
        .to_return(
          status: 200,
          body: { count: 1, next: nil, previous: nil, data: [{ id: 'cust_1', email: 'a@b.com' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.customers.list
      expect(result[:count]).to eq(1)
      expect(result[:data].first[:email]).to eq('a@b.com')
    end
  end

  describe '#retrieve' do
    it 'returns a customer' do
      stub_request(:get, "#{base_url}/customers/cust_1/")
        .to_return(status: 200, body: { id: 'cust_1', email: 'a@b.com' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      customer = client.customers.retrieve('cust_1')
      expect(customer[:id]).to eq('cust_1')
    end
  end

  describe '#create' do
    it 'creates a customer' do
      stub_request(:post, "#{base_url}/customers/")
        .to_return(status: 201, body: { id: 'cust_new', email: 'jean@example.com' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      customer = client.customers.create(email: 'jean@example.com', name: 'Jean Ondo')
      expect(customer[:id]).to eq('cust_new')
    end
  end

  describe '#delete' do
    it 'returns nil on 204' do
      stub_request(:delete, "#{base_url}/customers/cust_1/").to_return(status: 204)
      result = client.customers.delete('cust_1')
      expect(result).to be_nil
    end
  end

  context 'with a public key' do
    let(:pub_client) { Sangho.new('pk_test_abc123456789') }

    it 'raises SanghoPublicKeyError on list' do
      expect { pub_client.customers.list }.to raise_error(Sangho::SanghoPublicKeyError)
    end
  end

  describe 'error handling' do
    it 'raises SanghoNotFoundError on 404' do
      stub_request(:get, "#{base_url}/customers/bad/")
        .to_return(status: 404, body: { message: 'Not found' }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.customers.retrieve('bad') }.to raise_error(Sangho::SanghoNotFoundError)
    end

    it 'raises SanghoValidationError on 422 and exposes field_errors' do
      stub_request(:post, "#{base_url}/customers/")
        .to_return(status: 422, body: { message: 'Invalid', detail: { email: ['Enter a valid email.'] } }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.customers.create(email: 'bad', name: 'x') }
        .to raise_error(Sangho::SanghoValidationError) do |e|
          expect(e.field_errors).to have_key(:email)
        end
    end
  end
end
