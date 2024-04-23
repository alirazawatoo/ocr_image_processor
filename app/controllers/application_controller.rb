# frozen_string_literal: true

# ApplicationController is the base class for all controllers in the application.
class ApplicationController < ActionController::Base
  add_flash_types :info, :error, :warning
end
