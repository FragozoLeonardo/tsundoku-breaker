# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  describe "GET /api/v1/books" do
    subject(:request) { get api_v1_books_path }

    let!(:normalized_book) do
      create(:book, title: "  Clean Code  ", isbn: "978-0132350884")
    end
    let!(:newest_book) { create(:book) }

    before { request }

    it "returns http success" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all books" do
      expect(response.parsed_body.size).to eq(2)
    end

    it "orders books by creation date (newest first)" do
      expect(response.parsed_body.first["id"]).to eq(newest_book.id)
    end

    it "returns normalized data" do
      expect(response.parsed_body).to include(
        a_hash_including(
          "id" => normalized_book.id,
          "title" => "Clean Code",
          "isbn" => "9780132350884",
          "status" => "tsundoku"
        )
      )
    end
  end
end
