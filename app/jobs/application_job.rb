# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # The document was deleted before the job ran; there is nothing left to do.
  discard_on ActiveJob::DeserializationError
end
