# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :ocr_documents, only: %i[new create show] do
    get 'search', on: :member, defaults: { format: :json }
  end

  root to: 'ocr_documents#new'
end
