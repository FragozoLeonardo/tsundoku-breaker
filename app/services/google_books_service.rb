# frozen_string_literal: true

require "net/http"
require "json"

class GoogleBooksService
  Result = Struct.new(:success?, :data, :error, keyword_init: true)

  BASE_URL = "https://www.googleapis.com/books/v1/volumes"

  NETWORK_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout,
    Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError,
    OpenSSL::SSL::SSLError
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
  rescue JSON::ParserError => e
    log_error("Invalid JSON received from Google", e)
    api_error_result
  rescue *NETWORK_ERRORS => e
    log_error("Network connection failed", e)
    api_error_result
  end

  private

  attr_reader :isbn

  def fetch_from_google
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(query_params)

    Net::HTTP.get_response(uri)
  end

  def query_params
    {
      q: "isbn:#{@isbn}",
      key: api_key
    }.compact
  end

  def api_key
    ENV.fetch("GOOGLE_BOOKS_API_KEY", nil)
  end

  def parse_response(response)
    return api_error_result unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    items = body["items"]

    return book_not_found_result if items.blank?

    build_success_result(items.first["volumeInfo"])
  end

  def build_success_result(book_info)
    Result.new(
      success?: true,
      data: {
        title: book_info["title"],
        author: Array(book_info["authors"]).join(", "),
        description: book_info["description"],
        cover_url: book_info.dig("imageLinks", "thumbnail")
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

  def log_error(msg, error)
    Rails.logger.error("[GoogleBooksService] #{msg}: #{error.class} - #{error.message}")
  end
end
