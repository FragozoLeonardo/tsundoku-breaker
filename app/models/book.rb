# frozen_string_literal: true

class Book < ApplicationRecord
  attr_readonly :isbn

  enum :status, {
    processing: 0,
    tsundoku: 1,
    reading: 2,
    finished: 3,
    abandoned: 4
  }

  # Normalizações nativas do Rails 7.1+
  normalizes :title, with: ->(value) { value&.strip }
  normalizes :isbn, with: ->(value) { value&.strip&.delete("-") }

  validates :title, presence: true, unless: :processing?

  validates :isbn,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[0-9]{10,13}\z/ }
end
