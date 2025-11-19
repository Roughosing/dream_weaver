require 'openai'

class Dalle3ImageGenerator < ImageGeneratorBase
  def initialize(options = {})
    super(options)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'], request_timeout: 60)
  end

  protected

  def call_api(prompt)
    parameters = {
      model: "dall-e-3",
      prompt: prompt,
      size: "1024x1024",
      quality: "standard",
      n: 1
    }
    response = @client.images.generate(parameters: parameters)

    response.dig("data", 0, "url")
  rescue OpenAI::Error => e
    Rails.logger.error "DALL-E 3 API Error: #{e.message}"
    Rails.logger.error "DALL-E 3 Payload: #{parameters.to_json}"
    nil
  end
end
