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

    request = Net::HTTP::Post.new(uri)
    request['x-goog-api-key'] = @api_key
    request['Content-Type'] = 'application/json'
    request.body = {
      contents: [{
        parts: [
          { text: prompt }
        ]
      }]
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    # The response structure for Gemini image generation is typically nested.
    # This extracts the base64 encoded image data.
    result.dig('candidates', 0, 'content', 'parts', 0, 'inlineData', 'data')
  end
end
