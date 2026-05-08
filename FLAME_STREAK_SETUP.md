# Flame Streak System - Spritesheet & Asset Guide

## Quick Setup

The Flame Streak system is now integrated into PlayState and ready to use! You just need to create the visual assets.

---

## Required Assets

### 1. **Flame Spritesheets** (4 PNG files)
Location: `assets/shared/images/hud/flame/`

Create the following 4 files:
- `flame_yellow.png` — Orange-Yellow flames (100-199 combo)
- `flame_red.png` — Red flames (200-299 combo)
- `flame_teal.png` — Green-Teal flames (300-399 combo)
- `flame_pink.png` — Pink flames (400+ combo)

### 2. **Tier-Up Sound Effect**
Location: `assets/shared/sounds/notifications/`

Create or place:
- `flame_level_up.ogg` — Sound that plays when advancing to a new tier
- Alternative: `flame_level_up.mp3` for web compatibility

---

## Spritesheet Format Specifications

### **Recommended: Horizontal Strip Layout** (Simplest)

Each spritesheet should be a single PNG with animation frames arranged horizontally in a single row.

**Specifications:**
- **Frame Size:** 128×128 pixels per frame (or 96×96 - adjust in FlameStreak.hx line 77 if needed)
- **Frame Count:** 8-12 frames recommended for smooth looping
- **Image Dimensions:** 
  - For 10 frames at 128×128: 1280×128 pixels total
  - For 12 frames at 128×128: 1536×128 pixels total
  - For 8 frames at 96×96: 768×96 pixels total

**Example Layout (10 frames, 128×128 each):**
```
[Frame1] [Frame2] [Frame3] [Frame4] [Frame5] [Frame6] [Frame7] [Frame8] [Frame9] [Frame10]
         ←─ 1280px ─→
```

### **Alternative: Vertical Strip Layout**

If you prefer frames stacked vertically:

**Specifications:**
- Frame size stays the same (128×128 or 96×96)
- Image dimensions: 128×1280 for 10 frames (horizontal width × number of frames)
- Would require code modification in FlameStreak.hx

*Note: Current implementation expects horizontal layout. To use vertical, modify line 77 in FlameStreak.hx and frame calculation logic.*

---

## How to Create the Spritesheets

### **Option A: Hand-drawn / Pixel Art** (Best for engine visuals)

1. **Design the flame:**
   - Create a flame sprite appropriate for your game's art style
   - Size: 128×128 pixels (or 96×96) per frame
   - Consider the flame should be semi-transparent or have glow effects

2. **Animate (8-12 frames):**
   - Frame 1: Flame starting position (small/low)
   - Frames 2-11: Flame growing/flickering/dancing animation
   - Frame 12: Flame at peak (loops back to frame 1)
   - Example: Flame expands upward, flickers, shrinks slightly, repeats

3. **Color variations (4 files):**
   - `flame_yellow.png` — Orange-yellow hue
   - `flame_red.png` — Red hue
   - `flame_teal.png` — Green-teal/cyan hue
   - `flame_pink.png` — Magenta/pink hue
   - *Tip: Use color overlay/multiply blending in your art tool to recolor*

4. **Export:**
   - Format: PNG with transparency
   - Resolution: 128×1280 (or appropriate for your frame/size combo)
   - No compression artifacts (use lossless)

### **Option B: Using Image Editing Software** (Photoshop, GIMP, Krita)

**Steps:**
1. Create new document: 1280×128 px (for 10 frames at 128×128)
2. Create your flame animation:
   - Layer 1: Frame 1 image (paste at x=0)
   - Layer 2: Frame 2 image (paste at x=128)
   - Layer 3: Frame 3 image (paste at x=256)
   - ... and so on for all frames
3. Use "Export as PNG" and save to `assets/shared/images/hud/flame/flame_yellow.png`
4. For color variations:
   - Duplicate the file
   - Use Color Balance, Hue/Saturation, or overlay layers to change color
   - Save as separate files (red, teal, pink versions)

### **Option C: Using Online Tools / Generators**

- **Aseprite** (paid, but excellent for pixel animation)
- **LibreSprite** (free, Aseprite fork)
- **Krita** (free, good animation support)
- **Piskel** (online pixel art tool)

*Steps same as Option B above*

### **Option D: AI/Generated Assets**

You could also generate flame animations using:
- Midjourney/DALL-E prompts: "pixel art flame animation, 10 frames, orange"
- Stable Diffusion with controlnet
- Then stitch frames together as described above

---

## Custom Frame Size (If Not Using 128×128)

If you want different frame dimensions, modify **line 77** in [source/objects/FlameStreak.hx](source/objects/FlameStreak.hx):

**Current (128×128):**
```haxe
var frameSize:Int = 128;
```

**Change to your size:**
```haxe
var frameSize:Int = 96;  // For 96×96 frames
```

---

## Sound Effect Asset

### **For the tier-up sound:**

Create or source a short **notification sound** (0.2-0.5 seconds):
- Characteristics: Satisfying "level up" / "achievement" sound
- File format: `.ogg` (native) or `.mp3` (web)
- Location: `assets/shared/sounds/notifications/flame_level_up.ogg`

**Examples of sounds to use:**
- "Ding" or "bell" sound
- Electronic "power up" chime
- Sparkle/magic sound effect
- Brief ascending tone

---

## Testing Your Assets

1. **Place the files:**
   ```
   assets/shared/images/hud/flame/
   ├── flame_yellow.png
   ├── flame_red.png
   ├── flame_teal.png
   └── flame_pink.png
   
   assets/shared/sounds/notifications/
   └── flame_level_up.ogg
   ```

2. **Play a song in Freeplay/Story mode**

3. **Chain notes to 100 combo** — Orange flame should appear in top-right

4. **Continue to 200 combo** — Flame should turn red with a "level up" sound

5. **Continue to 300 & 400** — Flame turns teal, then pink

6. **Miss a note** — Flame disappears

7. **Optional: Re-reach 100+** — Flame reappears (no sound on re-entry, only on tier changes)

---

## Troubleshooting

**Flame doesn't appear:**
- Check file paths are exact: `assets/shared/images/hud/flame/flame_yellow.png`
- Verify frame dimensions match code (default 128×128)
- Check image format is PNG and files aren't corrupted

**Sound doesn't play:**
- Verify sound file: `assets/shared/sounds/notifications/flame_level_up.ogg`
- Make sure volume isn't muted in game settings
- Try `.mp3` format if `.ogg` doesn't work

**Animation looks choppy:**
- Increase frame count (add more animation frames)
- Adjust FPS in FlameStreak.hx line 88 (currently 12 FPS)
- Example: Change from `12` to `16` for faster, smoother loops

**Flame is wrong size:**
- Check frame dimensions (default 128×128)
- Modify frameSize variable (line 77) if using different dimensions
- Ensure spritesheet image width = frameSize × frameCount

---

## Advanced: Adjusting Colors & Animation Speed

To fine-tune the tier colors, edit [source/objects/FlameStreak.hx](source/objects/FlameStreak.hx) **lines 110-120:**

**Current colors:**
```haxe
case 1: FlxColor.fromRGB(255, 165, 0);    // Orange-Yellow (100)
case 2: FlxColor.fromRGB(255, 0, 0);      // Red (200)
case 3: FlxColor.fromRGB(0, 255, 200);    // Green-Teal (300)
case 4: FlxColor.fromRGB(255, 0, 255);    // Pink (400+)
```

To change colors, adjust RGB values:
- **RGB(255, 165, 0)** = Orange → Try RGB(255, 200, 0) for more yellow
- **RGB(255, 0, 0)** = Red → Try RGB(200, 0, 0) for darker red
- **RGB(0, 255, 200)** = Teal → Try RGB(0, 200, 255) for more blue
- **RGB(255, 0, 255)** = Pink → Try RGB(255, 100, 200) for lighter pink

To adjust animation speed, edit **line 88:**
```haxe
animation.add('flame', frames, 12, true);  // 12 = FPS (frames per second)
// Change to: animation.add('flame', frames, 16, true);  // 16 FPS = faster
```

---

## Next Steps

1. ✅ Code is integrated and ready
2. 📁 Create the asset folder: `assets/shared/images/hud/flame/`
3. 🎨 Create/design 4 flame spritesheets (yellow, red, teal, pink)
4. 🔊 Create the tier-up sound effect
5. 🎮 Test in-game by reaching combo milestones
6. 🔧 Fine-tune colors, sizes, and timing as desired

**Questions or issues?** Check the troubleshooting section above or review the code in [source/objects/FlameStreak.hx](source/objects/FlameStreak.hx).

Happy modding! 🔥
