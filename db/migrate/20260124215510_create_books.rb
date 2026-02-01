# frozen_string_literal: true

class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.text :title, null: false
      t.string :author
      t.text :description

      t.string :isbn, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :books, :isbn, unique: true
    add_index :books, :status
  end
end
