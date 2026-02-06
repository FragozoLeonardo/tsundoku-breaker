# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
#
class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.string :isbn, null: false
      t.text :title
      t.string :author
      t.text :description
      t.string :cover_url
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :books, :isbn, unique: true
    add_index :books, :status
  end
end

# rubocop:enable Metrics/MethodLength
