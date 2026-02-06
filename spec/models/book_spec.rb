# frozen_string_literal: true

require "rails_helper"

RSpec.describe Book, type: :model do
  subject(:book) { build(:book) }

  describe "database schema" do
    it { is_expected.to have_db_column(:isbn).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_index(:isbn).unique(true) }
  end

  describe "enums" do
    it "defines the expected status values" do
      expect(book).to define_enum_for(:status)
        .with_values(processing: 0, tsundoku: 1, reading: 2, finished: 3, abandoned: 4)
    end

    %i[processing tsundoku reading finished abandoned].each do |state|
      it "allows the state #{state}" do
        expect(build(:book, state)).to be_a(described_class)
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:isbn) }
    it { is_expected.to validate_uniqueness_of(:isbn).case_insensitive }

    context "when status is processing" do
      subject(:processing_book) { build(:book, status: :processing, title: nil) }

      it { is_expected.to be_valid }
    end

    %i[tsundoku reading finished abandoned].each do |state|
      context "when status is #{state}" do
        subject(:state_book) { build(:book, status: state, title: nil) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe "normalizations" do
    it "normalizes isbn correctly" do
      instance = described_class.create!(isbn: " 978-013-235-0884 ", status: :processing)
      expect(instance.isbn).to eq("9780132350884")
    end

    it "strips whitespace from the title" do
      instance = described_class.create!(isbn: "1234567890", title: "  Clean Code  ", status: :tsundoku)
      expect(instance.title).to eq("Clean Code")
    end

    it "handles nil values gracefully" do
      expect(build(:book, isbn: nil).isbn).to be_nil
      expect(build(:book, title: nil).title).to be_nil
    end
  end

  describe "readonly attributes" do
    it "prevents changing isbn after creation" do
      persisted = create(:book, isbn: "1234567890")
      expect { persisted.update!(isbn: "0987654321") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end
end
