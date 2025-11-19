# Gemini image generator
class GeminiImageGenerator < ImageGeneratorBase
  def initialize(options = {})
    super(options)
    @api_key = ENV['GEMINI_API_KEY']
    @api_url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent'
  end

  protected

  def system_prompt
    'this image will be used for text based game with visuals. It should give enough context of what is going on. do not draw any texts, draw emotions instead to express feelings. Images should not be abstract. REflect actions, or dialogues, or emotions. Suspense. Drama. Conflict.'
  end

  # Override to prepend the system prompt for more accurate logging and better separation of concerns
  def build_prompt_with_context(prompt, context)
    base_prompt = super(prompt, context)
    "#{system_prompt}\n#{base_prompt}"
  end

  def call_api(prompt)
    require 'net/http'
    require 'json'

    uri = URI(@api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 60
    http.read_timeout = 60
    # In development, disable SSL verification to avoid local certificate errors.
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    request = Net::HTTP::Post.new(uri)
    request['x-goog-api-key'] = @api_key
    request['Content-Type'] = 'application/json'
    request_body = {
      contents: [{
        parts: [
          { text: prompt }
        ]
      }]
    }
    request.body = request_body.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Gemini API HTTP Error: #{response.code} #{response.message}"
      Rails.logger.error "Gemini API Response: #{response.body}"
      Rails.logger.error "Gemini API Payload: #{request_body.to_json}"
      # If it's a server error, raise an exception that will be retried
      raise Net::ReadTimeout, "Gemini API returned a server error: #{response.code}" if response.is_a?(Net::HTTPServerError)
      return nil # For client errors (4xx), don't retry
    end

    result = JSON.parse(response.body)

    if result.key?('error')
      Rails.logger.error "Gemini API Error: #{result.dig('error', 'message')}"
      Rails.logger.error "Gemini API Response: #{response.body}"
      Rails.logger.error "Gemini API Payload: #{request_body.to_json}"
      return nil
    end

    parts = result.dig('candidates', 0, 'content', 'parts')
    image_part = parts&.find { |part| part.key?('inlineData') }
    base64_data = image_part&.dig('inlineData', 'data')

    unless base64_data
      Rails.logger.error 'Gemini API Error: Could not find image data in response.'
      Rails.logger.error "Gemini API Response: #{response.body}"
      Rails.logger.error "Gemini API Payload: #{request_body.to_json}"
      return nil
    end

    base64_data
  end
end
