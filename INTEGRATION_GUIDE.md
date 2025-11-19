# Dream Weaver Integration Guide

## Overview
This guide explains the integration of AI story generation with AI image generation in Dream Weaver.

## System Architecture

### Flow Diagram
```
User Prompt → Gemini Story Generator → JSON Story Structure → Game Controller → Scene Renderer → Gemini Image Generator → Display
```

### Components

#### 1. **Story Generation** (`lib/game_generator.rb`)
- Uses Gemini 2.5 Pro API
- Takes a natural language prompt
- Generates complete game with 20+ scenes
- Outputs structured JSON matching our game format

**Key Features:**
- Automatic plot structure
- Multiple endings (2-4)
- Consistent art style across all scenes
- Built-in narrative quality controls

#### 2. **Story Generator Controller** (`app/controllers/story_generator_controller.rb`)
- Handles user prompt input
- Calls `TextBasedGame::Generator`
- Stores generated story in session
- Manages errors gracefully

#### 3. **Game Controller** (Updated `app/controllers/game_controller.rb`)
- Now handles both:
  - Generated stories (from session)
  - Static stories (from JSON files)
- Automatically switches between sources
- Maintains session state across both types

#### 4. **Image Generation** (Existing `app/services/gemini_image_generator.rb`)
- Takes `image_prompt` from each scene
- Enhances prompt with Gemini text model
- Generates 16:9 cinematic images
- Falls back to Pollinations if needed
- Caches images to avoid regeneration

## User Flow

### Step 1: Story Creation
1. User lands on `/` (story generator)
2. Enters a prompt like: "A cyberpunk detective story in Neo-Tokyo"
3. Clicks "Generate My Adventure"
4. System generates complete story (30-60 seconds)

### Step 2: Gameplay
1. Game loads first scene
2. Image generates based on scene's `image_prompt`
3. User reads narrative and makes choices
4. Each choice leads to new scene with new image
5. Process continues until reaching an ending

### Step 3: Replay
- **Play Again**: Restart same story from beginning
- **Create New Story**: Generate a completely new adventure

## API Integration

### Gemini API Usage

**Story Generation:**
```ruby
TextBasedGame::Generator.new.generate(user_prompt)
```
- **Model**: `gemini-2.5-pro`
- **Temperature**: 0.5 (balanced creativity/consistency)
- **Response**: Structured JSON with schema validation
- **Timeout**: 120 seconds

**Image Generation:**
```ruby
GeminiImageGenerator.new.generate(image_prompt, scene_id)
```
- **Model**: `gemini-2.5-flash-image-preview` (Nanobanana)
- **Format**: 16:9 cinematic PNG
- **Enhancement**: Prompt improved via Gemini text model first
- **Fallback**: Pollinations AI (1920×1080)

## Environment Variables

Required in `.env`:
```bash
GEMINI_API_KEY=your_gemini_api_key_here
IMAGE_GENERATOR=gemini  # or dalle3, midjourney, stability, placeholder
```

## File Structure

```
dream_weaver/
├── lib/
│   └── game_generator.rb              # Story generation logic
├── app/
│   ├── controllers/
│   │   ├── story_generator_controller.rb  # Prompt handling
│   │   └── game_controller.rb             # Game play logic
│   ├── services/
│   │   ├── gemini_image_generator.rb      # Image generation
│   │   ├── image_generator_base.rb        # Base class
│   │   └── image_generator_factory.rb     # Factory pattern
│   └── views/
│       ├── story_generator/
│       │   └── new.html.erb               # Prompt input UI
│       └── game/
│           └── show.html.erb              # Game play UI
└── db/
    └── stories/
        └── default_story.json             # Fallback static story
```

## Session Management

**Session Variables:**
- `session[:generated_story]` - Full story JSON from generator
- `session[:current_scene_id]` - Current scene identifier
- `session[:choices_made]` - History of player choices

## Image Caching

Generated images are cached in:
```
public/images/generated/{scene_id}.png
```

**Benefits:**
- Faster page loads on revisiting scenes
- Reduced API costs
- Consistent visuals across playthroughs

## Error Handling

### Story Generation Failures
- Timeout (>120s): User-friendly error message
- Invalid API key: Flash error, stay on prompt page
- Malformed JSON: Logged, user redirected with error

### Image Generation Failures
- Gemini unavailable: Automatic fallback to Pollinations
- Both failed: Display placeholder with scene text
- Invalid scene: Auto-reset to start scene

## Performance Considerations

**Story Generation:**
- Average time: 30-60 seconds
- Cached in session (no regeneration needed)
- One API call per story

**Image Generation:**
- First visit: ~10-15 seconds per scene
- Subsequent visits: Instant (cached)
- 20+ images per complete playthrough

## Testing the Integration

### Manual Test Flow:
1. Start server: `rails s`
2. Visit `http://localhost:3000`
3. Enter prompt: "A space pirate adventure"
4. Wait for generation
5. Verify first scene loads with image
6. Make choices, verify new scenes generate images
7. Reach ending, test both restart options

### Check Logs:
```bash
tail -f log/development.log
```

Look for:
- "Generating story from prompt: ..."
- "Story generated successfully: ..."
- "Using generated story: ..."
- "Gemini generated inline image data"

## Troubleshooting

### Story won't generate
- Check `GEMINI_API_KEY` is set
- Verify API key has access to `gemini-2.5-pro`
- Check timeout settings (increase if needed)

### Images not showing
- Check `GEMINI_API_KEY` is set
- Verify `IMAGE_GENERATOR=gemini` in `.env`
- Check `public/images/generated/` directory exists
- Review logs for API errors

### Old story stuck in session
- Clear browser cookies
- Restart Rails server
- Or visit `/generate` directly

## Future Enhancements

- [ ] Save generated stories to database
- [ ] User accounts for story history
- [ ] Share generated stories with others
- [ ] Custom art style selection
- [ ] Real-time streaming of story generation
- [ ] Multiple language support
- [ ] Voice narration
- [ ] Music generation per scene

## Credits

- **Gemini 2.5 Pro**: Story generation
- **Gemini 2.5 Flash Image (Nanobanana)**: Primary image generation
- **Pollinations AI**: Fallback image generation
- **Ruby on Rails 7**: Web framework

