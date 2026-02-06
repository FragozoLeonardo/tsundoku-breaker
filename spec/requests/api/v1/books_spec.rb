# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  describe "API Safety & Headers" do
    it "returns JSON content type" do
      get api_v1_books_path
      expect(response.content_type).to include("application/json")
    end
  end

  describe "GET /api/v1/books" do
    before { create_list(:book, 3) }

    it "returns all books ordered by creation" do
      get api_v1_books_path
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end
  end

  describe "POST /api/v1/books" do
    let(:valid_params) { { book: { isbn: "9780132350884" } } }

    context "with valid ISBN" do
      it "creates a book and enqueues job" do
        ActiveJob::Base.queue_adapter = :test
        expect do
          post api_v1_books_path, params: valid_params
        end.to change(Book, :count).by(1).and have_enqueued_job(DownloadBookMetadataJob)

        expect(response).to have_http_status(:accepted)
      end
    end

    context "with duplicate ISBN" do
      it "returns unprocessable content" do
        create(:book, isbn: "9780132350884")
        post api_v1_books_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when parameters are missing" do
      it "returns bad request" do
        post api_v1_books_path, params: {}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "PATCH /api/v1/books/:id" do
    let(:book) { create(:book, status: :tsundoku, isbn: "1111111111") }

    it "updates book status" do
      patch api_v1_book_path(book), params: { book: { status: "reading" } }
      expect(response).to have_http_status(:ok)
      expect(book.reload.status).to eq("reading")
    end

    it "ignores isbn changes in requests" do
      patch api_v1_book_path(book), params: { book: { isbn: "9999999999" } }
      expect(book.reload.isbn).to eq("1111111111")
    end

    it "fails if book is still processing" do
      processing_book = create(:book, status: :processing)
      patch api_v1_book_path(processing_book), params: { book: { status: "reading" } }
      expect(response).to have_http_status(:conflict)
    end

    context "when book does not exist" do
      it "returns 404 not found" do
        patch api_v1_book_path(id: 999_999), params: { book: { status: "reading" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
