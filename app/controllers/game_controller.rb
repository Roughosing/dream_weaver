class GameController < ApplicationController
  before_action :load_story
  before_action :initialize_session

  def show
    @current_scene = get_current_scene
    @scene_image = generate_or_get_image(@current_scene)
  end

  def choose
    choice_index = params[:choice_index].to_i
    current_scene_id = session[:current_scene_id]
    current_scene = @story['scenes'].find { |s| s['id'] == current_scene_id }
    
    if current_scene && current_scene['choices'][choice_index]
      next_scene_id = current_scene['choices'][choice_index]['next_scene']
      session[:current_scene_id] = next_scene_id
      session[:choices_made] ||= []
      session[:choices_made] << { scene: current_scene_id, choice: choice_index }
    end

    redirect_to game_path
  end

  def restart
    if params[:new_story]
      # Clear the story ID and go back to the generator
      if session[:story_id].present?
        # Delete cached story data
        Rails.cache.delete("story_#{session[:story_id]}")
        
        # Clean up old story images
        cleanup_story_images(session[:story_id])
      end
      session[:story_id] = nil
      session[:current_scene_id] = nil
      session[:choices_made] = []
      redirect_to root_path
    else
      # Restart the current story
      session[:current_scene_id] = @story['start_scene']
      session[:choices_made] = []
      redirect_to game_path
    end
  end

  private

  def load_story
    # Check if there's a generated story ID in the session
    if session[:story_id].present?
      # Load from cache using the story ID
      @story = Rails.cache.read("story_#{session[:story_id]}")
      
      if @story.present?
        Rails.logger.info("Using generated story: #{@story['title']}")
      else
        # Cache expired or missing, fall back to default
        Rails.logger.warn("Story cache expired, using default story")
        story_file = Rails.root.join('db', 'stories', 'default_story.json')
        @story = JSON.parse(File.read(story_file))
      end
    else
      # Fall back to the default story file
      story_file = Rails.root.join('db', 'stories', 'default_story.json')
      @story = JSON.parse(File.read(story_file))
      Rails.logger.info("Using default story file")
    end
  end

  def initialize_session
    session[:current_scene_id] ||= @story['start_scene']
    session[:choices_made] ||= []
  end

  def get_current_scene
    scene_id = session[:current_scene_id]
    scene = @story['scenes'].find { |s| s['id'] == scene_id }
    
    # If scene not found (e.g., old session with different story), reset to start
    if scene.nil?
      Rails.logger.warn("Scene '#{scene_id}' not found, resetting to start scene")
      session[:current_scene_id] = @story['start_scene']
      scene = @story['scenes'].find { |s| s['id'] == @story['start_scene'] }
    end
    
    scene || @story['scenes'].first
  end

  def generate_or_get_image(scene)
    image_generator = ImageGeneratorFactory.create
    # Include story_id in cache key so each story has unique images
    story_id = session[:story_id] || 'default'
    cache_key = "#{story_id}_#{scene['id']}"
    image_generator.generate(scene['image_prompt'], cache_key)
  end
  
  def cleanup_story_images(story_id)
    # Remove all images associated with this story
    return if story_id.blank?
    
    image_dir = Rails.root.join('public', 'images', 'generated')
    pattern = "#{story_id}_*.png"
    
    Dir.glob(File.join(image_dir, pattern)).each do |file|
      File.delete(file) rescue nil
    end
    
    Rails.logger.info("Cleaned up images for story: #{story_id}")
  rescue => e
    Rails.logger.error("Error cleaning up images: #{e.message}")
  end
end
