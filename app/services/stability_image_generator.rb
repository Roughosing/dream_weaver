# Stability AI (Stable Diffusion) implementation
class StabilityImageGenerator < ImageGeneratorBase
  def initialize(options = {})
    super(options)
    @api_key = ENV['STABILITY_API_KEY']
    @api_url = 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image'
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
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request_body = {
      text_prompts: [{ text: prompt }],
      cfg_scale: 7,
      height: 1024,
      width: 1024,
      steps: 30,
      samples: 1
    }
    request.body = request_body.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Stability API Error: #{response.code} #{response.message}"
      Rails.logger.error "Stability API Response: #{response.body}"
      Rails.logger.error "Stability API Payload: #{request_body.to_json}"
      return nil
    end

    result = JSON.parse(response.body)

    base64_data = result.dig('artifacts', 0, 'base64')

    unless base64_data
      Rails.logger.error "Stability API Error: Could not find image data in response."
      Rails.logger.error "Stability API Response: #{response.body}"
      Rails.logger.error "Stability API Payload: #{request_body.to_json}"
      return nil
    end

    base64_data
  end

end
