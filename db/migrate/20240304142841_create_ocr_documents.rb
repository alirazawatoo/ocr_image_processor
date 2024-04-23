# frozen_string_literal: true

class CreateOcrDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :ocr_documents do |t|
      t.datetime :hocr_processed_at

      t.timestamps
    end
  end
end
