# frozen_string_literal: true

module Api
  module V1
    class BooksController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Book not found" }, status: :not_found
      end

      rescue_from ActionController::ParameterMissing do
        render json: { error: "Parameter missing" }, status: :bad_request
      end

      rescue_from ArgumentError do |e|
        render json: { error: e.message }, status: :unprocessable_content
      end

      def index
        books = Book.order(created_at: :desc)
        render json: books
      end

      def create
        book = Book.new(isbn: create_params[:isbn], status: :processing)

        if book.save
          DownloadBookMetadataJob.perform_later(book.id)
          render json: book, status: :accepted
        else
          render json: { errors: book.errors }, status: :unprocessable_content
        end
      end

      def update
        book = Book.find(params[:id])

        if book.processing?
          return render json: { error: "Book is still being processed and cannot be updated" },
                        status: :unprocessable_content
        end

        if book.update(update_params)
          render json: book
        else
          render json: { errors: book.errors }, status: :unprocessable_content
        end
      end

      private

      def create_params
        params.expect(book: %i[isbn])
      end

      def update_params
        params.expect(book: %i[status title author description cover_url])
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
