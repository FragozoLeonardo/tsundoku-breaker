# frozen_string_literal: true

class Book < ApplicationRecord
  enum :status, { tsundoku: 0, reading: 1, finished: 2 }, default: :tsundoku

  validates :title, presence: true
  validates :isbn, presence: true, uniqueness: { case_sensitive: false }
  validates :status, presence: true
end
