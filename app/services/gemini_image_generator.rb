# Gemini image generator
class GeminiImageGenerator < ImageGeneratorBase
  def initialize(options = {})
    super(options)
    @api_key = ENV['GEMINI_API_KEY']
    @api_url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent'
  end

  protected

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
    result = JSON.parse(response.body)

    if result.key?('error')
      Rails.logger.error "Gemini API Error: #{result.dig('error', 'message')}"
      Rails.logger.error "Gemini API Response: #{response.body}"
      Rails.logger.error "Gemini API Payload: #{request_body.to_json}"
      return nil
    end

    base64_data = result.dig('candidates', 0, 'content', 'parts', 0, 'inlineData', 'data')

    unless base64_data
      Rails.logger.error "Gemini API Error: Could not find image data in response."
      Rails.logger.error "Gemini API Response: #{response.body}"
      Rails.logger.error "Gemini API Payload: #{request_body.to_json}"
      return nil
    end

    base64_data
  end
end
