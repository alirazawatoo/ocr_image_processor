# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'rails', '~> 8.1.4'

gem 'bootsnap', require: false
gem 'importmap-rails'
gem 'pg', '~> 1.6'
gem 'puma', '>= 6.4'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]

# OCR and image drawing
gem 'ostruct' # rtesseract uses OpenStruct, which leaves Ruby's default gems in 4.0
gem 'rmagick', '~> 6.1'
gem 'rtesseract', '~> 3.1'

# Background jobs (Active Job adapter) backed by Redis
gem 'redis', '>= 5.0'
gem 'sidekiq', '~> 8.1'

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 8.0'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'faker'
  gem 'shoulda-matchers'
end
