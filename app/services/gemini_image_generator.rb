# Gemini + Nanobanana Image Generator
# Uses Google's Gemini AI with Nanobanana for image generation
class GeminiImageGenerator < ImageGeneratorBase
  require 'net/http'
  require 'json'
  require 'uri'

  def initialize(options = {})
    super(options)
    @gemini_api_key = ENV['GEMINI_API_KEY']
    raise 'GEMINI_API_KEY environment variable not set' unless @gemini_api_key
    @gemini_text_url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent'
    # Nanobanana = Gemini 2.5 Flash Image model
    @gemini_image_url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent'
  end

  protected

  def call_api(prompt)
    # Step 1: Use Gemini text model to enhance the prompt
    enhanced_prompt = enhance_prompt_with_gemini(prompt)
    
    # Step 2: Generate image with Gemini Image model (Nanobanana)
    generate_with_gemini_image(enhanced_prompt || prompt)
  end

  def enhance_prompt_with_gemini(prompt)
    uri = URI("#{@gemini_text_url}?key=#{@gemini_api_key}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    request.body = {
      contents: [{
        parts: [{
          text: build_image_prompt(prompt)
        }]
      }],
      generationConfig: {
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 300
      }
    }.to_json

    begin
      response = http.request(request)
      result = JSON.parse(response.body)
      
      if response.code == '200'
        enhanced = result.dig('candidates', 0, 'content', 'parts', 0, 'text')
        Rails.logger.info("Gemini enhanced prompt: #{enhanced}")
        return enhanced
      else
        Rails.logger.error("Gemini text API Error: #{result}")
        return prompt
      end
    rescue => e
      Rails.logger.error("Gemini text API Exception: #{e.message}")
      return prompt
    end
  end

  private

  def build_image_prompt(prompt)
    "Transform this scene into a highly detailed visual description for ultra-high-definition AI image generation: #{prompt}. Create a photorealistic, cinematic description emphasizing: ultra-sharp details, dramatic lighting, professional composition, vivid atmospheric effects, rich textures, 4K quality cinematography. Focus only on visual elements."
  end

  def generate_with_gemini_image(prompt)
    # Use Gemini 2.5 Flash Image model (Nanobanana)
    uri = URI("#{@gemini_image_url}?key=#{@gemini_api_key}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 120 # Image generation can take time

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    
    # Request body for Gemini image generation - cinematic 16:9 format with maximum quality
    request.body = {
      contents: [{
        parts: [{
          text: "#{prompt}. Create an ultra-high-definition, photorealistic, cinematic widescreen 16:9 aspect ratio image with maximum detail and sharpness. Professional quality, 4K resolution, suitable for a visual novel game. Landscape orientation."
        }]
      }],
      generationConfig: {
        temperature: 0.85,
        topK: 40,
        topP: 0.95,
        responseMimeType: "image/png",
        responseModalities: ["image"]
      }
    }.to_json

    begin
      response = http.request(request)
      result = JSON.parse(response.body)
      
      Rails.logger.info("Gemini Image API Response Code: #{response.code}")
      
      if response.code == '200'
        # Check if there's inline image data in the response
        image_data = result.dig('candidates', 0, 'content', 'parts', 0, 'inlineData')
        
        if image_data && image_data['mimeType']&.start_with?('image/')
          Rails.logger.info("Gemini generated inline image data")
          # Return base64 data with mime type
          return {
            data: image_data['data'],
            mime_type: image_data['mimeType']
          }
        else
          Rails.logger.warn("No inline image in Gemini response, using fallback")
          Rails.logger.debug("Response: #{result.inspect}")
          generate_with_pollinations(prompt)
        end
      else
        Rails.logger.error("Gemini Image API Error: #{result}")
        generate_with_pollinations(prompt)
      end
    rescue => e
      Rails.logger.error("Gemini Image API Exception: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      generate_with_pollinations(prompt)
    end
  end

  def generate_with_pollinations(prompt)
    # Free fallback image generation - 16:9 cinematic format with maximum quality
    prompt_encoded = URI.encode_www_form_component(prompt)
    # Using Flux Pro model for highest quality, with enhanced settings
    "https://image.pollinations.ai/prompt/#{prompt_encoded}?width=1920&height=1080&nologo=true&enhance=true&seed=#{Time.now.to_i}&model=flux&quality=100"
  end

  def generate_placeholder(text)
    # Generate SVG placeholder with Gemini-enhanced description - 16:9 format
    width = 1920
    height = 1080
    
    # Wrap text for better display
    words = text[0..100].split(' ')
    lines = []
    current_line = []
    
    words.each do |word|
      current_line << word
      if current_line.join(' ').length > 40
        lines << current_line.join(' ')
        current_line = []
      end
    end
    lines << current_line.join(' ') unless current_line.empty?
    lines = lines[0..3] # Max 4 lines
    
    svg = <<~SVG
      <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
          </linearGradient>
        </defs>
        <rect width="100%" height="100%" fill="url(#grad1)"/>
        #{lines.each_with_index.map { |line, i|
          y_pos = 400 + (i * 50)
          %Q(<text x="50%" y="#{y_pos}" font-family="Arial, sans-serif" font-size="20" 
                fill="white" text-anchor="middle" dominant-baseline="middle">
              #{line.gsub('"', "'").gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')}
            </text>)
        }.join("\n        ")}
        <text x="50%" y="900" font-family="Arial, sans-serif" font-size="16" 
              fill="rgba(255,255,255,0.7)" text-anchor="middle" dominant-baseline="middle">
          [AI Generated Scene - Powered by Gemini]
        </text>
      </svg>
    SVG
    
    svg
  end

  def save_image(image_data, scene_id)
    # Check if it's a hash with base64 data (from Gemini)
    if image_data.is_a?(Hash) && image_data[:data]
      file_ext = image_data[:mime_type]&.split('/')&.last || 'png'
      file_path = @cache_dir.join("#{scene_id}.#{file_ext}")
      
      begin
        require 'base64'
        Rails.logger.info("Decoding base64 image data")
        
        decoded_data = Base64.decode64(image_data[:data])
        File.open(file_path, 'wb') do |file|
          file.write(decoded_data)
        end
        
        Rails.logger.info("Image saved to: #{file_path}")
        return "/images/generated/#{scene_id}.#{file_ext}"
      rescue => e
        Rails.logger.error("Failed to decode/save image: #{e.message}")
        # Generate fallback SVG
        file_path = @cache_dir.join("#{scene_id}.svg")
        File.open(file_path, 'w') do |file|
          file << generate_placeholder("Image generation in progress...")
        end
        return "/images/generated/#{scene_id}.svg"
      end
    end
    
    # Check if it's a URL (from Pollinations fallback)
    if image_data.is_a?(String) && image_data.start_with?('http')
      file_path = @cache_dir.join("#{scene_id}.png")
      
      begin
        require 'open-uri'
        Rails.logger.info("Downloading image from: #{image_data}")
        
        URI.open(image_data, 'rb', read_timeout: 60) do |image|
          File.open(file_path, 'wb') do |file|
            file.write(image.read)
          end
        end
        
        Rails.logger.info("Image saved to: #{file_path}")
        return "/images/generated/#{scene_id}.png"
      rescue => e
        Rails.logger.error("Failed to download image: #{e.message}")
        # Generate fallback SVG
        file_path = @cache_dir.join("#{scene_id}.svg")
        File.open(file_path, 'w') do |file|
          file << generate_placeholder("Image generation in progress...")
        end
        return "/images/generated/#{scene_id}.svg"
      end
    end
    
    # Fallback for SVG or other data
    file_path = @cache_dir.join("#{scene_id}.svg")
    File.open(file_path, 'w') do |file|
      file << image_data
    end
    
    "/images/generated/#{scene_id}.svg"
  end
end
