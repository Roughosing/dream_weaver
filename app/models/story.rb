# Model to handle story loading and parsing
class Story
  def self.load(story_name = 'default_story')
    story_file = Rails.root.join('db', 'stories', "#{story_name}.json")
    JSON.parse(File.read(story_file))
  end

  def self.find_scene(story_data, scene_id)
    story_data['scenes'].find { |s| s['id'] == scene_id }
  end

  def self.is_ending?(scene)
    scene['choices'].nil? || scene['choices'].empty?
  end
end

