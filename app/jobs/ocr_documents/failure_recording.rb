# frozen_string_literal: true

module OcrDocuments
  # Stores a reader-facing message on the document once a job gives up, and
  # keeps the technical detail in the log.
  module FailureRecording
    def record_failure(message, error)
      Rails.logger.error("#{self.class.name} gave up on document #{arguments.first}: #{error.class}: #{error.message}")
      OcrDocument.find_by(id: arguments.first)&.update!(processing_error: message)
    end
  end
end
