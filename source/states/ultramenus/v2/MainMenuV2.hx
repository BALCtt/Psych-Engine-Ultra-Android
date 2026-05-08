package states.ultramenus.v2;

import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import backend.ThemeManager;

class MainMenuV2 extends MusicBeatState
{
	public static var curSelected:Int = 0;
	public static var curCategory:Int = 0;
	
	// Enhanced menu options with new categories
	var categories:Array<Array<String>> = [
		['story_mode', 'freeplay', 'extras'], // Ana Oyun
		['mods', 'achievements', 'gallery'], // İçerik  
		['credits', 'options', 'about']      // Sistem
	];
	
	var categoryNames:Array<String> = ['ANA OYUN', 'İÇERİK', 'SİSTEM'];
	var categoryIcons:Array<String> = ['🎮', '📦', '⚙️'];
	
	var menuTitles:Map<String, String> = [
		'story_mode' => 'HİKAYE MODU',
		'freeplay' => 'SERBEST OYUN', 
		'extras' => 'EKSTRALAR',
		'mods' => 'MODLAR',
		'achievements' => 'BAŞARILAR',
		'gallery' => 'GALERİ',
		'credits' => 'YAPIMCILAR',
		'options' => 'AYARLAR',
		'about' => 'HAKKINDA'
	];
	
	var menuDescriptions:Map<String, String> = [
		'story_mode' => 'Epic hikayede maceraya atıl',
		'freeplay' => 'Tüm şarkıları serbestçe oyna',
		'extras' => 'Gizli içerik ve sürprizler',
		'mods' => 'Özel modları yükle ve oyna',
		'achievements' => 'Başarılarını koleksiyonla',
		'gallery' => 'Sanat galerisini keşfet',
		'credits' => 'Emeği geçenleri gör',
		'options' => 'Oyun ayarlarını özelleştir',
		'about' => 'Psych Engine Ultra hakkında'
	];
	
	var menuIcons:Map<String, String> = [
		'story_mode' => '📖',
		'freeplay' => '🎵',
		'extras' => '✨',
		'mods' => '📦',
		'achievements' => '🏆',
		'gallery' => '🖼️',
		'credits' => '👥',
		'options' => '⚙️',
		'about' => 'ℹ️'
	];
	
	// Modern renk paleti
	static final PRIMARY:FlxColor     = 0xFF6366F1;
	static final SECONDARY:FlxColor   = 0xFF8B5CF6;
	static final ACCENT:FlxColor      = 0xFFEC4899;
	static final SUCCESS:FlxColor     = 0xFF10B981;
	static final WARNING:FlxColor     = 0xFFF59E0B;
	static final DANGER:FlxColor      = 0xFFEF4444;
	static final DARK:FlxColor        = 0xFF0F0F23;
	static final CARD_BG:FlxColor     = 0x8818182B;
	static final HOVER_BG:FlxColor    = 0x44FFFFFF;
	
	// Arka plan sistemleri
	var bgGradient:FlxSprite;
	var bgGrid:FlxBackdrop;
	var bgParticles:Array<DynamicParticle> = [];
	var bgOrbs:Array<FlxSprite> = [];
	var bgLines:Array<FlxSprite> = [];
	
	// UI Elemanları
	var headerBar:FlxSprite;
	var logoText:FlxText;
	var logoSubText:FlxText;
	var versionText:FlxText;
	var timeText:FlxText;
	
	// Kategori sistemi
	var categoryTabs:Array<FlxSprite> = [];
	var categoryTexts:Array<FlxText> = [];
	var categoryIndicator:FlxSprite;
	
	// Menü kartları
	var menuCards:Array<MenuCard> = [];
	var cardContainer:FlxTypedGroup<FlxSprite>;
	
	// Seçim ve efektler
	var selectionRing:FlxSprite;
	var hoverEffect:FlxSprite;
	var transitionOverlay:FlxSprite;
	
	// Sistem değişkenleri
	var selectedSomethin:Bool = false;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var ambientTime:Float = 0;
	var transitionTime:Float = 0;
	var isTransitioning:Bool = false;
	
	// Yeni özellikler
	var quickAccess:Array<FlxSprite> = [];
	var notifications:Array<Notification> = [];
	var searchMode:Bool = false;
	var searchTerm:String = "";
	
	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Psych Engine Ultra - Next Gen", null);
		#end
		
		persistentUpdate = persistentDraw = true;
		super.create();
		
		createBackground();
		createHeader();
		createCategories();
		createMenuCards();
		createSelectionEffects();
		createQuickAccess();
		createNotifications();
		
		setupCamera();
		
		FlxG.camera.fade(FlxColor.BLACK, 0.8, true);
		
		// Başlangıç animasyonları
		playIntroAnimation();
	}
	
	function createBackground()
	{
		// Ana gradient arka plan
		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[DARK, 0xFF1A1A3E, 0xFF16213E, DARK],
			[0, 0.3, 0.7, 1], 1
		);
		add(bgGradient);
		
		// Hareketli grid arka plan
		bgGrid = new FlxBackdrop(Paths.image('menu/grid'), 1, 1);
		bgGrid.velocity.set(10, 10);
		bgGrid.alpha = 0.1;
		add(bgGrid);
		
		// Ambient parçacıklar
		for (i in 0...50)
		{
			var particle = new DynamicParticle();
			particle.randomize();
			bgParticles.push(particle);
			add(particle.sprite);
		}
		
		// Dekoratif orb'ler
		for (i in 0...5)
		{
			var orb = new FlxSprite();
			orb.makeGraphic(200, 200, PRIMARY);
			orb.alpha = 0.05;
			orb.blend = ADD;
			bgOrbs.push(orb);
			add(orb);
		}
		
		// Dekoratif çizgiler
		for (i in 0...3)
		{
			var line = new FlxSprite().makeGraphic(FlxG.width, 2, PRIMARY);
			line.alpha = 0.1;
			bgLines.push(line);
			add(line);
		}
	}
	
	function createHeader()
	{
		// Header bar
		headerBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0x88000000);
		add(headerBar);
		
		// Logo
		logoText = new FlxText(30, 15, 0, "PSYCH ENGINE", 42);
		logoText.setFormat(Paths.font("vcr.ttf"), 42, PRIMARY, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		logoText.borderSize = 3;
		add(logoText);
		
		logoSubText = new FlxText(30, 55, 0, "ULTRA V2.0", 18);
		logoSubText.setFormat(Paths.font("vcr.ttf"), 18, ACCENT, LEFT);
		add(logoSubText);
		
		// Sağ üst bilgi
		versionText = new FlxText(FlxG.width - 200, 20, 180, "v2.0.0", 16);
		versionText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF888888, RIGHT);
		add(versionText);
		
		timeText = new FlxText(FlxG.width - 200, 45, 180, "", 14);
		timeText.setFormat(Paths.font("vcr.ttf"), 14, 0xFF666666, RIGHT);
		add(timeText);
	}
	
	function createCategories()
	{
		var tabWidth:Int = 150;
		var startX:Int = Std.int((FlxG.width - (tabWidth * 3)) / 2);
		
		for (i in 0...categories.length)
		{
			// Tab arka plan
			var tab = new FlxSprite(startX + i * tabWidth, 85).makeGraphic(tabWidth - 10, 40, 0x44FFFFFF);
			tab.alpha = i == curCategory ? 0.3 : 0.1;
			add(tab);
			categoryTabs.push(tab);
			
			// Tab metni
			var text = new FlxText(startX + i * tabWidth, 92, tabWidth - 10, categoryNames[i], 16);
			text.setFormat(Paths.font("vcr.ttf"), 16, i == curCategory ? PRIMARY : 0xFFAAAAAA, CENTER);
			add(text);
			categoryTexts.push(text);
		}
		
		// Kategori indikatörü
		categoryIndicator = new FlxSprite(startX, 125).makeGraphic(tabWidth - 10, 3, PRIMARY);
		add(categoryIndicator);
	}
	
	function createMenuCards()
	{
		cardContainer = new FlxTypedGroup<FlxSprite>();
		add(cardContainer);
		
		updateMenuCards();
	}
	
	function updateMenuCards()
	{
		// Mevcut kartları temizle
		for (card in menuCards)
		{
			cardContainer.remove(card.bg);
			cardContainer.remove(card.icon);
			cardContainer.remove(card.title);
			cardContainer.remove(card.desc);
			cardContainer.remove(card.arrow);
		}
		menuCards = [];
		
		var currentCategory = categories[curCategory];
		var cardWidth:Int = 280;
		var cardHeight:Int = 120;
		var spacing:Int = 20;
		var totalWidth:Int = currentCategory.length * cardWidth + (currentCategory.length - 1) * spacing;
		var startX:Int = Std.int((FlxG.width - totalWidth) / 2);
		var y:Int = 180;
		
		for (i in 0...currentCategory.length)
		{
			var option = currentCategory[i];
			var x = startX + i * (cardWidth + spacing);
			
			var card = new MenuCard(x, y, cardWidth, cardHeight, option);
			menuCards.push(card);
			
			cardContainer.add(card.bg);
			cardContainer.add(card.icon);
			cardContainer.add(card.title);
			cardContainer.add(card.desc);
			cardContainer.add(card.arrow);
		}
	}
	
	function createSelectionEffects()
	{
		// Seçim halkası
		selectionRing = new FlxSprite();
		selectionRing.makeGraphic(300, 140, 0x00FFFFFF);
		selectionRing.alpha = 0;
		add(selectionRing);
		
		// Hover efekti
		hoverEffect = new FlxSprite();
		hoverEffect.makeGraphic(300, 140, 0x44FFFFFF);
		hoverEffect.alpha = 0;
		add(hoverEffect);
		
		// Geçiş overlay
		transitionOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		transitionOverlay.alpha = 0;
		add(transitionOverlay);
	}
	
	function createQuickAccess()
	{
		// Hızlı erişim butonları (sağ alt)
		var quickButtons:Array<String> = ['🔍', '🌙', '🔔'];
		var buttonSize:Int = 40;
		var spacing:Int = 10;
		var startX:Int = FlxG.width - (quickButtons.length * (buttonSize + spacing)) - 20;
		var y:Int = FlxG.height - buttonSize - 20;
		
		for (i in 0...quickButtons.length)
		{
			var btn = new FlxSprite(startX + i * (buttonSize + spacing), y);
			btn.makeGraphic(buttonSize, buttonSize, 0x44FFFFFF);
			btn.alpha = 0.6;
			add(btn);
			quickAccess.push(btn);
			
			var icon = new FlxText(btn.x, btn.y + 5, buttonSize, quickButtons[i], 20);
			icon.setFormat(null, 20, FlxColor.WHITE, CENTER);
			add(icon);
		}
	}
	
	function createNotifications()
	{
		// Bildirim sistemi için alan
	}
	
	function setupCamera()
	{
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		
		camFollow.screenCenter();
		camFollowPos.screenCenter();
		FlxG.camera.follow(camFollowPos, null, 0.1);
	}
	
	function playIntroAnimation()
	{
		// Header animasyonu
		headerBar.y = -80;
		FlxTween.tween(headerBar, {y: 0}, 0.6, {ease: FlxEase.backOut});
		
		logoText.y = -50;
		FlxTween.tween(logoText, {y: 15}, 0.7, {ease: FlxEase.backOut, startDelay: 0.1});
		
		logoSubText.alpha = 0;
		FlxTween.tween(logoSubText, {alpha: 1}, 0.5, {startDelay: 0.3});
		
		// Kategori animasyonları
		for (i in 0...categoryTabs.length)
		{
			categoryTabs[i].y = 85 - 50;
			categoryTexts[i].y = 92 - 50;
			
			FlxTween.tween(categoryTabs[i], {y: 85}, 0.5, {ease: FlxEase.backOut, startDelay: 0.2 + i * 0.1});
			FlxTween.tween(categoryTexts[i], {y: 92}, 0.5, {ease: FlxEase.backOut, startDelay: 0.2 + i * 0.1});
		}
		
		// Kart animasyonları
		for (i in 0...menuCards.length)
		{
			var card = menuCards[i];
			card.bg.y = 180 + 100;
			card.bg.alpha = 0;
			
			FlxTween.tween(card.bg, {y: 180, alpha: 0.8}, 0.6, {ease: FlxEase.backOut, startDelay: 0.5 + i * 0.1});
			FlxTween.tween(card.icon, {alpha: 1}, 0.4, {startDelay: 0.6 + i * 0.1});
			FlxTween.tween(card.title, {alpha: 1}, 0.4, {startDelay: 0.7 + i * 0.1});
			FlxTween.tween(card.desc, {alpha: 0.7}, 0.4, {startDelay: 0.8 + i * 0.1});
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		ambientTime += elapsed;
		transitionTime += elapsed;
		
		updateBackground(elapsed);
		updateTime();
		updateEffects(elapsed);
		updateMenuInteractions(elapsed);
		
		if (!selectedSomethin && !isTransitioning)
		{
			handleInput();
		}
	}
	
	function updateBackground(elapsed:Float)
	{
		// Grid hareketi
		bgGrid.x -= 20 * elapsed;
		bgGrid.y -= 15 * elapsed;
		
		// Parçacık güncellemesi
		for (particle in bgParticles)
		{
			particle.update(elapsed);
		}
		
		// Orb animasyonları
		for (i in 0...bgOrbs.length)
		{
			var orb = bgOrbs[i];
			var scale = 1 + Math.sin(ambientTime * 0.5 + i) * 0.3;
			orb.scale.set(scale, scale);
			orb.alpha = 0.05 + Math.sin(ambientTime * 0.3 + i) * 0.03;
			orb.x = FlxG.width * (0.2 + i * 0.15) + Math.sin(ambientTime * 0.2 + i) * 50;
			orb.y = FlxG.height * (0.3 + i * 0.1) + Math.cos(ambientTime * 0.3 + i) * 30;
		}
		
		// Çizgi animasyonları
		for (i in 0...bgLines.length)
		{
			var line = bgLines[i];
			line.y = 200 + i * 150 + Math.sin(ambientTime + i) * 20;
			line.alpha = 0.1 + Math.sin(ambientTime * 2 + i) * 0.05;
		}
	}
	
	function updateTime()
	{
		var now = Date.now();
		var timeStr = '${now.getHours().toString().padLeft('0', 2)}:${now.getMinutes().toString().padLeft('0', 2)}';
		timeText.text = timeStr;
	}
	
	function updateEffects(elapsed:Float)
	{
		// Selection ring pulse
		if (menuCards.length > 0)
		{
			var selectedCard = menuCards[curSelected];
			selectionRing.x = selectedCard.bg.x - 10;
			selectionRing.y = selectedCard.bg.y - 10;
			selectionRing.alpha = 0.3 + Math.sin(ambientTime * 3) * 0.2;
			
			// Selection ring scale
			var scale = 1 + Math.sin(ambientTime * 2) * 0.05;
			selectionRing.scale.set(scale, scale);
		}
		
		// Logo nefes efekti
		var breathe = 1 + Math.sin(ambientTime * 1.5) * 0.02;
		logoText.scale.set(breathe, breathe);
		
		// Category indicator animasyonu
		if (categoryTabs.length > 0)
		{
			var targetX = categoryTabs[curCategory].x;
			categoryIndicator.x = FlxMath.lerp(categoryIndicator.x, targetX, 0.2);
		}
	}
	
	function updateMenuInteractions(elapsed:Float)
	{
		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		var hoveringCard:Int = -1;
		
		// Mouse hover detection
		for (i in 0...menuCards.length)
		{
			var card = menuCards[i];
			if (mouseX >= card.bg.x && mouseX <= card.bg.x + card.bg.width &&
				mouseY >= card.bg.y && mouseY <= card.bg.y + card.bg.height)
			{
				hoveringCard = i;
				break;
			}
		}
		
		// Hover effects
		for (i in 0...menuCards.length)
		{
			var card = menuCards[i];
			var targetAlpha:Float = 0.8;
			var targetScale:Float = 1;
			var targetY:Float = 180;
			
			if (i == curSelected)
			{
				targetAlpha = 1;
				targetScale = 1.05;
				targetY = 175;
			}
			else if (i == hoveringCard)
			{
				targetAlpha = 0.9;
				targetScale = 1.02;
				targetY = 178;
			}
			else
			{
				targetAlpha = 0.6;
				targetScale = 0.95;
				targetY = 182;
			}
			
			card.bg.alpha = FlxMath.lerp(card.bg.alpha, targetAlpha, 0.15);
			card.bg.scale.set(
				FlxMath.lerp(card.bg.scale.x, targetScale, 0.15),
				FlxMath.lerp(card.bg.scale.y, targetScale, 0.15)
			);
			card.bg.y = FlxMath.lerp(card.bg.y, targetY, 0.15);
			
			// Arrow animasyonu
			if (i == curSelected || i == hoveringCard)
			{
				card.arrow.alpha = FlxMath.lerp(card.arrow.alpha, 1, 0.2);
				card.arrow.x = card.bg.x + card.bg.width - 40 + Math.sin(ambientTime * 4) * 3;
			}
			else
			{
				card.arrow.alpha = FlxMath.lerp(card.arrow.alpha, 0, 0.2);
			}
		}
	}
	
	function handleInput()
	{
		// Kategori değiştirme (Q/E)
		if (controls.UI_LEFT_P)
		{
			changeCategory(-1);
		}
		else if (controls.UI_RIGHT_P)
		{
			changeCategory(1);
		}
		
		// Menü navigasyonu
		if (controls.UI_UP_P)
		{
			changeItem(-1);
		}
		else if (controls.UI_DOWN_P)
		{
			changeItem(1);
		}
		
		// Mouse seçimi
		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		
		for (i in 0...menuCards.length)
		{
			var card = menuCards[i];
			if (mouseX >= card.bg.x && mouseX <= card.bg.x + card.bg.width &&
				mouseY >= card.bg.y && mouseY <= card.bg.y + card.bg.height)
			{
				if (curSelected != i)
				{
					curSelected = i;
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
				}
				
				if (FlxG.mouse.justPressed)
				{
					selectItem();
				}
				break;
			}
		}
		
		// Onay ve geri
		if (controls.ACCEPT)
		{
			selectItem();
		}
		
		if (controls.BACK)
		{
			goBack();
		}
		
		// Debug
		#if desktop
		if (controls.justPressed('debug_1'))
		{
			selectedSomethin = true;
			MusicBeatState.switchState(new MasterEditorMenu());
		}
		#end
	}
	
	function changeCategory(change:Int)
	{
		curCategory += change;
		if (curCategory >= categories.length) curCategory = 0;
		if (curCategory < 0) curCategory = categories.length - 1;
		
		curSelected = 0;
		updateMenuCards();
		updateCategoryVisuals();
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		// Kategori değişim animasyonu
		for (i in 0...categoryTabs.length)
		{
			var targetAlpha = (i == curCategory) ? 0.3 : 0.1;
			FlxTween.tween(categoryTabs[i], {alpha: targetAlpha}, 0.3);
			
			var targetColor = (i == curCategory) ? PRIMARY : 0xFFAAAAAA;
			FlxTween.color(categoryTexts[i], 0.3, categoryTexts[i].color, targetColor);
		}
	}
	
	function updateCategoryVisuals()
	{
		for (i in 0...categoryTabs.length)
		{
			categoryTabs[i].alpha = (i == curCategory) ? 0.3 : 0.1;
			categoryTexts[i].color = (i == curCategory) ? PRIMARY : 0xFFAAAAAA;
		}
	}
	
	function changeItem(change:Int)
	{
		var currentCategory = categories[curCategory];
		curSelected += change;
		
		if (curSelected >= currentCategory.length) curSelected = 0;
		if (curSelected < 0) curSelected = currentCategory.length - 1;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	
	function selectItem()
	{
		if (selectedSomethin || isTransitioning) return;
		
		selectedSomethin = true;
		isTransitioning = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		var option = categories[curCategory][curSelected];
		var selectedCard = menuCards[curSelected];
		
		// Seçim animasyonu
		FlxFlicker.flicker(selectedCard.bg, 1, 0.06, false, false, function(flick:FlxFlicker)
		{
			navigateToOption(option);
		});
		
		// Diğer kartları kaydır
		for (i in 0...menuCards.length)
		{
			if (i != curSelected)
			{
				var card = menuCards[i];
				var direction = (i < curSelected) ? -1 : 1;
				FlxTween.tween(card.bg, {x: card.bg.x + direction * FlxG.width}, 0.6, {ease: FlxEase.backIn});
				FlxTween.tween(card.icon, {x: card.icon.x + direction * FlxG.width}, 0.6, {ease: FlxEase.backIn});
				FlxTween.tween(card.title, {x: card.title.x + direction * FlxG.width}, 0.6, {ease: FlxEase.backIn});
				FlxTween.tween(card.desc, {x: card.desc.x + direction * FlxG.width}, 0.6, {ease: FlxEase.backIn});
			}
		}
		
		// UI elemanlarını gizle
		FlxTween.tween(headerBar, {alpha: 0}, 0.4);
		FlxTween.tween(logoText, {alpha: 0}, 0.4);
		FlxTween.tween(logoSubText, {alpha: 0}, 0.4);
		FlxTween.tween(selectionRing, {alpha: 0}, 0.3);
		
		// Transition overlay
		FlxTween.tween(transitionOverlay, {alpha: 1}, 0.5, {
			onComplete: function(t:FlxTween) {
				// Navigate will be called after flicker completes
			}
		});
	}
	
	function navigateToOption(option:String)
	{
		switch (option)
		{
			case 'story_mode':
				ThemeManager.switchToStoryMenu();
			case 'freeplay':
				ThemeManager.switchToFreeplay();
			case 'extras':
				// Yeni ekstralar menüsü
				MusicBeatState.switchState(new ExtrasMenuState());
			case 'mods':
				#if MODS_ALLOWED
				MusicBeatState.switchState(new ModsMenuState());
				#end
			case 'achievements':
				ThemeManager.switchToAchievements();
			case 'gallery':
				// Yeni galeri menüsü
				MusicBeatState.switchState(new GalleryMenuState());
			case 'credits':
				ThemeManager.switchToCredits();
			case 'options':
				MusicBeatState.switchState(new OptionsState());
				OptionsState.onPlayState = false;
			case 'about':
				// Yeni hakkında menüsü
				MusicBeatState.switchState(new AboutMenuState());
			default:
				trace('Bilinmeyen menü seçeneği: $option');
		}
	}
	
	function goBack()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		
		FlxTween.tween(transitionOverlay, {alpha: 1}, 0.3, {
			onComplete: function(t:FlxTween) {
				MusicBeatState.switchState(new TitleState());
			}
		});
	}
	
	override function beatHit()
	{
		super.beatHit();
		
		// Logo beat bump
		FlxTween.cancelTweensOf(logoText.scale);
		logoText.scale.set(1.08, 1.08);
		FlxTween.tween(logoText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});
		
		// Selection ring flash
		if (menuCards.length > 0)
		{
			FlxTween.cancelTweensOf(selectionRing);
			selectionRing.color = ACCENT;
			FlxTween.color(selectionRing, 0.2, ACCENT, PRIMARY);
		}
		
		// Kart beat efektleri
		for (i in 0...menuCards.length)
		{
			if (i == curSelected)
			{
				var card = menuCards[i];
				FlxTween.cancelTweensOf(card.bg.scale);
				card.bg.scale.set(1.1, 1.1);
				FlxTween.tween(card.bg.scale, {x: 1.05, y: 1.05}, 0.4, {ease: FlxEase.quadOut});
			}
		}
		
		// Background orb beat
		for (i in 0...bgOrbs.length)
		{
			var orb = bgOrbs[i];
			FlxTween.cancelTweensOf(orb.scale);
			orb.scale.set(1.5, 1.5);
			FlxTween.tween(orb.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.quadOut});
		}
	}
}

// Yardımcı sınıflar
class MenuCard
{
	public var bg:FlxSprite;
	public var icon:FlxText;
	public var title:FlxText;
	public var desc:FlxText;
	public var arrow:FlxText;
	
	public function new(x:Float, y:Float, width:Int, height:Int, option:String)
	{
		// Kart arka planı
		bg = new FlxSprite(x, y);
		bg.makeGraphic(width, height, 0x8818182B);
		bg.updateHitbox();
		
		// İkon
		icon = new FlxText(x + 20, y + 15, 40, MainMenuV2.menuIcons[option], 32);
		icon.setFormat(null, 32, FlxColor.WHITE, CENTER);
		icon.alpha = 0;
		
		// Başlık
		title = new FlxText(x + 80, y + 15, width - 120, MainMenuV2.menuTitles[option], 20);
		title.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		title.borderSize = 1;
		title.alpha = 0;
		
		// Açıklama
		desc = new FlxText(x + 80, y + 45, width - 120, MainMenuV2.menuDescriptions[option], 14);
		desc.setFormat(Paths.font("vcr.ttf"), 14, 0xFFCCCCCC, LEFT);
		desc.alpha = 0;
		
		// Ok
		arrow = new FlxText(x + width - 40, y + height/2 - 10, 30, "▶", 20);
		arrow.setFormat(Paths.font("vcr.ttf"), 20, MainMenuV2.ACCENT, CENTER);
		arrow.alpha = 0;
	}
}

class DynamicParticle
{
	public var sprite:FlxSprite;
	public var velocity:FlxPoint;
	public var size:Float;
	public var lifeTime:Float;
	public var maxLifeTime:Float;
	
	public function new()
	{
		sprite = new FlxSprite();
		velocity = new FlxPoint();
		randomize();
	}
	
	public function randomize()
	{
		size = FlxG.random.float(1, 4);
		sprite.makeGraphic(Std.int(size), Std.int(size), FlxG.random.color(0xFF6366F1, 0xFFEC4899));
		sprite.x = FlxG.random.float(0, FlxG.width);
		sprite.y = FlxG.random.float(0, FlxG.height);
		velocity.x = FlxG.random.float(-30, 30);
		velocity.y = FlxG.random.float(-50, -10);
		lifeTime = 0;
		maxLifeTime = FlxG.random.float(3, 8);
		sprite.alpha = FlxG.random.float(0.1, 0.4);
	}
	
	public function update(elapsed:Float)
	{
		sprite.x += velocity.x * elapsed;
		sprite.y += velocity.y * elapsed;
		
		lifeTime += elapsed;
		if (lifeTime >= maxLifeTime)
		{
			randomize();
		}
		
		// Ekran dışı kontrolü
		if (sprite.y < -10 || sprite.x < -10 || sprite.x > FlxG.width + 10)
		{
			randomize();
		}
	}
}

class Notification
{
	public var bg:FlxSprite;
	public var text:FlxText;
	public var icon:FlxText;
	public var lifeTime:Float;
	
	public function new(message:String, type:String = "info")
	{
		// Bildirim sistemi gelecekte eklenebilir
	}
}
