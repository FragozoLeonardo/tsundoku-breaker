# frozen_string_literal: true

require "net/http"
require "json"

class GoogleBooksService
  # Pattern: Result Object
  # Retorna uma estrutura previsível: { success?, data, error }
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
    # Resiliência: Em caso de falha catastrófica de rede (DNS, Timeout),
    # retornamos um erro controlado em vez de explodir a aplicação.
    Result.new(success?: false, error: :api_error)
  end

  private

  attr_reader :isbn

  def fetch_from_google
    uri = URI("#{BASE_URL}?q=isbn:#{isbn}")
    Net::HTTP.get_response(uri)
  end

  def parse_response(response)
    # Garante que a resposta foi 2xx (Sucesso)
    return Result.new(success?: false, error: :api_error) unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    items = body["items"]

    # Se a lista de livros vier vazia ou nula
    return Result.new(success?: false, error: :book_not_found) if items.blank?

    book_info = items.first["volumeInfo"]

    # Mapeamento dos dados
    Result.new(
      success?: true,
      data: {
        title: book_info["title"],
        authors: book_info["authors"],
        description: book_info["description"],
        remote_cover_url: book_info.dig("imageLinks", "thumbnail")
      },
      error: nil
    )
  end
end
