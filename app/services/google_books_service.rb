# frozen_string_literal: true

require "net/http"
require "json"

class GoogleBooksService
  Result = Struct.new(:success?, :data, :error, keyword_init: true)

  BASE_URL = "https://www.googleapis.com/books/v1/volumes"

  def self.call(isbn)
    new(isbn).perform
  end

  def initialize(isbn)
    @isbn = isbn
  end

  def perform
    response = fetch_from_google
    parse_response(response)
  rescue StandardError
    Result.new(success?: false, error: :api_error)
  end

  private

  attr_reader :isbn

  def fetch_from_google
    api_key = ENV.fetch("GOOGLE_BOOKS_API_KEY", nil)

    query_params = {
      q: "isbn:#{isbn}",
      key: api_key
    }.compact

    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(query_params)

    Net::HTTP.get_response(uri)
  end

  def parse_response(response)
    return Result.new(success?: false, error: :api_error) unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    items = body["items"]

    return Result.new(success?: false, error: :book_not_found) if items.blank?

    book_info = items.first["volumeInfo"]

    authors_array = book_info["authors"]
    author_string = authors_array&.join(", ")

    Result.new(
      success?: true,
      data: {
        title: book_info["title"],
        author: author_string,
        description: book_info["description"],
        remote_cover_url: book_info.dig("imageLinks", "thumbnail")
      },
      error: nil
    )
  end
end
