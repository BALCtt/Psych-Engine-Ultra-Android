package states.ultramenus.v2;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxGradient;
import states.MusicBeatState;

class ExtrasMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;
	
	var menuItems:Array<String> = [
		'gallery',
		'jukebox', 
		'cutscenes',
		'cheats',
		'awards',
		'statistics'
	];
	
	var menuTitles:Array<String> = [
		'GALERİ',
		'JUKEBOX',
		'CUTSCENES', 
		'CHEATS',
		'AWARDS',
		'İSTATİSTİKLER'
	];
	
	var menuDescriptions:Array<String> = [
		'Concept art ve görseller',
		'Müzikleri dinle',
		'Cutscene\'ları izle',
		'Hile menüsü',
		'Ödüller ve rozetler',
		'Oyun istatistiklerin'
	];
	
	var menuIcons:Array<String> = ['🖼️', '🎵', '🎬', '🎮', '🏆', '📊'];
	
	static final PRIMARY:FlxColor = 0xFF6366F1;
	static final SECONDARY:FlxColor = 0xFF8B5CF6;
	static final ACCENT:FlxColor = 0xFFEC4899;
	static final DARK:FlxColor = 0xFF0F0F23;
	static final CARD_BG:FlxColor = 0x8818182B;
	
	var bg:FlxSprite;
	var bgGrid:flixel.addons.display.FlxBackdrop;
	var headerBar:FlxSprite;
	var titleText:FlxText;
	var backButton:FlxSprite;
	var backText:FlxText;
	
	var menuCards:Array<ExtrasCard> = [];
	var selectionIndicator:FlxSprite;
	
	var selectedSomethin:Bool = false;
	var camFollow:FlxObject;
	var ambientTime:Float = 0;
	
	override function create()
	{
		super.create();
		
		persistentUpdate = persistentDraw = true;
		
		createBackground();
		createHeader();
		createMenuCards();
		createSelectionEffects();
		setupCamera();
		
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
		playIntroAnimation();
	}
	
	function createBackground()
	{
		// Gradient arka plan
		bg = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[DARK, 0xFF1A1A3E, 0xFF16213E, DARK],
			[0, 0.3, 0.7, 1], 1
		);
		add(bg);
		
		// Grid arka plan
		bgGrid = new flixel.addons.display.FlxBackdrop(Paths.image('menu/grid'), 1, 1);
		bgGrid.velocity.set(15, 10);
		bgGrid.alpha = 0.08;
		add(bgGrid);
	}
	
	function createHeader()
	{
		// Header bar
		headerBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0x88000000);
		add(headerBar);
		
		// Başlık
		titleText = new FlxText(30, 20, 0, "EKSTRALAR", 36);
		titleText.setFormat(Paths.font("vcr.ttf"), 36, PRIMARY, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		titleText.borderSize = 3;
		add(titleText);
		
		// Geri butonu
		backButton = new FlxSprite(FlxG.width - 120, 20).makeGraphic(80, 40, 0x44FFFFFF);
		backButton.alpha = 0.6;
		add(backButton);
		
		backText = new FlxText(FlxG.width - 120, 30, 80, "GERİ", 16);
		backText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(backText);
	}
	
	function createMenuCards()
	{
		var cardWidth:Int = 200;
		var cardHeight:Int = 150;
		var cols:Int = 3;
		var rows:Int = 2;
		var spacingX:Int = 30;
		var spacingY:Int = 30;
		var totalWidth:Int = cols * cardWidth + (cols - 1) * spacingX;
		var totalHeight:Int = rows * cardHeight + (rows - 1) * spacingY;
		var startX:Int = Std.int((FlxG.width - totalWidth) / 2);
		var startY:Int = Std.int((FlxG.height - totalHeight) / 2) + 20;
		
		for (i in 0...menuItems.length)
		{
			var col = i % cols;
			var row = Std.int(i / cols);
			var x = startX + col * (cardWidth + spacingX);
			var y = startY + row * (cardHeight + spacingY);
			
			var card = new ExtrasCard(x, y, cardWidth, cardHeight, menuItems[i], menuTitles[i], menuDescriptions[i], menuIcons[i]);
			menuCards.push(card);
			
			add(card.bg);
			add(card.icon);
			add(card.title);
			add(card.desc);
		}
	}
	
	function createSelectionEffects()
	{
		selectionIndicator = new FlxSprite();
		selectionIndicator.makeGraphic(220, 170, 0x22FFFFFF);
		selectionIndicator.alpha = 0;
		add(selectionIndicator);
	}
	
	function setupCamera()
	{
		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		camFollow.screenCenter();
		FlxG.camera.follow(camFollow, null, 0.1);
	}
	
	function playIntroAnimation()
	{
		headerBar.y = -80;
		FlxTween.tween(headerBar, {y: 0}, 0.6, {ease: FlxEase.backOut});
		
		titleText.x = -100;
		FlxTween.tween(titleText, {x: 30}, 0.7, {ease: FlxEase.backOut, startDelay: 0.1});
		
		backButton.x = FlxG.width + 100;
		FlxTween.tween(backButton, {x: FlxG.width - 120}, 0.5, {ease: FlxEase.backOut, startDelay: 0.2});
		backText.x = FlxG.width + 100;
		FlxTween.tween(backText, {x: FlxG.width - 120}, 0.5, {ease: FlxEase.backOut, startDelay: 0.2});
		
		for (i in 0...menuCards.length)
		{
			var card = menuCards[i];
			card.bg.alpha = 0;
			card.bg.scale.set(0.8, 0.8);
			
			FlxTween.tween(card.bg, {alpha: 0.8, "scale.x": 1, "scale.y": 1}, 0.5, {
				ease: FlxEase.backOut,
				startDelay: 0.3 + i * 0.08
			});
			
			FlxTween.tween(card.icon, {alpha: 1}, 0.4, {startDelay: 0.4 + i * 0.08});
			FlxTween.tween(card.title, {alpha: 1}, 0.4, {startDelay: 0.5 + i * 0.08});
			FlxTween.tween(card.desc, {alpha: 0.7}, 0.4, {startDelay: 0.6 + i * 0.08});
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		ambientTime += elapsed;
		
		// Grid hareketi
		bgGrid.x -= 15 * elapsed;
		bgGrid.y -= 10 * elapsed;
		
		// Title nefes
		var breathe = 1 + Math.sin(ambientTime * 1.5) * 0.02;
		titleText.scale.set(breathe, breathe);
		
		updateCardInteractions();
		updateSelectionEffects();
		
		if (!selectedSomethin)
		{
			handleInput();
		}
	}
	
	function updateCardInteractions()
	{
		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		
		for (i in 0...menuCards.length)
		{
			var card = menuCards[i];
			var isHovering = mouseX >= card.bg.x && mouseX <= card.bg.x + card.bg.width &&
							mouseY >= card.bg.y && mouseY <= card.bg.y + card.bg.height;
			
			var targetAlpha:Float = 0.8;
			var targetScale:Float = 1;
			var targetColor:FlxColor = FlxColor.WHITE;
			
			if (i == curSelected)
			{
				targetAlpha = 1;
				targetScale = 1.08;
				targetColor = PRIMARY;
			}
			else if (isHovering)
			{
				targetAlpha = 0.9;
				targetScale = 1.04;
				targetColor = SECONDARY;
			}
			else
			{
				targetAlpha = 0.6;
				targetScale = 0.95;
				targetColor = FlxColor.WHITE;
			}
			
			card.bg.alpha = FlxMath.lerp(card.bg.alpha, targetAlpha, 0.15);
			card.bg.scale.set(
				FlxMath.lerp(card.bg.scale.x, targetScale, 0.15),
				FlxMath.lerp(card.bg.scale.y, targetScale, 0.15)
			);
			
			card.title.color = FlxMath.lerpColor(card.title.color, targetColor, 0.15);
			
			// Mouse hover seçimi
			if (isHovering && FlxG.mouse.justPressed && curSelected != i)
			{
				curSelected = i;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
			}
		}
	}
	
	function updateSelectionEffects()
	{
		if (menuCards.length > 0)
		{
			var selectedCard = menuCards[curSelected];
			selectionIndicator.x = selectedCard.bg.x - 10;
			selectionIndicator.y = selectedCard.bg.y - 10;
			selectionIndicator.alpha = 0.3 + Math.sin(ambientTime * 3) * 0.2;
			
			var scale = 1 + Math.sin(ambientTime * 2) * 0.05;
			selectionIndicator.scale.set(scale, scale);
		}
	}
	
	function handleInput()
	{
		if (controls.UI_LEFT_P)
		{
			changeSelection(-1);
		}
		else if (controls.UI_RIGHT_P)
		{
			changeSelection(1);
		}
		else if (controls.UI_UP_P)
		{
			changeSelection(-3);
		}
		else if (controls.UI_DOWN_P)
		{
			changeSelection(3);
		}
		
		if (controls.ACCEPT)
		{
			selectItem();
		}
		
		if (controls.BACK)
		{
			goBack();
		}
		
		// Mouse geri butonu
		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		
		if (mouseX >= backButton.x && mouseX <= backButton.x + backButton.width &&
			mouseY >= backButton.y && mouseY <= backButton.y + backButton.height)
		{
			backButton.alpha = FlxMath.lerp(backButton.alpha, 0.9, 0.2);
			backText.color = FlxMath.lerpColor(backText.color, ACCENT, 0.2);
			
			if (FlxG.mouse.justPressed)
			{
				goBack();
			}
		}
		else
		{
			backButton.alpha = FlxMath.lerp(backButton.alpha, 0.6, 0.2);
			backText.color = FlxMath.lerpColor(backText.color, FlxColor.WHITE, 0.2);
		}
	}
	
	function changeSelection(change:Int)
	{
		curSelected += change;
		
		if (curSelected >= menuCards.length) curSelected = 0;
		if (curSelected < 0) curSelected = menuCards.length - 1;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	
	function selectItem()
	{
		if (selectedSomethin) return;
		
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		var selectedCard = menuCards[curSelected];
		
		// Seçim animasyonu
		FlxTween.tween(selectedCard.bg, {"scale.x": 1.2, "scale.y": 1.2}, 0.3, {ease: FlxEase.backIn});
		FlxTween.tween(selectedCard.bg, {alpha: 0}, 0.3, {ease: FlxEase.backIn});
		
		// Diğer kartları gizle
		for (i in 0...menuCards.length)
		{
			if (i != curSelected)
			{
				var card = menuCards[i];
				FlxTween.tween(card.bg, {alpha: 0}, 0.3, {startDelay: i * 0.05});
				FlxTween.tween(card.icon, {alpha: 0}, 0.3, {startDelay: i * 0.05});
				FlxTween.tween(card.title, {alpha: 0}, 0.3, {startDelay: i * 0.05});
				FlxTween.tween(card.desc, {alpha: 0}, 0.3, {startDelay: i * 0.05});
			}
		}
		
		// Navigate after animation
		FlxTween.tween(FlxG.camera, {alpha: 0}, 0.5, {
			onComplete: function(t:FlxTween) {
				navigateToOption(menuItems[curSelected]);
			}
		});
	}
	
	function navigateToOption(option:String)
	{
		switch (option)
		{
			case 'gallery':
				// Gallery menüsüne git
				trace("Gallery açılıyor...");
			case 'jukebox':
				// Jukebox menüsüne git
				trace("Jukebox açılıyor...");
			case 'cutscenes':
				// Cutscenes menüsüne git
				trace("Cutscenes açılıyor...");
			case 'cheats':
				// Cheats menüsüne git
				trace("Cheats açılıyor...");
			case 'awards':
				// Awards menüsüne git
				trace("Awards açılıyor...");
			case 'statistics':
				// Statistics menüsüne git
				trace("Statistics açılıyor...");
			default:
				trace('Bilinmeyen ekstra: $option');
		}
	}
	
	function goBack()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		
		FlxTween.tween(FlxG.camera, {alpha: 0}, 0.3, {
			onComplete: function(t:FlxTween) {
				MusicBeatState.switchState(new MainMenuV2());
			}
		});
	}
	
	override function beatHit()
	{
		super.beatHit();
		
		// Title beat bump
		FlxTween.cancelTweensOf(titleText.scale);
		titleText.scale.set(1.06, 1.06);
		FlxTween.tween(titleText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});
		
		// Selected card beat
		if (menuCards.length > 0)
		{
			var selectedCard = menuCards[curSelected];
			FlxTween.cancelTweensOf(selectedCard.bg.scale);
			selectedCard.bg.scale.set(1.12, 1.12);
			FlxTween.tween(selectedCard.bg.scale, {x: 1.08, y: 1.08}, 0.4, {ease: FlxEase.quadOut});
		}
	}
}

class ExtrasCard
{
	public var bg:FlxSprite;
	public var icon:FlxText;
	public var title:FlxText;
	public var desc:FlxText;
	
	public function new(x:Float, y:Float, width:Int, height:Int, option:String, title:String, desc:String, iconStr:String)
	{
		// Kart arka planı
		bg = new FlxSprite(x, y);
		bg.makeGraphic(width, height, 0x8818182B);
		bg.updateHitbox();
		
		// İkon
		icon = new FlxText(x + 10, y + 10, width - 20, iconStr, 36);
		icon.setFormat(null, 36, FlxColor.WHITE, CENTER);
		icon.alpha = 0;
		
		// Başlık
		title = new FlxText(x + 15, y + height - 50, width - 30, title, 16);
		title.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		title.borderSize = 1;
		title.alpha = 0;
		
		// Açıklama
		desc = new FlxText(x + 15, y + height - 30, width - 30, desc, 12);
		desc.setFormat(Paths.font("vcr.ttf"), 12, 0xFFCCCCCC, CENTER);
		desc.alpha = 0;
	}
}
