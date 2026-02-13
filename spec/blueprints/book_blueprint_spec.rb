# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookBlueprint do
  describe "Serialization" do
    let(:book) { create(:book, title: "Clean Code", author: "Robert Martin") }

    it "serializes the basic fields" do
      result = JSON.parse(described_class.render(book))

      expect(result["title"]).to eq("Clean Code")
      expect(result["author"]).to eq("Robert Martin")
    end

    context "with different statuses" do
      it "returns 'Fetching metadata...' for processing books" do
        book.status = :processing
        book.title = nil
        result = JSON.parse(described_class.render(book))

        expect(result["title"]).to eq("Fetching metadata...")
      end
    end
  end
end
