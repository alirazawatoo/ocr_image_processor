# frozen_string_literal: true

class AddProcessingErrorToOcrDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :ocr_documents, :processing_error, :string
  end
end
