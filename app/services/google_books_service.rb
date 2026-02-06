# frozen_string_literal: true

require "net/http"
require "json"

class GoogleBooksService
  Result = Struct.new(:success?, :data, :error, :latency, keyword_init: true)

  BASE_URL = "https://www.googleapis.com/books/v1/volumes"
  HTTP_TIMEOUTS = { open: 5, read: 10 }.freeze

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
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = fetch_from_google
    latency = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

    parse_response(response, latency)
  rescue JSON::ParserError => e
    log_diagnostic("Invalid JSON", e)
    api_error_result(:parsing_error)
  rescue *NETWORK_ERRORS => e
    log_diagnostic("Network failure", e)
    api_error_result(:network_failure)
  end

  private

  attr_reader :isbn

  def fetch_from_google
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form({ q: "isbn:#{@isbn}", key: api_key }.compact)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = HTTP_TIMEOUTS[:open]
    http.read_timeout = HTTP_TIMEOUTS[:read]

    http.get(uri.request_uri)
  end

  def api_key
    ENV.fetch("GOOGLE_BOOKS_API_KEY", nil)
  end

  def parse_response(response, latency)
    case response
    when Net::HTTPSuccess then handle_success(response, latency)
    when Net::HTTPTooManyRequests
      log_diagnostic("Rate limit (429)", nil, level: :info)
      api_error_result(:rate_limit_exceeded, latency)
    else
      log_diagnostic("API Error: #{response&.code}", nil)
      api_error_result(:api_error, latency)
    end
  end

  def handle_success(response, latency)
    body = JSON.parse(response.body)
    return book_not_found_result(latency) if body["items"].blank?

    Result.new(
      success?: true,
      latency: latency,
      data: format_book_data(body["items"].first["volumeInfo"]),
      error: nil
    )
  end

  def format_book_data(info)
    {
      title: info["title"]&.strip,
      author: Array(info["authors"]).join(", ").presence || "Unknown Author",
      description: info["description"],
      cover_url: info.dig("imageLinks", "thumbnail")&.gsub("http://", "https://")
    }
  end

  def api_error_result(error, latency = nil)
    Result.new(success?: false, error: error, latency: latency)
  end

  def book_not_found_result(latency)
    Result.new(success?: false, error: :book_not_found, latency: latency)
  end

  def log_diagnostic(msg, error, level: :error)
    details = error ? " | #{error.class}: #{error.message}" : ""
    Rails.logger.send(level, "[GoogleBooksService] #{msg}#{details} | ISBN: #{@isbn}")
  end
end
