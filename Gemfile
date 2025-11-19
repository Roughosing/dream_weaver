source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.3.6'

gem 'bcrypt', '~> 3.1.7'
gem 'jbuilder', '~> 2.7'
gem 'puma', '~> 6.0'
gem 'rails', '~> 7.1'
gem 'redis', '~> 4.0'
gem 'sass-rails', '>= 6'
gem 'sqlite3', '~> 1.4'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'webpacker', '~> 5.0'

# AI Integration
gem 'ruby-openai' # For ChatGPT and DALL-E 3

# Image processing
gem 'image_processing', '~> 1.2'

gem 'dotenv'
gem 'httparty'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails' # For loading .env files
end

group :development do
  gem 'listen', '~> 3.3'
  gem 'pry'
  gem 'rspec'
  gem 'spring'
  gem 'web-console', '>= 4.1.0'
end
