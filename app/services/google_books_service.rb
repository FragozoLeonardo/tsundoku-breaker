# frozen_string_literal: true

require "net/http"
require "json"

class GoogleBooksService
  Result = Struct.new(:success?, :data, :error, keyword_init: true)

  BASE_URL = "https://www.googleapis.com/books/v1/volumes"

  API_ERRORS = [
    Net::OpenTimeout,
    Timeout::Error,
    JSON::ParserError
  ].freeze

  def self.call(isbn)
    new(isbn).perform
  end

  def initialize(isbn)
    @isbn = isbn
  end

  def perform
    response = fetch_from_google
    parse_response(response)
  rescue JSON::ParserError
    Result.new(success?: false, error: :api_error)
  rescue StandardError => e
    Rails.logger.error("GoogleBooksService Error: #{e.message}")
    Result.new(success?: false, error: :api_error)
  end

  private

  attr_reader :isbn

  def fetch_from_google
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(query_params)

    http_client.get_response(uri)
  end

  def query_params
    {
      q: "isbn:#{isbn}",
      key: api_key
    }.compact
  end

  def api_key
    ENV.fetch("GOOGLE_BOOKS_API_KEY", nil)
  end

  def http_client
    Net::HTTP
  end

  def parse_response(response)
    return api_error_result unless successful_response?(response)

    items = extract_items(response.body)
    return book_not_found_result if items.empty?

    build_success_result(items.first["volumeInfo"])
  end

  def successful_response?(response)
    response.is_a?(Net::HTTPSuccess)
  end

  def extract_items(body)
    parsed = JSON.parse(body)
    Array(parsed["items"])
  end

  def build_success_result(book_info)
    Result.new(
      success?: true,
      data: {
        title: book_info["title"],
        author: Array(book_info["authors"]).join(", "),
        description: book_info["description"],
        remote_cover_url: book_info.dig("imageLinks", "thumbnail")
      },
      error: nil
    )
  end

  def api_error_result
    Result.new(success?: false, error: :api_error)
  end

  def book_not_found_result
    Result.new(success?: false, error: :book_not_found)
  end

  def log_error(error)
    return unless defined?(Rails)

    Rails.logger.error(
      "[GoogleBooksService] #{error.class}: #{error.message}"
    )
  end
end
