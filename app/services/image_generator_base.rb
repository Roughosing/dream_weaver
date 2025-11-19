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
  def generate(prompt, scene_id, context = {})
    cached_image = get_cached_image(scene_id)
    if cached_image
      Rails.logger.debug "Image cache HIT for scene '#{scene_id}': #{cached_image}"
      return cached_image
    end

    full_prompt = build_prompt_with_context(prompt, context)

    Rails.logger.info "Image cache MISS for scene '#{scene_id}'. Generating with #{self.class.name}."
    Rails.logger.debug "Image prompt: #{full_prompt}"

    # Generate new image
    image_data = nil
    begin
      Retriable.retriable on: [Net::OpenTimeout, Net::ReadTimeout, Faraday::TimeoutError], tries: 3, base_interval: 1 do |try|
        Rails.logger.info "Attempting to generate image for scene '#{scene_id}' (attempt #{try})..." if try > 1
        image_data = call_api(full_prompt)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Faraday::TimeoutError => e
      Rails.logger.error "Image generation failed for scene '#{scene_id}' after multiple retries: #{e.class} - #{e.message}"
      return nil
    end

    if image_data.blank?
      Rails.logger.error "Image generation failed: API returned no data for scene '#{scene_id}'."
      return nil
    end

    # Save and cache
    path = save_image(image_data, scene_id)
    Rails.logger.info "Image successfully generated and saved to #{path}"
    path
  end

  protected

  # Override this method in subclasses to call the specific API
  def call_api(prompt)
    raise NotImplementedError, "Subclasses must implement #call_api"
  end

  def build_prompt_with_context(prompt, context)
    full_prompt = [prompt]

    if context[:previous_choices].present?
      full_prompt << "CONTEXT FROM PREVIOUS CHOICES: #{context[:previous_choices]}"
    end

    if context[:style].present?
      full_prompt << "STYLE: #{context[:style]}"
    end

    if context[:tags].present?
      full_prompt << "TAGS: #{context[:tags]}"
    end

    full_prompt.join("\n\n")
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

  protected

  def get_cached_image(scene_id)
    # Default generator checks for PNG files
    cached_path = @cache_dir.join("#{scene_id}.png")
    
    if File.exist?(cached_path) && File.mtime(cached_path) > 10.seconds.ago
      return "/images/generated/#{scene_id}.png"
    end
    nil
  end
end
