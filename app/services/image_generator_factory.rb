# Factory to create the appropriate image generator based on configuration
class ImageGeneratorFactory
  def self.create
    generator_type = Rails.application.config.image_generator || :dalle3
    
    case generator_type
    when :dalle3
      Dalle3ImageGenerator.new
    when :midjourney
      MidjourneyImageGenerator.new
    when :stability
      StabilityImageGenerator.new
    when :placeholder
      PlaceholderImageGenerator.new
    else
      raise ArgumentError, "Unknown image generator: #{generator_type}"
    end
  end
end
