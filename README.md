# Dream Weaver - AI Powered Visual Novel

An immersive, web-based visual novel where the story and art are created dynamically using AI.

## Features

- **Branching Narrative**: Rich, interactive story with multiple paths and endings
- **Dynamic AI Art**: Images generated on-the-fly using pluggable AI image generators
- **ChatGPT Integration**: For narrative generation and dynamic storytelling
- **Pluggable Architecture**: Easy to swap between different image generation services

## Tech Stack

- **Framework**: Ruby on Rails 7.1
- **AI Services**: 
  - OpenAI (ChatGPT & DALL-E 3)
  - Pluggable image generators (DALL-E 3, Midjourney, Stability AI, Placeholder)

## Setup

1. **Install dependencies**:
   ```bash
   bundle install
   ```

2. **Set up environment variables**:
   Create a `.env` file in the root directory:
   ```bash
   OPENAI_API_KEY=your_openai_api_key_here
   IMAGE_GENERATOR=placeholder  # Options: placeholder, dalle3, midjourney, stability
   ```

3. **Create necessary directories**:
   ```bash
   mkdir -p storage/images/generated
   ```

4. **Start the Rails server**:
   ```bash
   rails server
   ```

5. **Visit**: http://localhost:3000

## Image Generator Configuration

The app uses a pluggable image generator system. To switch generators, set the `IMAGE_GENERATOR` environment variable:

- `placeholder` - Simple placeholder images (for development/testing)
- `dalle3` - DALL-E 3 via OpenAI API (requires `OPENAI_API_KEY`)
- `midjourney` - Midjourney via third-party service (requires configuration)
- `stability` - Stability AI Stable Diffusion (requires `STABILITY_API_KEY`)

## Project Structure

```
dream_weaver/
├── app/
│   ├── controllers/
│   │   └── game_controller.rb      # Main game logic
│   ├── models/
│   │   └── story.rb                 # Story loader
│   ├── services/
│   │   ├── image_generator_base.rb  # Base class for generators
│   │   ├── image_generator_factory.rb # Factory to create generators
│   │   ├── dalle3_image_generator.rb
│   │   ├── midjourney_image_generator.rb
│   │   ├── stability_image_generator.rb
│   │   ├── placeholder_image_generator.rb
│   │   └── chatgpt_service.rb       # ChatGPT integration
│   └── views/
│       └── game/
│           └── show.html.erb        # Main game view
├── db/
│   └── stories/
│       └── default_story.json      # Story definition
└── storage/
    └── images/
        └── generated/              # Cached AI images
```

## Adding a New Image Generator

1. Create a new class in `app/services/` that inherits from `ImageGeneratorBase`
2. Implement the `call_api(prompt)` method
3. Optionally override `save_image` if needed
4. Add the new generator to `ImageGeneratorFactory`
5. Update `config/application.rb` if needed

Example:
```ruby
class MyImageGenerator < ImageGeneratorBase
  protected
  
  def call_api(prompt)
    # Your API call here
    # Return image data (URL, base64, or binary)
  end
end
```

## Story Format

Stories are defined in JSON files in `db/stories/`. Each scene has:
- `id`: Unique scene identifier
- `narrative_text`: The story text displayed to the player
- `image_prompt`: Prompt sent to the image generator
- `choices`: Array of choices with `text` and `next_scene`

## Development

- Start with `IMAGE_GENERATOR=placeholder` for testing without API costs
- Images are cached in `storage/images/generated/` to avoid regenerating
- Story state is managed via Rails sessions

## License

MIT
