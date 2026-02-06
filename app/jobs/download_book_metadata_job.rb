# frozen_string_literal: true

class DownloadBookMetadataJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :exponentially_longer, attempts: 3

  def perform(book_id)
    book = Book.find(book_id)
    result = GoogleBooksService.call(book.isbn)

    if result.success?
      handle_success(book, result.data)
    else
      handle_failure(book, result.error)
    end
  end

  private

  def handle_success(book, data)
    book.update!(
      title: data[:title],
      author: data[:author],
      description: data[:description],
      cover_url: data[:cover_url],
      status: :tsundoku
    )
  end

  def handle_failure(book, error_type)
    return unless book.processing?

    log_failure(book, error_type)
    persist_failure(book, error_type)
  end

  def log_failure(book, error_type)
    case error_type
    when :book_not_found
      Rails.logger.warn "[DownloadBookMetadataJob] Book not found for ISBN: #{book.isbn}"
    when :rate_limit_exceeded
      Rails.logger.info "[DownloadBookMetadataJob] Rate limit exceeded for ISBN: #{book.isbn}"
    else
      Rails.logger.error "[DownloadBookMetadataJob] Error: #{error_type} for ISBN: #{book.isbn}"
    end
  end

  def persist_failure(book, error_type)
    book.status = error_type == :book_not_found ? :abandoned : :processing
    book.save(validate: false)
  end
end
