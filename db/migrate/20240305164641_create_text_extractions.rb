# frozen_string_literal: true

class CreateTextExtractions < ActiveRecord::Migration[7.1]
  def change
    create_table :text_extractions do |t|
      t.text :word
      t.integer :confidence, null: false
      t.integer :x_start, null: false
      t.integer :y_start, null: false
      t.integer :x_end, null: false
      t.integer :y_end, null: false
      t.belongs_to :ocr_document, null: false, foreign_key: true
      t.timestamps
    end
  end
end
