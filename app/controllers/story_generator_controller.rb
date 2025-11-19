require_relative '../../lib/game_generator'

class StoryGeneratorController < ApplicationController
  def new
    # Show the form for entering a story prompt
  end

  def create
    prompt = params[:prompt]
    
    if prompt.blank?
      flash[:error] = "Please enter a prompt for your story"
      redirect_to new_story_generator_path and return
    end

    begin
      # Generate the story using the GameGenerator
      Rails.logger.info("Generating story from prompt: #{prompt}")
      generator = TextBasedGame::Generator.new
      story_json = generator.generate(prompt)
      
      # Parse the JSON response
      story_data = JSON.parse(story_json)
      
      # Generate a unique story ID
      story_id = SecureRandom.hex(16)
      
      # Save story to cache (expires in 24 hours)
      Rails.cache.write("story_#{story_id}", story_data, expires_in: 24.hours)
      
      # Save only the story ID in session (much smaller)
      session[:story_id] = story_id
      session[:current_scene_id] = story_data['start_scene']
      session[:choices_made] = []
      
      Rails.logger.info("Story generated successfully: #{story_data['title']} (ID: #{story_id})")
      
      # Redirect to play the game
      redirect_to game_path
    rescue => e
      Rails.logger.error("Story generation failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      flash[:error] = "Failed to generate story: #{e.message}"
      redirect_to new_story_generator_path
    end
  end
end

