# frozen_string_literal: true

require "rails_helper"

RSpec.describe DownloadBookMetadataJob, type: :job do
  let(:book) { create(:book, status: :processing, title: nil) }
  let(:book_data) do
    {
      title: "Clean Code",
      author: "Robert C. Martin",
      description: "A Handbook of Agile Software Craftsmanship",
      cover_url: "http://example.com/cover.jpg"
    }
  end
  let(:service_result) { instance_double(GoogleBooksService::Result, success?: true, data: book_data) }

  it "updates book metadata and changes status to tsundoku" do
    allow(GoogleBooksService).to receive(:call).with(book.isbn).and_return(service_result)

    described_class.perform_now(book.id)

    book.reload
    expect(book.title).to eq("Clean Code")
    expect(book.status).to eq("tsundoku")
  end
end
