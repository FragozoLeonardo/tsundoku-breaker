# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe GoogleBooksService do
  describe ".call" do
    subject(:service_call) { described_class.call(isbn) }

    let(:isbn) { "9780132350884" }
    let(:fake_api_key) { "TEST_API_KEY" }

    before do
      allow(ENV).to receive(:fetch).with("GOOGLE_BOOKS_API_KEY", nil).and_return(fake_api_key)
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    it "measures and returns latency" do
      stub_request(:get, /googleapis/).to_return(status: 200, body: { items: [] }.to_json)
      expect(service_call.latency).to be_a(Numeric)
    end

    context "when API returns success" do
      let(:response_body) do
        {
          items: [{
            volumeInfo: {
              title: "  Clean Code  ",
              authors: ["Robert Martin", "Micah Martin"],
              imageLinks: { thumbnail: "http://cover.jpg" }
            }
          }]
        }.to_json
      end

      it "returns success with latency and sanitized data" do
        stub_request(:get, /googleapis/).to_return(status: 200, body: response_body)

        result = service_call

        expect(result).to be_success
        expect(result.data[:title]).to eq("Clean Code")
        expect(result.data[:author]).to eq("Robert Martin, Micah Martin")
        expect(result.data[:cover_url]).to eq("https://cover.jpg")
      end
    end

    context "when rate limit is hit" do
      it "returns rate_limit_exceeded and logs as info" do
        stub_request(:get, /googleapis/).to_return(status: 429)
        expect(service_call.error).to eq(:rate_limit_exceeded)
        expect(Rails.logger).to have_received(:info).with(/Rate limit.*#{isbn}/)
      end
    end

    GoogleBooksService::NETWORK_ERRORS.each do |error_class|
      it "returns a network_failure error on #{error_class}" do
        stub_request(:get, /googleapis/).to_raise(error_class)
        expect(service_call.error).to eq(:network_failure)
      end

      it "logs diagnostic error for #{error_class}" do
        stub_request(:get, /googleapis/).to_raise(error_class)
        service_call
        expect(Rails.logger).to have_received(:error).with(/Network failure.*#{isbn}/)
      end
    end

    context "when response is invalid JSON" do
      it "returns parsing_error" do
        stub_request(:get, /googleapis/).to_return(status: 200, body: "not-json")
        expect(service_call.error).to eq(:parsing_error)
      end
    end

    context "when book is not found" do
      it "returns book_not_found" do
        stub_request(:get, /googleapis/).to_return(status: 200, body: { totalItems: 0 }.to_json)
        expect(service_call.error).to eq(:book_not_found)
      end
    end
  end
end
