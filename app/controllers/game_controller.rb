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
    session[:current_scene_id] = @story['start_scene']
    session[:choices_made] = []
    redirect_to game_path
  end

  def reset
    # Clear all session data for a fresh start
    reset_session

    # Delete all cached images
    cache_dir = Rails.root.join('public', 'images', 'generated')
    if Dir.exist?(cache_dir)
      FileUtils.rm_rf(Dir.glob("#{cache_dir}/*"))
    end

    redirect_to game_path
  end

  private

  def load_story
    story_file = Rails.root.join('db', 'stories', 'default_story.json')
    @story = JSON.parse(File.read(story_file))
  end

  def initialize_session
    session[:current_scene_id] ||= @story['start_scene']
    session[:choices_made] ||= []
  end

  def get_current_scene
    scene_id = session[:current_scene_id]
    @story['scenes'].find { |s| s['id'] == scene_id } || @story['scenes'].first
  end

  def generate_or_get_image(scene)
    image_generator = ImageGeneratorFactory.create

    # Build a context string from the text of previous choices
    previous_choices_text = session[:choices_made].map do |choice_info|
      previous_scene = @story['scenes'].find { |s| s['id'] == choice_info['scene'] }
      if previous_scene
        previous_scene['choices'][choice_info['choice']]['text']
      end
    end.compact.join('. ')

    image_generator.generate(scene['image_prompt'], scene['id'], { previous_choices: previous_choices_text })
  end
end
