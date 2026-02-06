# frozen_string_literal: true

class DownloadBookMetadataJob < ApplicationJob
  queue_as :default

  def perform(book_id)
    book = Book.find(book_id)
    result = GoogleBooksService.call(book.isbn)

    if result.success?
      book.update!(book_attributes(result.data).merge(status: :tsundoku))
    else
      Rails.logger.error "[DownloadBookMetadataJob] Error: #{result.error}"
    end
  end

  private

  def book_attributes(data)
    {
      title: data[:title],
      author: data[:author],
      description: data[:description],
      cover_url: data[:cover_url]
    }
  end
end
