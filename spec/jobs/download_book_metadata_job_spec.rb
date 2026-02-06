# frozen_string_literal: true

require "rails_helper"

RSpec.describe DownloadBookMetadataJob, type: :job do
  let(:book) { create(:book, status: :processing, title: nil) }

  describe "#perform" do
    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:error)
    end

    context "when service returns success" do
      let(:book_data) { { title: "Clean Code", author: "Robert Martin" } }
      let(:success_result) { instance_double(GoogleBooksService::Result, success?: true, data: book_data) }

      it "updates book metadata and sets status to tsundoku" do
        allow(GoogleBooksService).to receive(:call).with(book.isbn).and_return(success_result)
        described_class.perform_now(book.id)
        expect(book.reload.status).to eq("tsundoku")
        expect(book.title).to eq("Clean Code")
      end
    end

    context "when book is not found" do
      let(:not_found_result) { instance_double(GoogleBooksService::Result, success?: false, error: :book_not_found) }

      it "updates status to abandoned" do
        allow(GoogleBooksService).to receive(:call).with(book.isbn).and_return(not_found_result)
        described_class.perform_now(book.id)
        expect(book.reload.status).to eq("abandoned")
      end
    end

    %i[api_error parsing_error network_failure rate_limit_exceeded].each do |error_type|
      context "when service returns #{error_type}" do
        let(:failure_result) { instance_double(GoogleBooksService::Result, success?: false, error: error_type) }

        it "keeps status as processing for retry" do
          allow(GoogleBooksService).to receive(:call).with(book.isbn).and_return(failure_result)
          described_class.perform_now(book.id)
          expect(book.reload.status).to eq("processing")
        end
      end
    end
  end
end
