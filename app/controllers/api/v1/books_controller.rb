# frozen_string_literal: true

module Api
  module V1
    class BooksController < ApplicationController
      def index
        books = Book.order(created_at: :desc)
        render json: books
      end

      def create
        isbn = book_params[:isbn]
        result = GoogleBooksService.call(isbn)

        if result.success?
          create_book_from(result.data, isbn)
        else
          handle_service_error(result.error)
        end
      end

      private

      def book_params
        params.expect(book: [:isbn])
      end

      def create_book_from(book_data, isbn)
        book = Book.new(book_data.merge(isbn: isbn))

        if book.save
          render json: book, status: :created
        else
          render json: { errors: book.errors }, status: :unprocessable_content
        end
      end

      def handle_service_error(error_code)
        case error_code
        when :book_not_found
          render json: { error: "Book not found" }, status: :not_found
        else
          render json: { error: "Service unavailable" }, status: :service_unavailable
        end
      end
    end
  end
end
