# frozen_string_literal: true

class BookBlueprint < Blueprinter::Base
  identifier :id

  fields :author, :isbn, :status, :cover_url

  field :title do |book|
    if book.processing? && book.title.blank?
      "Fetching metadata..."
    else
      book.title
    end
  end

  view :short do
    fields :title, :author, :status
  end
end
