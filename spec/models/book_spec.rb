# frozen_string_literal: true

require "rails_helper"

RSpec.describe Book, type: :model do
  subject(:book) { build(:book) }

  describe "database schema" do
    it { is_expected.to have_db_column(:title).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:isbn).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:integer).with_options(default: :tsundoku, null: false) }
    it { is_expected.to have_db_index(:isbn).unique(true) }
    it { is_expected.to have_db_index(:status) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }

    context "when validating isbn format" do
      it { is_expected.to validate_presence_of(:isbn) }
      it { is_expected.to validate_uniqueness_of(:isbn).case_insensitive }

      it "accepts raw input with hyphens and normalizes it" do
        book.isbn = "978-1234567890"
        book.valid?
        expect(book.isbn).to eq("9781234567890")
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
    it { is_expected.to define_enum_for(:status).with_values(tsundoku: 0, reading: 1, finished: 2) }

    it "allows switching status to reading via trait" do
      expect(build(:book, :reading)).to be_reading
    end

    it "allows switching status to finished via trait" do
      expect(build(:book, :finished)).to be_finished
    end
  end
end
