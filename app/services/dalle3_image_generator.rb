require 'openai'

class Dalle3ImageGenerator < ImageGeneratorBase
  def initialize(options = {})
    super(options)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  protected

  def call_api(prompt)
    response = @client.images.generate(
      parameters: {
        model: "dall-e-3",
        prompt: prompt,
        size: "1024x1024",
        quality: "standard",
        n: 1
      }
    )

    response.dig("data", 0, "url")
  end
end
