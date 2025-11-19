# frozen_string_literal: true

require 'httparty'
require 'json'
require 'dotenv/load'

# Main module for the Text-Based Game components.
module TextBasedGame
  # Convenience method to create a new generator and generate a game.
  #
  # @param prompt [String] The natural language prompt for the game.
  # @return [String] A JSON string representing the game graph.
  def self.generate(prompt)
    Generator.new.generate(prompt)
  end

  # The Generator class is responsible for taking a prompt
  # and returning a structured JSON representing the game.
  class Generator
    API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent'

    SYSTEM_PROMPT = <<~EOF
        Act as a World-Class Narrative Game Designer. Your task is to create a complete, immersive text-based adventure game.

        **Game Parameters:**
        1.  **Total Scenes:** Generate at least 20 scenes.
        2.  **Endings:** Include 2 to 4 distinct ending scenes (some positive, some negative).
        3.  **Theme/Genre:** Create a story that is intriguing, filled with plot twists, and fun to play. Include dialogues. It's an RPG.
      4.  **Narrative:** USe same structure as the most popular books/movies in the area. IT should be as fun and interesting as watching a movie. LEt's use best sources
        5.  **Visual Consistency:** All image prompts must share a consistent art style (e.g., "Cinematic lighting, unreal engine 5 render, noir style").
        6.  **Visuals:** Images should reflect character development. Interaction with world. Emotions.#{' '}

        **Structure Requirement:**
        You must output the game in a structured format. For EACH scene, use exactly this template:

        ---
        **Scene ID:** [Number]
        **Scene Title:** [Name of the scene]
        **Narrative:** [The story text. For Scene 1, you MUST explain who the player is, where they are, and what their ultimate goal is. Keep it engaging.]
        **Image Prompt:** [Detailed description for an AI image generator. Describe the setting, lighting, mood, and key objects. Do not use random descriptions; they must strictly match the Narrative.]
        **Choices:**
           A) [Text for Choice A] -> Leads to Scene [ID]
           B) [Text for Choice B] -> Leads to Scene [ID]
           (Optional) C) [Text for Choice C] -> Leads to Scene [ID]
           (Optional) D) [Text for Choice D] -> Leads to Scene [ID]
        ---

        **Logic Rules:**
        * **Scene 1 (Entry Point):** Must be the "Hook." Establish the protagonist's identity and the stakes immediately.
        * **Flow:** Ensure the "Leads to Scene [ID]" logic makes sense. Do not create dead ends unless it is an Ending Scene.
        * **Ending Scenes:** These should have NO choices, only a conclusion text and a "Game Over" or "Victory" status.

        **Instructions for Generation:**
        please generate the game full game, all scenes

        **Begin with the Plot Outline and Scene 1.**
    EOF

    # The JSON schema to be sent to the Gemini API to enforce
    # the structure of the generated game.
    RESPONSE_SCHEMA = {
      type: :object,
      properties: {
        title: { type: :string, description: 'The title of the game.' },
        style: { type: :string, description: 'Style used for images during generation' },
        tags: { type: :string, description: 'random tags that should express game style, mood, scenes design' },
        start_scene: { type: :string, description: 'The ID of the starting scene.' },
        scenes: {
          type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :string, description: 'A unique identifier for the scene.' },
              narrative_text: { type: :string, description: 'The text describing the scene to the player.' },
              image_prompt: { type: :string, description: 'A prompt to generate an image for the scene.' },
              choices: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    text: { type: :string, description: 'The text for a choice the player can make.' },
                    next_scene: { type: :string, description: 'The id of the scene this choice leads to.' }
                  },
                  required: %w[text next_scene]
                }
              }
            },
            required: %w[id narrative_text image_prompt choices]
          }
        }
      },
      required: %w[title start_scene scenes]
    }.freeze

    def initialize
      @api_key = ENV['GEMINI_API_KEY']
      raise 'GEMINI_API_KEY environment variable not set.' unless @api_key
    end

    # Generates a game from a text prompt.
    #
    # @param prompt [String] The natural language prompt for the game.
    # @return [String] A JSON string representing the game graph.
    def generate(prompt)
      response = call_gemini_api(prompt)
      # The response from Gemini is a JSON string within a larger structure.
      # We need to parse the response body and extract the text part containing the game JSON.
      JSON.parse(response.body)['candidates'][0]['content']['parts'][0]['text']
    end

    private

    # Calls the Gemini API with the given prompt.
    # @param prompt [String] The prompt to send to the API.
    # @return [HTTParty::Response] The response from the API.
    def call_gemini_api(prompt)
      headers = {
        'Content-Type' => 'application/json',
        'x-goog-api-key' => @api_key
      }
      body = {
        system_instruction: {
          parts: [
            { text: SYSTEM_PROMPT }
          ]
        },
        contents: [
          { role: 'user', parts: [{ text: prompt }] }
        ],
        generationConfig: {
          responseMimeType: 'application/json',
          temperature: 0.5,
          responseJsonSchema: RESPONSE_SCHEMA
        }
      }.to_json

      HTTParty.post(API_URL, headers: headers, body: body, timeout: 120)
    end
  end
end
