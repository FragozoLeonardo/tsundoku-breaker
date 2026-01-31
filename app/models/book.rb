# frozen_string_literal: true

class Book < ApplicationRecord
  enum :status, { tsundoku: 0, reading: 1, finished: 2 }

  normalizes :title, with: ->(value) { value&.strip }
  normalizes :isbn, with: ->(value) { value&.strip&.delete("-") }

  validates :title, presence: true
  validates :isbn,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[0-9]+\z/ }
end
