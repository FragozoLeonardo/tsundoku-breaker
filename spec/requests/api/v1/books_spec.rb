# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Books", type: :request do
  describe "GET /api/v1/books" do
    subject(:request) { get api_v1_books_path }

    let!(:oldest_book) { create(:book, created_at: 2.days.ago) }
    let!(:middle_book) { create(:book, created_at: 1.day.ago) }
    let!(:newest_book) { create(:book, created_at: Time.current) }

    before { request }

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

    let(:isbn) { "9780132350884" }
    let(:service_result) { GoogleBooksService::Result.new(success?: true, data: book_data, error: nil) }
    let(:book_data) do
      {
        title: "Clean Code",
        author: "Robert C. Martin",
        description: "A handbook of agile software craftsmanship",
        cover_url: "http://example.com/cover.jpg"
      }
    end

    before do
      allow(GoogleBooksService).to receive(:call).with(isbn).and_return(service_result)
    end

    context "when the book is found and valid" do
      it "creates a new book" do
        expect { request }.to change(Book, :count).by(1)
      end

      it "returns http created" do
        request
        expect(response).to have_http_status(:created)
      end

      it "returns the created book attributes" do
        request
        expect(response.parsed_body).to include(
          "title" => "Clean Code",
          "isbn" => "9780132350884",
          "author" => "Robert C. Martin"
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

    context "when the book is not found in Google Books" do
      let(:service_result) { GoogleBooksService::Result.new(success?: false, error: :book_not_found) }

      it "returns not found" do
        request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the external service fails" do
      let(:service_result) { GoogleBooksService::Result.new(success?: false, error: :api_error) }

      it "returns service unavailable" do
        request
        expect(response).to have_http_status(:service_unavailable)
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

      it "returns the updated book" do
        request
        expect(response.parsed_body["status"]).to eq("reading")
      end
    end

    context "with invalid parameters" do
      let(:params) { { book: { status: "invalid_status" } } }

      it "does not update the book" do
        expect { request }.not_to(change { book.reload.status })
      end

      it "returns unprocessable content" do
        request
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when trying to update protected attributes" do
      let(:original_isbn) { book.isbn }
      let(:params) { { book: { status: "finished", isbn: "0000000000" } } }

      it "updates the allowed attribute but ignores the protected one" do
        request
        book.reload
        expect(book.status).to eq("finished")
        expect(book.isbn).to eq(original_isbn)
      end
    end

    context "with empty or missing parameters" do
      let(:params) { {} }

      it "returns bad request" do
        request
        expect(response).to have_http_status(:bad_request)
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
