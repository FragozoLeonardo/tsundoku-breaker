# frozen_string_literal: true

module Api
  module V1
    class BooksController < ApplicationController
      def index
        render json: Book.all
      end
    end
  end
end
