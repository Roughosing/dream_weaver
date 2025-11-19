require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module DreamWeaver
  class Application < Rails::Application
    config.load_defaults 7.1
    
    # Configure which image generator to use
    # Options: :dalle3, :midjourney, :stability, :gemini, :placeholder
    config.image_generator = ENV.fetch('IMAGE_GENERATOR', 'placeholder').to_sym
    
    # Configuration for generators
    config.autoload_paths += %W(#{config.root}/app/services)
  end
end
