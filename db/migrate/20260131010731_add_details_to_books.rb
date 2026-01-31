# frozen_string_literal: true

class AddDetailsToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :author, :string
    add_column :books, :description, :text
    add_column :books, :cover_url, :string
  end
end
