# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  describe "GET /api/v1/books" do
    subject(:get_books) { get api_v1_books_path }

    let!(:book) { create(:book) }
    let(:expected_attributes) do
      {
        "id" => book.id,
        "title" => book.title,
        "isbn" => book.isbn,
        "status" => book.status
      }
    end

    before { create_list(:book, 2) }

    it "returns http success" do
      get_books
      expect(response).to have_http_status(:ok)
    end

    it "returns all books" do
      get_books
      expect(response.parsed_body.size).to eq(3)
    end

    it "returns the correct book data matching the database" do
      get_books
      expect(response.parsed_body).to include(a_hash_including(expected_attributes))
    end
  end
end
