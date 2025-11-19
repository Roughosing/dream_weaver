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

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      text_prompts: [{ text: prompt }],
      cfg_scale: 7,
      height: 1024,
      width: 1024,
      steps: 30,
      samples: 1
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    # Stability AI returns base64 encoded image
    result.dig('artifacts', 0, 'base64')
  end

  def save_image(image_data, scene_id)
    require 'base64'
    file_path = @cache_dir.join("#{scene_id}.png")
    File.open(file_path, 'wb') do |file|
      file << Base64.decode64(image_data)
    end
    file_path
  end
end
