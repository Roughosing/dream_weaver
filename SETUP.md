# Quick Setup Guide

## Initial Setup

1. **Install Ruby dependencies**:
   ```bash
   bundle install
   ```

2. **Set up environment variables**:
   ```bash
   cp env.example .env
   # Then edit .env and add your API keys
   ```

3. **Create necessary directories** (should already exist, but just in case):
   ```bash
   mkdir -p public/images/generated
   ```

4. **Start the Rails server**:
   ```bash
   rails server
   ```

5. **Visit**: http://localhost:3000

## Testing Without API Keys

The app defaults to `placeholder` image generator, which creates simple SVG placeholders. This lets you test the game flow without any API costs.

To use placeholder mode, make sure your `.env` has:
```
IMAGE_GENERATOR=placeholder
```

To use Gemini (default), make sure your `.env` has:
```
IMAGE_GENERATOR=gemini
GEMINI_API_KEY=your_gemini_api_key_here
```

## Switching Image Generators

Edit your `.env` file and change `IMAGE_GENERATOR`:

- `placeholder` - No API needed, creates SVG placeholders
- `gemini` - Requires `GEMINI_API_KEY` (Google Gemini + Nanobanana) - **Default**
- `dalle3` - Requires `OPENAI_API_KEY`
- `stability` - Requires `STABILITY_API_KEY`
- `midjourney` - Requires configuration (see MidjourneyImageGenerator)

## Project Structure Overview

```
app/
├── controllers/
│   └── game_controller.rb      # Handles game state and navigation
├── models/
│   └── story.rb                 # Story loader/parser
├── services/
│   ├── image_generator_base.rb  # Base class for all generators
│   ├── image_generator_factory.rb # Creates the right generator
│   ├── dalle3_image_generator.rb
│   ├── midjourney_image_generator.rb
│   ├── stability_image_generator.rb
│   ├── placeholder_image_generator.rb
│   └── chatgpt_service.rb       # ChatGPT integration
└── views/
    └── game/
        └── show.html.erb        # Main game UI

db/stories/
└── default_story.json          # Your branching narrative

public/images/generated/        # Cached AI images
```

## How the Pluggable System Works

1. **ImageGeneratorBase**: Base class that handles caching and file management
2. **Specific Generators**: Inherit from base and implement `call_api(prompt)`
3. **Factory Pattern**: `ImageGeneratorFactory.create` returns the right generator based on config
4. **Easy to Add**: Just create a new class inheriting from `ImageGeneratorBase` and add it to the factory

## Next Steps

- Add your OpenAI API key to use DALL-E 3
- Customize the story in `db/stories/default_story.json`
- Integrate ChatGPT service for dynamic narrative generation
- Add more image generators as needed
