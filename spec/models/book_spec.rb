# frozen_string_literal: true

require "rails_helper"

RSpec.describe Book, type: :model do
  subject(:book) { build(:book) }

  describe "database schema" do
    it { is_expected.to have_db_column(:title).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:isbn).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:author).of_type(:string) }
    it { is_expected.to have_db_column(:description).of_type(:text) }
    it { is_expected.to have_db_column(:cover_url).of_type(:string) }

    it "defaults status to tsundoku" do
      book = described_class.new
      expect(book.status).to eq("tsundoku")
    end

    it { is_expected.to have_db_index(:isbn).unique(true) }
    it { is_expected.to have_db_index(:status) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:isbn) }
    it { is_expected.to validate_uniqueness_of(:isbn).case_insensitive }

    context "when validating normalization and format" do
      it "removes hyphens from isbn before validation" do
        book.isbn = "978-1234567890"
        book.valid?
        expect(book.isbn).to eq("9781234567890")
      end

      it "strips whitespace from title" do
        book.title = "  Clean Code  "
        book.valid?
        expect(book.title).to eq("Clean Code")
      end

      it { is_expected.to allow_value("1234567890").for(:isbn) }
      it { is_expected.not_to allow_value("test-string").for(:isbn) }
      it { is_expected.not_to allow_value("isbn-123").for(:isbn) }
    end

    it "has a valid factory" do
      expect(book).to be_valid
    end

    context "with invalid traits" do
      it "is invalid when using the invalid trait" do
        expect(build(:book, :invalid)).not_to be_valid
      end
    end
  end

  describe "enums" do
    it do
      expect(book).to define_enum_for(:status)
        .with_values(tsundoku: 0, reading: 1, finished: 2)
    end

    it "allows switching status to reading via trait" do
      expect(build(:book, :reading)).to be_reading
    end

    it "allows switching status to finished via trait" do
      expect(build(:book, :finished)).to be_finished
    end
  end
end
