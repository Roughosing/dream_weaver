# Changes Summary - Story & Image Isolation

## 🎯 Issues Fixed

### 1. ✅ Images Now Story-Specific
**Problem:** Images were being reused across different stories
**Solution:** Each story now has its own unique image cache

### 2. ✅ Minimum 2-3 Choices Per Scene
**Problem:** Some generated scenes had only 1 choice
**Solution:** Updated AI prompts to enforce 2-3 choices per non-ending scene

## 📝 Technical Changes

### Image Caching (Story-Specific)

**Before:**
```ruby
# Images cached by scene_id only
image_generator.generate(scene['image_prompt'], scene['id'])
# Result: "SCENE_1.png" - shared across all stories
```

**After:**
```ruby
# Images cached by story_id + scene_id
story_id = session[:story_id] || 'default'
cache_key = "#{story_id}_#{scene['id']}"
image_generator.generate(scene['image_prompt'], cache_key)
# Result: "abc123_SCENE_1.png" - unique per story
```

### Behavior Now:
- ✅ **New Story** = Fresh images generated
- ✅ **Same Story Replay** = Images reused (faster)
- ✅ **Different Story** = Different images
- ✅ **Old Story Cleanup** = Images deleted when creating new story

### Story Generation Prompts

**Updated `lib/game_generator.rb`:**

```
**CRITICAL CHOICE RULES:**
* **MINIMUM CHOICES:** Every non-ending scene MUST have at least 2 choices (A and B are REQUIRED).
* **PREFERRED CHOICES:** Most scenes should have 3 choices (A, B, and C). This gives players meaningful agency.
* **MAXIMUM CHOICES:** Up to 4 choices (A, B, C, D) for complex decision points.
* **Ending Scenes ONLY:** Only ending scenes should have ZERO choices (empty choices array).
* **Never create scenes with only 1 choice** - this removes player agency and breaks immersion.
```

### Automatic Cleanup

**When Creating New Story:**
1. Old story data deleted from cache
2. All old story images removed from disk
3. Fresh story_id generated
4. New images will have unique filenames

**When Playing Same Story Again:**
- Click "Play Again" = Uses cached story + cached images
- Click "Create New Story" = Cleans up old story, generates new one

## 🎮 User Experience

### Scenario 1: Generate Story A
```
User: "A space pirate adventure"
→ Story ID: abc123
→ Images: abc123_scene1.png, abc123_scene2.png, etc.
→ Each scene: 2-3 choices
```

### Scenario 2: Play Story A Again
```
User: Clicks "Play Again"
→ Uses same Story ID: abc123
→ Images load instantly (cached)
→ Same choices as before
```

### Scenario 3: Generate Story B
```
User: Clicks "Create New Story"
→ Old story (abc123) deleted
→ Old images (abc123_*.png) deleted
→ New Story ID: def456
→ New images: def456_scene1.png, def456_scene2.png
→ Each scene: 2-3 fresh choices
```

## 📁 Files Modified

1. **`app/controllers/game_controller.rb`**
   - Added `story_id` to image cache keys
   - Added `cleanup_story_images()` method
   - Images now isolated per story

2. **`app/controllers/story_generator_controller.rb`**
   - Added `cleanup_old_story()` method
   - Cleans up previous story before generating new one

3. **`lib/game_generator.rb`**
   - Enhanced SYSTEM_PROMPT with choice requirements
   - Enforces minimum 2 choices, prefers 3 choices
   - Only endings can have 0 choices

## 🧪 Testing

To verify the changes work:

1. **Generate Story A:**
   - Enter prompt: "A cyberpunk detective story"
   - Verify each scene has 2-3 choices
   - Check `public/images/generated/` for images like `abc123_scene1.png`

2. **Generate Story B:**
   - Click "Create New Story"
   - Enter new prompt: "A medieval fantasy adventure"
   - Verify old images are deleted
   - Check new images like `def456_scene1.png`

3. **Replay Story B:**
   - Click "Play Again"
   - Verify images load instantly (cached)
   - Same story, same images

## 📊 Storage Benefits

**Before:**
- All stories shared same image cache
- Could not distinguish between stories
- No cleanup = disk fills up over time

**After:**
- Each story has unique images
- Automatic cleanup when creating new story
- Only current story's images kept on disk
- Clear separation between different adventures

## 🚀 Ready to Test!

Restart your Rails server for these changes to take effect:

```bash
# Stop server (Ctrl+C)
cd /Users/gregpenrose/Desktop/ShyppleInnovationDays/dream_weaver
rails s
```

Then try:
1. Generate a story
2. Play through and note the choices (should be 2-3 per scene)
3. Click "Create New Story"
4. Generate a different story
5. Verify the images are completely different!

---

**Changes implemented:** November 19, 2025
**All changes are backward compatible** ✅

