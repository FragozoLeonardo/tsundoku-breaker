# frozen_string_literal: true

module Api
  module V1
    class BooksController < ApplicationController
      def index
        books = Book.order(created_at: :desc)
        render json: books
      end
    end
  end
end
