source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.3.6'

gem 'rails', '~> 7.1'
gem 'sqlite3', '~> 1.4'
gem 'puma', '~> 6.0'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 5.0'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'jbuilder', '~> 2.7'
gem 'redis', '~> 4.0'
gem 'bcrypt', '~> 3.1.7'

# AI Integration
gem 'ruby-openai'  # For ChatGPT and DALL-E 3
gem 'retriable'    # For simple, exponential backoff retries

# Image processing
gem 'image_processing', '~> 1.2'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'  # For loading .env files
end

group :development do
  gem 'web-console', '>= 4.1.0'
  gem 'listen', '~> 3.3'
  gem 'spring'
end
