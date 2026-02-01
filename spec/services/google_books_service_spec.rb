# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe GoogleBooksService do
  describe ".call" do
    subject(:service_call) { described_class.call(isbn) }

    let(:isbn) { "9780132350884" }
    let(:base_url) { GoogleBooksService::BASE_URL }
    let(:fake_api_key) { "TEST_API_KEY" }

    before do
      allow(ENV).to receive(:fetch)
        .with("GOOGLE_BOOKS_API_KEY", nil)
        .and_return(fake_api_key)
    end

    context "when the API returns data successfully" do
      let(:google_response) do
        {
          items: [
            {
              volumeInfo: {
                title: "Clean Code",
                authors: ["Robert C. Martin"],
                description: "Best book ever.",
                imageLinks: { thumbnail: "http://cover.jpg" }
              }
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, base_url)
          .with(query: { q: "isbn:#{isbn}", key: fake_api_key })
          .to_return(
            status: 200,
            body: google_response,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns a success result with formatted book data" do
        result = service_call

        expect(result).to be_success
        expect(result.data).to include(
          title: "Clean Code",
          author: "Robert C. Martin"
        )
        expect(result.error).to be_nil
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end

    context "when the book is not found" do
      let(:empty_response) { { totalItems: 0, items: [] }.to_json }

      before do
        stub_request(:get, base_url)
          .with(query: { q: "isbn:#{isbn}", key: fake_api_key })
          .to_return(status: 200, body: empty_response)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "returns a failure result with book_not_found error" do
        result = service_call

        expect(result).not_to be_success
        expect(result.error).to eq(:book_not_found)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when the API returns a server error" do
      before do
        stub_request(:get, base_url)
          .with(query: { q: "isbn:#{isbn}", key: fake_api_key })
          .to_return(status: 500)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "returns a failure result with api_error" do
        result = service_call

        expect(result).not_to be_success
        expect(result.error).to eq(:api_error)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when the request times out" do
      before do
        stub_request(:get, base_url)
          .with(query: { q: "isbn:#{isbn}", key: fake_api_key })
          .to_timeout
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "handles the exception and returns api_error" do
        result = service_call

        expect(result).not_to be_success
        expect(result.error).to eq(:api_error)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when the response body is invalid JSON" do
      before do
        stub_request(:get, base_url)
          .with(query: { q: "isbn:#{isbn}", key: fake_api_key })
          .to_return(status: 200, body: "INVALID_JSON_DATA")
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "handles the exception and returns api_error" do
        result = service_call

        expect(result).not_to be_success
        expect(result.error).to eq(:api_error)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
