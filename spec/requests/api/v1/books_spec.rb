# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  describe "GET /api/v1/books" do
    subject(:get_books) { get api_v1_books_path }

    let!(:book) do
      create(:book, title: "  Clean Code  ", isbn: "978-0132350884")
    end

    let(:expected_attributes) do
      {
        "id" => book.id,
        "title" => "Clean Code",
        "isbn" => "9780132350884",
        "status" => "tsundoku"
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

    it "orders books by creation (newest first)" do
      get_books
      expect(response.parsed_body.first["id"]).to eq(Book.last.id)
    end

    it "returns normalized data" do
      get_books
      expect(response.parsed_body).to include(a_hash_including(expected_attributes))
    end
  end
end
