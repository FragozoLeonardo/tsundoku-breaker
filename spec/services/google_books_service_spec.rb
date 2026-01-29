# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleBooksService do
  describe ".call" do
    subject(:service_call) { described_class.call(isbn) }

    let(:isbn) { "9780132350884" }
    let(:base_url) { "https://www.googleapis.com/books/v1/volumes" }

    context "when the API returns data successfully" do
      let(:google_response) do
        {
          items: [
            {
              volumeInfo: {
                title: "Clean Code",
                authors: ["Robert C. Martin"],
                description: "Best book ever."
              }
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, "#{base_url}?q=isbn:#{isbn}")
          .to_return(status: 200, body: google_response, headers: { "Content-Type" => "application/json" })
      end

      it "returns a success result with book data" do
        result = service_call

        expect(result).to be_success
        expect(result.data[:title]).to eq("Clean Code")
        expect(result.data[:authors]).to eq(["Robert C. Martin"])
      end
    end

    context "when the book is not found" do
      let(:empty_response) { { totalItems: 0, items: [] }.to_json }

      before do
        stub_request(:get, "#{base_url}?q=isbn:#{isbn}")
          .to_return(status: 200, body: empty_response)
      end

      it "returns a failure result" do
        result = service_call
        expect(result).not_to be_success
        expect(result.error).to eq(:book_not_found)
      end
    end

    context "when the API request fails (500)" do
      before do
        stub_request(:get, "#{base_url}?q=isbn:#{isbn}")
          .to_return(status: 500)
      end

      it "returns a failure result with connection error" do
        result = service_call
        expect(result).not_to be_success
        expect(result.error).to eq(:api_error)
      end
    end
  end
end
