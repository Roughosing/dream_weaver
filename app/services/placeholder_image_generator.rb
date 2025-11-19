# Placeholder generator for development/testing
# Generates a simple SVG placeholder image
class PlaceholderImageGenerator < ImageGeneratorBase
  protected

  def call_api(prompt)
    # Generate a simple SVG placeholder
    width = 1024
    height = 1024
    text = prompt[0..60].gsub('"', "'")  # First 60 chars, escape quotes
    
    svg = <<~SVG
      <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
        <rect width="100%" height="100%" fill="#4A90E2"/>
        <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="24" 
              fill="white" text-anchor="middle" dominant-baseline="middle"
              style="font-weight: bold;">
          #{text}
        </text>
        <text x="50%" y="60%" font-family="Arial, sans-serif" font-size="16" 
              fill="rgba(255,255,255,0.7)" text-anchor="middle" dominant-baseline="middle">
          [Placeholder Image]
        </text>
      </svg>
    SVG
    
    # Convert SVG to PNG using a simple approach
    # For a real implementation, you'd use ImageMagick or similar
    # For now, we'll save as SVG and let the browser handle it
    svg
  end

  def save_image(image_data, scene_id)
    file_path = @cache_dir.join("#{scene_id}.svg")
    File.open(file_path, 'w') do |file|
      file << image_data
    end
    
    # Return path to the SVG
    "/images/generated/#{scene_id}.svg"
  end

  protected

  # Override to check for SVG files instead of PNG
  def get_cached_image(scene_id)
    cached_path = @cache_dir.join("#{scene_id}.svg")
    
    if File.exist?(cached_path) && File.mtime(cached_path) > 10.seconds.ago
      return "/images/generated/#{scene_id}.svg"
    end
    nil
  end
end

