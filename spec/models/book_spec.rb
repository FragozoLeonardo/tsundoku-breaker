# frozen_string_literal: true

require "rails_helper"

RSpec.describe Book, type: :model do
  # Cria a variável 'book' para ser usada nos testes
  # Define 'book' como o sujeito implícito
  subject { book }

  let(:book) { described_class.new(title: "High Performance Postgres", isbn: "978-1234567890", status: :tsundoku) }

  describe "database schema" do
    it { is_expected.to have_db_column(:title).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:isbn).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:integer).with_options(default: :tsundoku, null: false) }

    it { is_expected.to have_db_index(:isbn).unique(true) }
    it { is_expected.to have_db_index(:status) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:isbn) }
    it { is_expected.to validate_uniqueness_of(:isbn).case_insensitive }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(tsundoku: 0, reading: 1, finished: 2) }

    it "raises ArgumentError when setting an invalid status" do
      expect { book.status = :invalid_option }.to raise_error(ArgumentError)
    end
  end
end
