package objects;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import backend.animation.PsychAnimationController;

/**
 * Enhanced FlameStreak - Animated flame with responsive scaling, combo display smooth animations
 * Milestones: 50, 100, 250, 500
 */
class FlameStreak extends FlxSprite
{
	private var flameSprite:FlxSprite;
	private var comboBg:FlxSprite;
	private var comboNumbers:Array<FlxSprite>;
	
	public var currentCombo:Int = 0;
	public var currentTier:Int = 0;
	private var previousTier:Int = 0;
	public var isActive:Bool = false;
	
	private var colorTween:FlxTween;
	private var entranceTween:FlxTween;
	private var exitTween:FlxTween;
	private var numberTween:FlxTween;
	
	private var baseScale:Float = 1.0;
	private var displayedCombo:Int = 0;
	
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		
		animation = new PsychAnimationController(this);
		loadGraphic(null);
		
		flameSprite = new FlxSprite(x, y);
		flameSprite.animation = new PsychAnimationController(flameSprite);
		flameSprite.alpha = 0;
		
		comboBg = new FlxSprite(x, y + 60);
		comboBg.alpha = 0;
		
		comboNumbers = [];
		
		calculateScale();
		
		currentCombo = 0;
		currentTier = 0;
		previousTier = 0;
		displayedCombo = 0;
	}
	
	/**
	 * Add child sprites to a group (call from PlayState)
	 */
	public function setChildrenGroup(group:flixel.group.FlxSpriteGroup):Void
	{
		if (flameSprite != null) group.add(flameSprite);
		if (comboBg != null) group.add(comboBg);
		for (num in comboNumbers)
		{
			if (num != null) group.add(num);
		}
	}
	
	private function calculateScale():Void
	{
		baseScale = FlxG.width / 1280.0 * 0.8;
		baseScale = Math.max(0.5, Math.min(2.0, baseScale));
	}
	
	private function getTierFromCombo(combo:Int):Int
	{
		if (combo >= 500) return 4;
		if (combo >= 250) return 3;
		if (combo >= 100) return 2;
		if (combo >= 50) return 1;
		return 0;
	}
	
	private function loadFlameTier(tier:Int):Void
	{
		if (tier < 1 || tier > 4) 
		{
			clearFlame();
			return;
		}
		
		var tierNames:Array<String> = ['yellow', 'red', 'teal', 'purple'];
		var tierName:String = tierNames[tier - 1];
		var imagePath:String = 'hud/flame/flame_$tierName';
		
		try 
		{
			flameSprite.frames = Paths.getSparrowAtlas(imagePath);
			if (flameSprite.frames == null) throw "Failed to load atlas";
			
			flameSprite.animation.destroyAnimations();
			
			var frameIndices:Array<Int> = [];
			if (flameSprite.frames != null && flameSprite.frames.numFrames > 0)
			{
				for (i in 0...flameSprite.frames.numFrames)
					frameIndices.push(i);
			}
			
			if (frameIndices.length > 0)
			{
				flameSprite.animation.add('flame', frameIndices, 12, true);
				flameSprite.animation.play('flame', true);
				// Make flame much smaller (0.25 because source images are 2000x2000)
				flameSprite.scale.set(baseScale * 0.25, baseScale * 0.25);
				flameSprite.updateHitbox();
				isActive = true;
			}
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('Failed to load flame tier $tier: $imagePath - $e');
			if (tier != 1)
			{
				loadFlameTier(1);
				return;
			}
			clearFlame();
		}
	}
	
	private function loadComboDisplay():Void
	{
		try 
		{
			comboBg.loadGraphic(Paths.image('combo'));
			comboBg.scale.set(baseScale, baseScale);
			comboBg.updateHitbox();
			updateComboNumbers();
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('Failed to load combo: $e');
		}
	}
	
	private function updateComboNumbers():Void
	{
		// Clear old numbers
		for (num in comboNumbers)
			num.destroy();
		comboNumbers = [];
		
		var numStr:String = Std.string(displayedCombo);
		var startX:Float = comboBg.x + 30;
		
		for (i in 0...numStr.length)
		{
			var digit:String = numStr.charAt(i);
			var numSprite:FlxSprite = new FlxSprite(startX + (i * 40 * baseScale), comboBg.y - 65);
			
			try
			{
				// Try num0.png format first (vanilla game), fallback to 0.png (mods)
				var graphic = Paths.image('num$digit');
				if (graphic == null)
					graphic = Paths.image(digit);
				
				if (graphic == null)
					throw "Could not load digit $digit";
				
				numSprite.loadGraphic(graphic);
				numSprite.scale.set(baseScale * 0.6, baseScale * 0.6);
				numSprite.updateHitbox();
				comboNumbers.push(numSprite);
			}
			catch (e:Dynamic)
			{
				FlxG.log.warn('Failed to load digit $digit: $e');
			}
		}
	}
	
	public function updateCombo(newCombo:Int):Void
	{
		currentCombo = Std.int(Math.max(0, newCombo));
		var newTier:Int = getTierFromCombo(currentCombo);
		
		if (newTier != currentTier)
		{
			currentTier = newTier;
			
			if (newTier == 0)
			{
				hideFlame();
			}
			else
			{
				if (currentTier != previousTier && previousTier > 0)
				{
					playTierUpAnimation();
				}
				else if (!isActive)
				{
					showFlame();
					displayedCombo = currentCombo;
					updateComboNumbers();
				}
				
				previousTier = newTier;
			}
		}
	}
	
	private function showFlame():Void
	{
		if (isActive) return;
		
		loadFlameTier(currentTier);
		loadComboDisplay();
		
		if (!isActive) return;
		
		visible = !ClientPrefs.data.hideHud;
		
		if (entranceTween != null) entranceTween.cancel();
		
		flameSprite.x -= 200;
		flameSprite.alpha = 0;
		comboBg.alpha = 0;
		
		entranceTween = FlxTween.tween(flameSprite, { x: flameSprite.x + 200, alpha: 0.8 }, 0.4,
		{
			ease: flixel.tweens.FlxEase.backOut,
			onUpdate: function(tween:FlxTween)
			{
				comboBg.alpha = flameSprite.alpha * 0.7;
			}
		});
	}
	
	public function hideFlame():Void
	{
		if (!isActive) return;
		
		isActive = false;
		flameSprite.animation.stop();
		
		if (exitTween != null) exitTween.cancel();
		
		exitTween = FlxTween.tween(flameSprite, { alpha: 0 }, 0.3,
		{
			ease: flixel.tweens.FlxEase.quadIn,
			onUpdate: function(tween:FlxTween)
			{
				comboBg.alpha = flameSprite.alpha * 0.7;
			},
			onComplete: function(tween:FlxTween)
			{
				clearFlame();
			}
		});
		
		currentTier = 0;
		previousTier = 0;
	}
	
	private function playTierUpAnimation():Void
	{
		if (!isActive) return;
		
		// Load new sprite directly (no color tween, no freeze)
		loadFlameTier(currentTier);
		
		FlxG.sound.play(Paths.sound('flame_level_up'), 0.7);
		
		// Pulse effect
		var originalAlpha:Float = flameSprite.alpha;
		FlxTween.tween(flameSprite, { alpha: 1.0 }, 0.1,
		{
			onComplete: function(tween:FlxTween)
			{
				FlxTween.tween(flameSprite, { alpha: originalAlpha }, 0.1);
			}
		});
		
		animateComboNumber();
	}
	
	private function animateComboNumber():Void
	{
		if (numberTween != null) numberTween.cancel();
		
		var oldCombo:Int = displayedCombo;
		var comboObj:{ value: Float } = { value: 0 };
		
		numberTween = FlxTween.tween(comboObj, { value: 1 }, 0.5,
		{
			ease: flixel.tweens.FlxEase.quadInOut,
			onUpdate: function(tween:FlxTween)
			{
				displayedCombo = Std.int(oldCombo + (currentCombo - oldCombo) * comboObj.value);
				updateComboNumbers();
			},
			onComplete: function(tween:FlxTween)
			{
				displayedCombo = currentCombo;
				updateComboNumbers();
				numberTween = null;
			}
		});
	}
	
	private function clearFlame():Void
	{
		flameSprite.animation.stop();
		comboBg.loadGraphic(null);
		for (num in comboNumbers)
			num.destroy();
		comboNumbers = [];
		flameSprite.alpha = 0;
		comboBg.alpha = 0;
		isActive = false;
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (isActive && flameSprite.animation != null)
		{
			if (flameSprite.animation.curAnim == null || flameSprite.animation.curAnim.name != 'flame')
			{
				flameSprite.animation.play('flame', true);
			}
		}
	}
	
	override public function destroy():Void
	{
		if (colorTween != null) colorTween.cancel();
		if (entranceTween != null) entranceTween.cancel();
		if (exitTween != null) exitTween.cancel();
		if (numberTween != null) numberTween.cancel();
		
		super.destroy();
	}
}
