# Base class for all image generators
# Implementations should inherit from this and implement the #generate method
class ImageGeneratorBase
  require 'fileutils'
  
  def initialize(options = {})
    @cache_dir = Rails.root.join('public', 'images', 'generated')
    FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
  end

  # Main method to generate or retrieve an image
  # Returns the path to the image file
  def generate(prompt, scene_id)
    cached_image = get_cached_image(scene_id)
    return cached_image if cached_image

    # Generate new image
    image_data = call_api(prompt)
    
    # Save and cache
    save_image(image_data, scene_id)
  end

  protected

  # Override this method in subclasses to call the specific API
  def call_api(prompt)
    raise NotImplementedError, "Subclasses must implement #call_api"
  end

  # Override this method if the API returns data in a different format
  def save_image(image_data, scene_id)
    file_path = @cache_dir.join("#{scene_id}.png")
    
    if image_data.is_a?(String) && image_data.start_with?('http')
      # Download from URL
      require 'open-uri'
      File.open(file_path, 'wb') do |file|
        file << URI.open(image_data).read
      end
    elsif image_data.is_a?(String) && image_data.length > 100 && !image_data.include?(' ')
      # Base64 encoded (long string without spaces)
      require 'base64'
      File.open(file_path, 'wb') do |file|
        file << Base64.decode64(image_data)
      end
    else
      # Binary data
      File.open(file_path, 'wb') do |file|
        file << image_data
      end
    end

    # Return relative path from public directory
    "/images/generated/#{scene_id}.png"
  end

  private

  def get_cached_image(scene_id)
    # Check for PNG first (actual generated images)
    # Ignore SVG placeholders - they should be regenerated
    cached_path_png = @cache_dir.join("#{scene_id}.png")
    cached_path_jpg = @cache_dir.join("#{scene_id}.jpg")
    cached_path_jpeg = @cache_dir.join("#{scene_id}.jpeg")
    
    if File.exist?(cached_path_png)
      return "/images/generated/#{scene_id}.png"
    elsif File.exist?(cached_path_jpg)
      return "/images/generated/#{scene_id}.jpg"
    elsif File.exist?(cached_path_jpeg)
      return "/images/generated/#{scene_id}.jpeg"
    end
    
    # Don't return SVG placeholders - force regeneration
    nil
  end
end
