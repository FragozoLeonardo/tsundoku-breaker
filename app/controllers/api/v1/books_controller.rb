# frozen_string_literal: true

module Api
  module V1
    class BooksController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ArgumentError, with: :render_unprocessable

      def index
        books = Book.order(created_at: :desc)
        render json: BookBlueprint.render(books)
      end

      def create
        book = Book.new(isbn: create_params[:isbn], status: :processing)

        if book.save
          DownloadBookMetadataJob.perform_later(book.id)
          render json: BookBlueprint.render(book), status: :accepted
        else
          render json: { errors: book.errors }, status: :unprocessable_content
        end
      end

      def update
        book = Book.find(params[:id])

        return render json: { error: "Book is still being processed" }, status: :conflict if book.processing?

        if book.update(update_params)
          render json: BookBlueprint.render(book)
        else
          render json: { errors: book.errors }, status: :unprocessable_content
        end
      end

      private

      def create_params
        params.expect(book: [:isbn])
      end

      def update_params
        params.expect(book: %i[status title author description cover_url])
      end

      def render_not_found
        render json: { error: "Book not found" }, status: :not_found
      end

      def render_bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def render_unprocessable(exception)
        render json: { error: exception.message }, status: :unprocessable_content
      end
    end
  end
end
