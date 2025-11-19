require 'openai'

# Service for ChatGPT integration
# Can be used for dynamic narrative generation, player input processing, etc.
class ChatGptService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  # Generate narrative text based on scene description
  def generate_narrative(scene_description, context = {})
    prompt = build_narrative_prompt(scene_description, context)
    
    response = @client.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a creative writer for an interactive visual novel. Write engaging, immersive narrative descriptions."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.8,
        max_tokens: 300
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  # Process player choice and generate dynamic response
  def process_choice(choice_text, scene_context)
    prompt = "The player chose: '#{choice_text}'. Scene context: #{scene_context}. Generate a brief narrative response."
    
    response = @client.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.9,
        max_tokens: 150
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  private

  def build_narrative_prompt(scene_description, context)
    base_prompt = "Write a vivid, immersive narrative description for this scene: #{scene_description}"
    
    if context[:mood]
      base_prompt += "\nMood: #{context[:mood]}"
    end
    
    if context[:previous_choices]
      base_prompt += "\nPrevious player choices: #{context[:previous_choices].join(', ')}"
    end

    base_prompt
  end
end
