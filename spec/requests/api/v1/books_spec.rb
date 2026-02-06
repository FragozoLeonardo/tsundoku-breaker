# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  include ActiveJob::TestHelper

  describe "GET /api/v1/books" do
    subject(:request) { get api_v1_books_path }

    let!(:newest_book) { create(:book, created_at: Time.current) }

    before do
      create(:book, created_at: 2.days.ago)
      create(:book, created_at: 1.day.ago)
      request
    end

    it "returns http success" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all books" do
      expect(response.parsed_body.size).to eq(3)
    end

    it "orders books by creation date (newest first)" do
      expect(response.parsed_body.first["id"]).to eq(newest_book.id)
    end
  end

  describe "POST /api/v1/books" do
    subject(:request) { post api_v1_books_path, params: { book: { isbn: isbn } } }

    before do
      ActiveJob::Base.queue_adapter = :test
    end

    let(:isbn) { "9780132350884" }

    context "with valid parameters" do
      it "creates a new book in processing status" do
        expect { request }.to change(Book, :count).by(1)
        expect(Book.last.status).to eq("processing")
      end

      it "returns http accepted" do
        request
        expect(response).to have_http_status(:accepted)
      end

      it "enqueues the metadata download job" do
        expect { request }.to have_enqueued_job(DownloadBookMetadataJob)
          .with(instance_of(Integer)) # O job recebe o ID do livro
      end

      it "returns the initial book attributes" do
        request
        expect(response.parsed_body).to include(
          "isbn" => isbn,
          "status" => "processing"
        )
      end
    end

    context "when the book already exists" do
      before { create(:book, isbn: isbn) }

      it "does not create a new book" do
        expect { request }.not_to change(Book, :count)
      end

      it "returns unprocessable content" do
        request
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns error messages" do
        request
        expect(response.parsed_body["errors"]).to include("isbn")
      end
    end
  end

  describe "PATCH /api/v1/books/:id" do
    subject(:request) { patch api_v1_book_path(book_id), params: params }

    let!(:book) { create(:book, status: :tsundoku) }
    let(:book_id) { book.id }
    let(:params) { { book: { status: "reading" } } }

    context "with valid parameters" do
      it "updates the book status" do
        expect { request }.to change { book.reload.status }.from("tsundoku").to("reading")
      end

      it "returns http ok" do
        request
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the book is still processing" do
      let!(:book) { create(:book, status: :processing) }
      let(:params) { { book: { status: "reading" } } }

      it "returns unprocessable content" do
        request
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns a specific error message" do
        request
        expect(response.parsed_body["error"]).to eq("Book is still being processed and cannot be updated")
      end
    end

    context "with invalid parameters" do
      let(:params) { { book: { status: "invalid_status" } } }

      it "returns unprocessable content" do
        request
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when book does not exist" do
      let(:book_id) { -1 }

      it "returns not found" do
        request
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
