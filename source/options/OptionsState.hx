package options;

import states.MainMenuState;
import backend.StageData;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxObject;
import flixel.util.FlxGradient;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.addons.display.FlxBackdrop;
import flixel.sound.FlxSound;
import flixel.input.keyboard.FlxKey;

class OptionsState extends MusicBeatState
{
	public static final USE_LAYERED_MUSIC:Bool  = false;
	public static final USE_EXISTING_MUSIC:Bool = false;
	static final MUSIC_BASE:String  = "options/optsBase";
	static final MUSIC_LAYER:String = "options/optsLayer";
	var _musicLayer:FlxSound;

	final ICON_OFFSETS:Array<Float> = [-900, -450, 0, 450, 900];
	final ICON_SCALES:Array<Float>  = [0.55,  0.85, 1.2, 0.85, 0.55];
	final TITLE_SCALES:Array<Float> = [0.35,  0.65, 1.0, 0.65, 0.35];
	final TITLE_V_OFF:Array<Float>  = [-90,   -45,  0,   -45,  -90];
	final ICON_ALPHAS:Array<Float>  = [0.0,   0.5,  1.0, 0.5,  0.0];
	final IDX_OFFSETS:Array<Int>    = [-2, -1, 0, 1, 2];
	final ICON_SIZE:Int = 220;
	final BOX_SIZE:Int = 260;
	final ICON_Y_CENTER:Float = 280;
	final TITLE_Y_BASE:Float = 490;

	final COLOR_SEL:FlxColor = 0xFFFFEE00;
	final COLOR_NRM:FlxColor = 0xFFFFFFFF;

	static var curSelected:Int = 0;
	var _exiting:Bool = false;
	var _options:Array<String> = [];
	var _optionDescs:Map<String, String> = [];
	var optionsColor:Map<String, Array<Int>> = [];
	var optionsIconPaths:Map<String, String> = [];
	var optionsStats:Map<String, String> = [];
	public static var onPlayState:Bool = false;

	var _secretCode:Array<FlxKey> = [FlxKey.X, FlxKey.Q, FlxKey.B, FlxKey.O, FlxKey.K, FlxKey.Y, FlxKey.E];
	var _secretIdx:Int = 0;

	var bg:FlxSprite;
	var bgPattern:FlxBackdrop;
	var bgGradient:FlxSprite;
	var bgDarken:FlxSprite;
	var bgVignette:FlxSprite;
	var bgOrbs:FlxTypedGroup<FlxSprite>;

	var headerPanel:FlxSprite;
	var headerGlow:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var breadcrumbText:FlxText;

	var profilePanel:FlxSprite;
	var profileIcon:FlxSprite;
	var profileName:FlxText;
	var profileStats:FlxText;

	var _carouselGroup:FlxSpriteGroup;
	var _iconBoxes:Array<FlxSprite> = [];
	var _icons:Array<FlxSprite> = [];
	var _titleTexts:Array<FlxText> = [];

	var descPanel:FlxSprite;
	var descPanelGlow:FlxSprite;
	var descIcon:FlxSprite;
	var descTitle:FlxText;
	var descText:FlxText;
	var descStats:FlxText;

	var particleEmitter:FlxEmitter;
	var secondaryParticles:FlxEmitter;
	var glowEffect:FlxSprite;
	var selectionGlow:FlxSprite;
	var scanlines:FlxSprite;
	var floatingShapes:FlxTypedGroup<FlxSprite>;

	var controlHintsPanel:FlxSprite;
	var controlHintsText:FlxText;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var bgColorTween:FlxTween;

	var animTimer:Float = 0;
	var pulseTimer:Float = 0;
	var waveTimer:Float = 0;
	var floatTimer:Float = 0;
	var glowTimer:Float = 0;
	var orbTimer:Float = 0;

	override function create()
	{
		_buildLanguageData();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Settings Menu", null);
		#end

		_startMusic();
		createBackgroundSystem();
		createParticleSystems();
		createFloatingShapes();
		createHeader();
		createProfilePanel();
		createCarousel();
		createDescriptionPanel();
		createControlHints();
		playEntranceAnimation();

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);
		camFollowPos.setPosition(FlxG.width / 2, FlxG.height / 2);
		FlxG.camera.follow(camFollowPos, null, 1);

		_applyCarousel(curSelected, 0);
		_updateDescBar();
		ClientPrefs.saveSettings();

		if (controls.mobileC)
		{
			var tipText:FlxText = new FlxText(150, FlxG.height - 24, 0,
				'Press ' + (FlxG.onMobile ? 'C' : 'CTRL or C') + ' to Go Mobile Controls Menu', 16);
			tipText.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tipText.borderSize = 1.25;
			tipText.scrollFactor.set();
			tipText.antialiasing = ClientPrefs.data.antialiasing;
			add(tipText);
		}

		addTouchPad('LEFT_FULL', 'A_B_C');
		super.create();
	}

	function _buildLanguageData():Void
	{
		_options = [
			Language.getPhrase('opt_note_colors',   'Note Colors'),
			Language.getPhrase('opt_controls',      'Controls'),
			Language.getPhrase('opt_delay_combo',   'Delay & Combo'),
			Language.getPhrase('opt_graphics',      'Graphics & Performance'),
			Language.getPhrase('opt_interface',     'Interface & Visuals'),
			Language.getPhrase('opt_gameplay',      'Gameplay'),
			Language.getPhrase('opt_peu',           'P.E.U Settings'),
			Language.getPhrase('opt_menu_settings', 'Menu Settings')
		];
		#if TRANSLATIONS_ALLOWED
		_options.push(Language.getPhrase('opt_language', 'Language'));
		#end
		#if mobile
		_options.push(Language.getPhrase('opt_mobile', 'Mobile Settings'));
		#end

		_optionDescs = [
			Language.getPhrase('opt_note_colors',   'Note Colors')            => Language.getPhrase('opt_desc_note_colors',   'Customize the colors and appearance of the notes however you like.'),
			Language.getPhrase('opt_controls',      'Controls')               => Language.getPhrase('opt_desc_controls',      'Configure keyboard and gamepad button assignments.'),
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')          => Language.getPhrase('opt_desc_delay_combo',   'Adjust the audio and video settings. Change the combo display style.'),
			Language.getPhrase('opt_graphics',      'Graphics & Performance') => Language.getPhrase('opt_desc_graphics',      'Optimize graphics quality, FPS limit, and performance settings.'),
			Language.getPhrase('opt_interface',     'Interface & Visuals')    => Language.getPhrase('opt_desc_interface',     'Customize the menu design and in-game visuals.'),
			Language.getPhrase('opt_gameplay',      'Gameplay')               => Language.getPhrase('opt_desc_gameplay',      'Customize Your Game Settings to Suit Your Style!'),
			Language.getPhrase('opt_language',      'Language')               => Language.getPhrase('opt_desc_language',      'Change the game language and view the localization options.'),
			Language.getPhrase('opt_peu',           'P.E.U Settings')         => Language.getPhrase('opt_desc_peu',           'Customize Psych Engine Ultra Settings.'),
			Language.getPhrase('opt_menu_settings', 'Menu Settings')          => Language.getPhrase('opt_desc_menu_settings', 'Customize the main menu appearance.')
		];

		optionsStats = [
			Language.getPhrase('opt_note_colors',   'Note Colors')            => Language.getPhrase('opt_stat_note_colors',   'Adjust Note Colors Using Colors.'),
			Language.getPhrase('opt_controls',      'Controls')               => Language.getPhrase('opt_stat_controls',      'Default: W-A-S-D'),
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')          => Language.getPhrase('opt_stat_delay_combo',   'Default ms: 0'),
			Language.getPhrase('opt_graphics',      'Graphics & Performance') => Language.getPhrase('opt_stat_graphics',      'Manage Your Gaming Performance'),
			Language.getPhrase('opt_interface',     'Interface & Visuals')    => Language.getPhrase('opt_stat_interface',     'Select your Note Skins.'),
			Language.getPhrase('opt_gameplay',      'Gameplay')               => Language.getPhrase('opt_stat_gameplay',      'Manage Gameplay Settings'),
			Language.getPhrase('opt_language',      'Language')               => Language.getPhrase('opt_stat_language',      'Select Your Language Here!'),
			Language.getPhrase('opt_peu',           'P.E.U Settings')         => Language.getPhrase('opt_stat_peu',           'Customize P.E.U'),
			Language.getPhrase('opt_menu_settings', 'Menu Settings')          => Language.getPhrase('opt_stat_menu_settings', 'Customize Main Menu')
		];

		optionsColor = [
			Language.getPhrase('opt_note_colors',   'Note Colors')            => [0xFF9B59B6, 0xFF8E44AD, 0xFF6C3483],
			Language.getPhrase('opt_controls',      'Controls')               => [0xFFE67E22, 0xFFD35400, 0xFFA04000],
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')          => [0xFFE74C3C, 0xFFC0392B, 0xFF922B21],
			Language.getPhrase('opt_graphics',      'Graphics & Performance') => [0xFF3498DB, 0xFF2980B9, 0xFF1F618D],
			Language.getPhrase('opt_interface',     'Interface & Visuals')    => [0xFF9B59B6, 0xFF8E44AD, 0xFF6C3483],
			Language.getPhrase('opt_gameplay',      'Gameplay')               => [0xFF2ECC71, 0xFF27AE60, 0xFF1E8449],
			Language.getPhrase('opt_language',      'Language')               => [0xFF7F8C8D, 0xFF707B7C, 0xFF212F3D],
			Language.getPhrase('opt_peu',           'P.E.U Settings')         => [0xFF8E44AD, 0xFF7D3C98, 0xFF4A235A],
			Language.getPhrase('opt_menu_settings', 'Menu Settings')          => [0xFFF39C12, 0xFFD68910, 0xFF7E5109],
		];

		optionsIconPaths = [
			Language.getPhrase('opt_note_colors',   'Note Colors')            => 'note_colors',
			Language.getPhrase('opt_controls',      'Controls')               => 'controls',
			Language.getPhrase('opt_delay_combo',   'Delay & Combo')          => 'delay_and_combo',
			Language.getPhrase('opt_graphics',      'Graphics & Performance') => 'graphics_and_performance',
			Language.getPhrase('opt_interface',     'Interface & Visuals')    => 'interface_and_visuals',
			Language.getPhrase('opt_gameplay',      'Gameplay')               => 'gameplay',
			Language.getPhrase('opt_language',      'Language')               => 'language',
			Language.getPhrase('opt_peu',           'P.E.U Settings')         => 'peu',
			Language.getPhrase('opt_menu_settings', 'Menu Settings')          => 'menu_settings'
		];
	}

	function _startMusic():Void
	{
		if (USE_EXISTING_MUSIC) return;
		if (!USE_LAYERED_MUSIC) return;
		FlxG.sound.playMusic(Paths.music(MUSIC_BASE), 1, true);
		_musicLayer = FlxG.sound.play(Paths.music(MUSIC_LAYER), 0, true);
		_musicLayer.time = FlxG.sound.music.time;
	}

	function _stopMusic():Void
	{
		if (USE_EXISTING_MUSIC || !USE_LAYERED_MUSIC) return;
		if (FlxG.sound.music != null) FlxG.sound.music.fadeOut(0.35);
		if (_musicLayer != null) _musicLayer.fadeOut(0.35);
	}

	function _syncLayerVolume():Void
	{
		if (!USE_LAYERED_MUSIC || _musicLayer == null || FlxG.sound.music == null) return;
		if (Math.abs(_musicLayer.time - FlxG.sound.music.time) > 25)
		{
			_musicLayer.pause();
			_musicLayer.time = FlxG.sound.music.time;
			_musicLayer.play();
		}
		_musicLayer.volume = FlxMath.lerp(_musicLayer.volume, 0.0, 0.08);
	}

	function createBackgroundSystem()
	{
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.5));
		bg.updateHitbox();
		bg.screenCenter();
		bg.alpha = 0.25;
		bg.scrollFactor.set(0.02, 0.02);
		add(bg);

		bgPattern = new FlxBackdrop(null, XY, 0, 0);
		bgPattern.makeGraphic(120, 120, FlxColor.TRANSPARENT, true);
		drawGridPattern(bgPattern);
		bgPattern.velocity.set(15, 10);
		bgPattern.alpha = 0;
		bgPattern.scrollFactor.set(0, 0);
		add(bgPattern);

		bgGradient = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0xFF1a1a2e, 0xFF16213e, 0xFF0f3460, 0xFF0a0a15],
			1, 135
		);
		bgGradient.alpha = 0;
		bgGradient.scrollFactor.set(0, 0);
		add(bgGradient);

		bgOrbs = new FlxTypedGroup<FlxSprite>();
		add(bgOrbs);
		for (i in 0...8)
		{
			var orb = new FlxSprite(Math.random() * FlxG.width, Math.random() * FlxG.height);
			orb.makeGraphic(Std.int(80 + Math.random() * 120), Std.int(80 + Math.random() * 120), FlxColor.WHITE);
			orb.blend = ADD;
			orb.alpha = 0;
			orb.scrollFactor.set(0.05, 0.05);
			orb.ID = i;
			bgOrbs.add(orb);
		}

		bgVignette = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[0x00000000, 0x00000000, 0x66000000],
			1, 0, true
		);
		bgVignette.scrollFactor.set(0, 0);
		add(bgVignette);

		bgDarken = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bgDarken.alpha = 0;
		bgDarken.scrollFactor.set(0, 0);
		add(bgDarken);

		glowEffect = new FlxSprite(FlxG.width / 2 - 600, FlxG.height / 2 - 600);
		glowEffect.makeGraphic(1200, 1200, FlxColor.WHITE);
		glowEffect.blend = ADD;
		glowEffect.alpha = 0;
		glowEffect.scrollFactor.set(0, 0);
		add(glowEffect);

		selectionGlow = new FlxSprite();
		selectionGlow.makeGraphic(300, 300, FlxColor.WHITE);
		selectionGlow.blend = ADD;
		selectionGlow.alpha = 0;
		selectionGlow.scrollFactor.set(0, 0);
		add(selectionGlow);

		scanlines = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT, true);
		drawScanlines(scanlines);
		scanlines.alpha = 0.03;
		scanlines.scrollFactor.set(0, 0);
		add(scanlines);
	}

	function drawGridPattern(sprite:FlxSprite)
	{
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);
		for (i in 0...Std.int(sprite.width / 20))
			g.fillRect(new flash.geom.Rectangle(i * 20, 0, 1, sprite.height), 0x11FFFFFF);
		for (i in 0...Std.int(sprite.height / 20))
			g.fillRect(new flash.geom.Rectangle(0, i * 20, sprite.width, 1), 0x11FFFFFF);
		for (i in 0...Std.int(sprite.width / 20))
			for (j in 0...Std.int(sprite.height / 20))
				g.fillRect(new flash.geom.Rectangle(i * 20 - 1, j * 20 - 1, 3, 3), 0x22FFFFFF);
	}

	function drawScanlines(sprite:FlxSprite)
	{
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);
		for (i in 0...Std.int(FlxG.height / 3))
			g.fillRect(new flash.geom.Rectangle(0, i * 3, FlxG.width, 1), 0x08000000);
	}

	function createParticleSystems()
	{
		particleEmitter = new FlxEmitter(FlxG.width / 2, 50, 80);
		particleEmitter.width = FlxG.width;
		for (i in 0...80)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(3, 3, FlxColor.WHITE);
			particle.blend = ADD;
			particle.exists = false;
			particleEmitter.add(particle);
		}
		particleEmitter.launchMode = FlxEmitterMode.SQUARE;
		particleEmitter.velocity.set(-30, 40, 30, 150);
		particleEmitter.lifespan.set(4, 8);
		particleEmitter.alpha.set(0.2, 0.5, 0, 0);
		particleEmitter.scale.set(1, 2, 0.3, 0.3);
		particleEmitter.start(false, 0.05);
		add(particleEmitter);

		secondaryParticles = new FlxEmitter(FlxG.width / 2, FlxG.height / 2, 40);
		secondaryParticles.width = FlxG.width;
		secondaryParticles.height = FlxG.height;
		for (i in 0...40)
		{
			var particle:FlxParticle = new FlxParticle();
			particle.makeGraphic(5, 5, FlxColor.WHITE);
			particle.alpha = 0.15;
			particle.exists = false;
			secondaryParticles.add(particle);
		}
		secondaryParticles.launchMode = FlxEmitterMode.SQUARE;
		secondaryParticles.velocity.set(-15, -15, 15, 15);
		secondaryParticles.lifespan.set(6, 12);
		secondaryParticles.alpha.set(0.08, 0.15, 0, 0);
		secondaryParticles.start(false, 0.2);
		add(secondaryParticles);
	}

	function createFloatingShapes()
	{
		floatingShapes = new FlxTypedGroup<FlxSprite>();
		add(floatingShapes);
		for (i in 0...15)
		{
			var shape = new FlxSprite(Math.random() * FlxG.width, Math.random() * FlxG.height);
			shape.makeGraphic(30, 30, FlxColor.WHITE);
			shape.blend = ADD;
			shape.alpha = 0;
			shape.scrollFactor.set(0.05 + Math.random() * 0.1, 0.05 + Math.random() * 0.1);
			shape.ID = i;
			floatingShapes.add(shape);
		}
	}

	function createHeader()
	{
		headerPanel = new FlxSprite(0, -110).makeGraphic(FlxG.width, 110, 0xEE000000);
		headerPanel.scrollFactor.set(0, 0);
		add(headerPanel);

		headerGlow = new FlxSprite(0, -110).makeGraphic(FlxG.width, 4, FlxColor.WHITE);
		headerGlow.blend = ADD;
		headerGlow.alpha = 0.5;
		headerGlow.scrollFactor.set(0, 0);
		add(headerGlow);

		titleText = new FlxText(40, 15, FlxG.width - 280, Language.getPhrase('settings_title', 'Settings'), 44);
		titleText.setFormat(Paths.font("vcr.ttf"), 44, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF8D58FD);
		titleText.borderSize = 4;
		titleText.scrollFactor.set(0, 0);
		titleText.alpha = 0;
		add(titleText);

		subtitleText = new FlxText(40, 62, FlxG.width - 280, Language.getPhrase('settings_subtitle', 'Customize your gaming experience!'), 18);
		subtitleText.setFormat(Paths.font("vcr.ttf"), 18, 0xFFBBBBBB, LEFT);
		subtitleText.scrollFactor.set(0, 0);
		subtitleText.alpha = 0;
		add(subtitleText);

		breadcrumbText = new FlxText(40, 86, FlxG.width - 280, Language.getPhrase('settings_breadcrumb', 'Main Menu > Settings'), 12);
		breadcrumbText.setFormat(Paths.font("vcr.ttf"), 12, 0xFF888888, LEFT);
		breadcrumbText.scrollFactor.set(0, 0);
		breadcrumbText.alpha = 0;
		add(breadcrumbText);
	}

	function createProfilePanel()
	{
		profilePanel = new FlxSprite(FlxG.width - 200, 12).makeGraphic(185, 85, 0x88000000);
		profilePanel.scrollFactor.set(0, 0);
		profilePanel.alpha = 0;
		add(profilePanel);

		profileIcon = new FlxSprite(FlxG.width - 190, 20);
		if (Paths.image('ultra/settings/images/player') != null)
		{
			profileIcon.loadGraphic(Paths.image('ultra/settings/images/player'));
			profileIcon.setGraphicSize(65, 65);
			profileIcon.updateHitbox();
		}
		else
			profileIcon.makeGraphic(65, 65, 0x66FFFFFF);
		profileIcon.scrollFactor.set(0, 0);
		profileIcon.antialiasing = ClientPrefs.data.antialiasing;
		profileIcon.alpha = 0;
		add(profileIcon);

		profileName = new FlxText(FlxG.width - 115, 28, 100, Language.getPhrase('profile_name', 'Oyuncu'), 18);
		profileName.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		profileName.borderSize = 2;
		profileName.scrollFactor.set(0, 0);
		profileName.alpha = 0;
		add(profileName);

		profileStats = new FlxText(FlxG.width - 115, 52, 100, "Lv. 1", 13);
		profileStats.setFormat(Paths.font("vcr.ttf"), 13, 0xFFFFD700, LEFT);
		profileStats.scrollFactor.set(0, 0);
		profileStats.alpha = 0;
		add(profileStats);
	}

	function createCarousel()
	{
		_carouselGroup = new FlxSpriteGroup();
		add(_carouselGroup);

		for (i in 0...IDX_OFFSETS.length)
		{
			var box = new FlxSprite();
			box.makeGraphic(BOX_SIZE, BOX_SIZE, 0xAA000000);
			box.screenCenter();
			box.antialiasing = ClientPrefs.data.antialiasing;
			_iconBoxes.push(box);
			_carouselGroup.add(box);
		}

		for (i in 0...IDX_OFFSETS.length)
		{
			var icon = new FlxSprite();
			icon.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.WHITE);
			icon.screenCenter();
			icon.antialiasing = ClientPrefs.data.antialiasing;
			_icons.push(icon);
			_carouselGroup.add(icon);

			var txt = new FlxText(0, 0, 400, "", 24);
			txt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			txt.borderSize = 2;
			_titleTexts.push(txt);
			_carouselGroup.add(txt);
		}
	}

	function createDescriptionPanel()
	{
		descPanel = new FlxSprite(25, FlxG.height).makeGraphic(FlxG.width - 50, 85, 0xDD000000);
		descPanel.scrollFactor.set(0, 0);
		add(descPanel);

		descPanelGlow = new FlxSprite(25, FlxG.height).makeGraphic(FlxG.width - 50, 3, FlxColor.WHITE);
		descPanelGlow.blend = ADD;
		descPanelGlow.alpha = 0.4;
		descPanelGlow.scrollFactor.set(0, 0);
		add(descPanelGlow);

		descIcon = new FlxSprite(40, FlxG.height + 12);
		descIcon.makeGraphic(55, 55, 0x66FFFFFF);
		descIcon.scrollFactor.set(0, 0);
		descIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(descIcon);

		descTitle = new FlxText(110, FlxG.height + 10, FlxG.width - 160, "", 20);
		descTitle.setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFD700, LEFT,
			FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descTitle.borderSize = 2;
		descTitle.scrollFactor.set(0, 0);
		add(descTitle);

		descText = new FlxText(110, FlxG.height + 38, FlxG.width - 160, "", 14);
		descText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		descText.scrollFactor.set(0, 0);
		add(descText);

		descStats = new FlxText(FlxG.width - 200, FlxG.height + 15, 170, "", 11);
		descStats.setFormat(Paths.font("vcr.ttf"), 11, 0xFF888888, RIGHT);
		descStats.scrollFactor.set(0, 0);
		add(descStats);
	}

	function createControlHints()
	{
		controlHintsPanel = new FlxSprite(0, FlxG.height).makeGraphic(FlxG.width, 28, 0xAA000000);
		controlHintsPanel.scrollFactor.set(0, 0);
		add(controlHintsPanel);

		var hintStr:String = controls.mobileC
			? Language.getPhrase('settings_hint_mobile', 'D-PAD: Gezin  |  A: Seç  |  B: Geri  |  C: Mobil Kontroller')
			: Language.getPhrase('settings_hint_desktop', 'LEFT/RIGHT: Navigate   |   ENTER: Open   |   ESC: Back');

		controlHintsText = new FlxText(0, FlxG.height + 6, FlxG.width, hintStr, 12);
		controlHintsText.setFormat(Paths.font("vcr.ttf"), 12, 0xFFAAAAAA, CENTER);
		controlHintsText.scrollFactor.set(0, 0);
		controlHintsText.alpha = 0;
		add(controlHintsText);
	}

	function playEntranceAnimation()
	{
		FlxTween.tween(bgDarken, {alpha: 0.6}, 0.8, {ease: FlxEase.quartOut});
		FlxTween.tween(bgGradient, {alpha: 0.85}, 1, {ease: FlxEase.quartOut, startDelay: 0.1});
		FlxTween.tween(bgPattern, {alpha: 0.06}, 1.2, {ease: FlxEase.quartOut, startDelay: 0.2});
		FlxTween.tween(glowEffect, {alpha: 0.1}, 1, {ease: FlxEase.quartOut, startDelay: 0.3});

		for (orb in bgOrbs)
			FlxTween.tween(orb, {alpha: 0.08 + Math.random() * 0.08}, 1.5,
				{ease: FlxEase.quartOut, startDelay: 0.5 + Math.random() * 0.5});

		for (shape in floatingShapes)
			FlxTween.tween(shape, {alpha: 0.1 + Math.random() * 0.15}, 1.5,
				{ease: FlxEase.quartOut, startDelay: 0.6 + Math.random() * 0.6});

		FlxTween.tween(headerPanel, {y: 0}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(headerGlow, {y: 106}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.1});
		FlxTween.tween(titleText, {alpha: 1}, 0.7, {ease: FlxEase.quartOut, startDelay: 0.3});
		FlxTween.tween(subtitleText, {alpha: 0.8}, 0.7, {ease: FlxEase.quartOut, startDelay: 0.4});
		FlxTween.tween(breadcrumbText, {alpha: 0.7}, 0.7, {ease: FlxEase.quartOut, startDelay: 0.5});

		FlxTween.tween(profilePanel, {alpha: 0.9}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.4});
		FlxTween.tween(profileIcon, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.45});
		FlxTween.tween(profileName, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.5});
		FlxTween.tween(profileStats, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.55});

		FlxTween.tween(descPanel, {y: FlxG.height - 113}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.3});
		FlxTween.tween(descPanelGlow, {y: FlxG.height - 113}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.3});
		FlxTween.tween(descIcon, {y: FlxG.height - 101}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.4});
		FlxTween.tween(descTitle, {y: FlxG.height - 103}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.45});
		FlxTween.tween(descText, {y: FlxG.height - 75}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.5});
		FlxTween.tween(descStats, {y: FlxG.height - 98}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.55});

		FlxTween.tween(controlHintsPanel, {y: FlxG.height - 28}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.35});
		FlxTween.tween(controlHintsText, {alpha: 1, y: FlxG.height - 22}, 0.6,
			{ease: FlxEase.quartOut, startDelay: 0.5});

		FlxTween.tween(_carouselGroup, {alpha: 1}, 0.6, {ease: FlxEase.quartOut, startDelay: 0.4});
	}

	function playExitAnimation(callback:Void->Void)
	{
		FlxTween.tween(bgGradient, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
		FlxTween.tween(bgDarken, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
		FlxTween.tween(bgPattern, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});
		FlxTween.tween(glowEffect, {alpha: 0}, 0.4, {ease: FlxEase.quartIn});

		FlxTween.tween(headerPanel, {y: -150}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(headerGlow, {y: -150}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(titleText, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});

		FlxTween.tween(profilePanel, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
		FlxTween.tween(profileIcon, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});
		FlxTween.tween(profileName, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});

		FlxTween.tween(descPanel, {y: FlxG.height + 50}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(descPanelGlow, {y: FlxG.height + 50}, 0.4, {ease: FlxEase.backIn});
		FlxTween.tween(controlHintsPanel, {y: FlxG.height + 50}, 0.4, {ease: FlxEase.backIn});

		FlxTween.tween(_carouselGroup, {alpha: 0}, 0.3, {ease: FlxEase.quartIn});

		new FlxTimer().start(0.45, function(tmr:FlxTimer) { callback(); });
	}

	function _loadIconGraphic(icon:FlxSprite, dataIdx:Int):Void
	{
		var label = _options[dataIdx];
		var iconPath = optionsIconPaths.exists(label) ? optionsIconPaths.get(label) : 'pet';
		var imgPath = Paths.image('ultra/settings/images/' + iconPath);
		if (imgPath != null)
		{
			icon.loadGraphic(imgPath);
			icon.setGraphicSize(ICON_SIZE, ICON_SIZE);
			icon.updateHitbox();
		}
		else
		{
			icon.makeGraphic(ICON_SIZE, ICON_SIZE, _categoryColor(dataIdx));
		}
	}

	function _getBoxColor(dataIdx:Int):FlxColor
	{
		var label = _options[dataIdx];
		if (optionsColor.exists(label))
		{
			var colors = optionsColor.get(label);
			return colors[0];
		}
		return 0xAA000000;
	}

	function _getTargetX(slotIndex:Int):Float
	{
		return FlxG.width / 2 + ICON_OFFSETS[slotIndex];
	}

	function _getIconTargetX(slotIndex:Int):Float
	{
		return FlxG.width / 2 - ICON_SIZE / 2 + ICON_OFFSETS[slotIndex];
	}

	function _getBoxTargetX(slotIndex:Int):Float
	{
		return FlxG.width / 2 - BOX_SIZE / 2 + ICON_OFFSETS[slotIndex];
	}

	function _getIconTargetY():Float
	{
		return ICON_Y_CENTER;
	}

	function _getBoxTargetY():Float
	{
		return ICON_Y_CENTER - (BOX_SIZE - ICON_SIZE) / 2;
	}

	function _getTitleTargetX(slotIndex:Int):Float
	{
		return FlxG.width / 2 - 200 + ICON_OFFSETS[slotIndex];
	}

	function _getTitleTargetY(slotIndex:Int):Float
	{
		return TITLE_Y_BASE + TITLE_V_OFF[slotIndex];
	}

	function _applyCarousel(newSelected:Int, change:Int):Void
	{
		curSelected = newSelected;
		var doTween:Bool = (change != 0);

		for (i in 0...IDX_OFFSETS.length)
		{
			var dataIdx = _wrapIdx(curSelected + IDX_OFFSETS[i]);

			_loadIconGraphic(_icons[i], dataIdx);
			_iconBoxes[i].color = _getBoxColor(dataIdx);
			_titleTexts[i].text = _options[dataIdx];
			_titleTexts[i].color = (IDX_OFFSETS[i] == 0) ? FlxColor.WHITE : 0xFF888888;

			var targetBX = _getBoxTargetX(i);
			var targetBY = _getBoxTargetY();
			var targetIX = _getIconTargetX(i);
			var targetIY = _getIconTargetY();
			var targetTX = _getTitleTargetX(i);
			var targetTY = _getTitleTargetY(i);
			var targetAlpha = ICON_ALPHAS[i];
			var targetIScale = ICON_SCALES[i];
			var targetTScale = TITLE_SCALES[i];

			if (doTween)
			{
				var iOffset = i + change;

				FlxTween.cancelTweensOf(_iconBoxes[i]);
				FlxTween.cancelTweensOf(_iconBoxes[i].scale);
				FlxTween.cancelTweensOf(_icons[i]);
				FlxTween.cancelTweensOf(_icons[i].scale);
				FlxTween.cancelTweensOf(_titleTexts[i]);
				FlxTween.cancelTweensOf(_titleTexts[i].scale);

				if (iOffset < 0 || iOffset >= IDX_OFFSETS.length)
				{
					_iconBoxes[i].visible = false;
					_icons[i].visible = false;
					_titleTexts[i].visible = false;

					_iconBoxes[i].setPosition(targetBX, targetBY);
					_iconBoxes[i].alpha = targetAlpha;
					_iconBoxes[i].scale.set(targetIScale, targetIScale);
					_icons[i].setPosition(targetIX, targetIY);
					_icons[i].alpha = targetAlpha;
					_icons[i].scale.set(targetIScale, targetIScale);
					_titleTexts[i].setPosition(targetTX, targetTY);
					_titleTexts[i].alpha = targetAlpha;
					_titleTexts[i].scale.set(targetTScale, targetTScale);
				}
				else
				{
					_iconBoxes[i].visible = true;
					_icons[i].visible = true;
					_titleTexts[i].visible = true;

					_iconBoxes[i].setPosition(_getBoxTargetX(iOffset), _getBoxTargetY());
					_iconBoxes[i].scale.set(ICON_SCALES[iOffset], ICON_SCALES[iOffset]);
					_iconBoxes[i].alpha = ICON_ALPHAS[iOffset];

					_icons[i].setPosition(_getIconTargetX(iOffset), _getIconTargetY());
					_icons[i].scale.set(ICON_SCALES[iOffset], ICON_SCALES[iOffset]);
					_icons[i].alpha = ICON_ALPHAS[iOffset];

					_titleTexts[i].setPosition(_getTitleTargetX(iOffset), _getTitleTargetY(iOffset));
					_titleTexts[i].scale.set(TITLE_SCALES[iOffset], TITLE_SCALES[iOffset]);
					_titleTexts[i].alpha = ICON_ALPHAS[iOffset];

					FlxTween.tween(_iconBoxes[i], {x: targetBX, y: targetBY, alpha: targetAlpha}, 0.4, {ease: FlxEase.quartOut});
					FlxTween.tween(_iconBoxes[i].scale, {x: targetIScale, y: targetIScale}, 0.4, {ease: FlxEase.quartOut});
					FlxTween.tween(_icons[i], {x: targetIX, y: targetIY, alpha: targetAlpha}, 0.4, {ease: FlxEase.quartOut});
					FlxTween.tween(_icons[i].scale, {x: targetIScale, y: targetIScale}, 0.4, {ease: FlxEase.quartOut});
					FlxTween.tween(_titleTexts[i], {x: targetTX, y: targetTY, alpha: targetAlpha}, 0.4, {ease: FlxEase.quartOut});
					FlxTween.tween(_titleTexts[i].scale, {x: targetTScale, y: targetTScale}, 0.4, {ease: FlxEase.quartOut});
				}
			}
			else
			{
				_iconBoxes[i].visible = true;
				_icons[i].visible = true;
				_titleTexts[i].visible = true;
				_iconBoxes[i].setPosition(targetBX, targetBY);
				_iconBoxes[i].alpha = targetAlpha;
				_iconBoxes[i].scale.set(targetIScale, targetIScale);
				_icons[i].setPosition(targetIX, targetIY);
				_icons[i].alpha = targetAlpha;
				_icons[i].scale.set(targetIScale, targetIScale);
				_titleTexts[i].setPosition(targetTX, targetTY);
				_titleTexts[i].alpha = targetAlpha;
				_titleTexts[i].scale.set(targetTScale, targetTScale);
			}
		}
	}

	function _categoryColor(idx:Int):FlxColor
	{
		final C:Array<FlxColor> = [
			0xFFB36AE0, 0xFFE87820, 0xFFE03030, 0xFF2E8FE0,
			0xFF9B50E0, 0xFF27C060, 0xFF8E38B8, 0xFFF0920E, 0xFF607080
		];
		return C[idx % C.length];
	}

	inline function _wrapIdx(v:Int):Int
	{
		while (v >= _options.length) v -= _options.length;
		while (v < 0) v += _options.length;
		return v;
	}

	function _updateDescBar():Void
	{
		var lbl = _options[curSelected];
		descTitle.text = lbl;
		if (_optionDescs.exists(lbl)) descText.text = _optionDescs.get(lbl);
		if (optionsStats.exists(lbl)) descStats.text = optionsStats.get(lbl);

		var iconPath = optionsIconPaths.exists(lbl) ? optionsIconPaths.get(lbl) : 'pet';
		var imgPath = Paths.image('ultra/settings/images/' + iconPath);
		if (imgPath != null)
		{
			descIcon.loadGraphic(imgPath);
			descIcon.setGraphicSize(55, 55);
			descIcon.updateHitbox();
		}

		FlxTween.cancelTweensOf(descTitle);
		FlxTween.cancelTweensOf(descText);
		descTitle.alpha = 0;
		descText.alpha = 0;
		FlxTween.tween(descTitle, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});
		FlxTween.tween(descText, {alpha: 1}, 0.3, {ease: FlxEase.quartOut, startDelay: 0.1});

		if (optionsColor.exists(lbl))
		{
			var colors = optionsColor.get(lbl);
			var newGradient = FlxGradient.createGradientFlxSprite(
				FlxG.width, FlxG.height,
				[colors[0], colors[1], colors[2], 0xFF0a0a15], 1, 135);
			newGradient.alpha = 0;
			newGradient.scrollFactor.set(0, 0);
			var oldGradient = bgGradient;
			insert(members.indexOf(bgGradient), newGradient);
			FlxTween.tween(oldGradient, {alpha: 0}, 0.5, {onComplete: function(t) remove(oldGradient)});
			FlxTween.tween(newGradient, {alpha: 0.85}, 0.5);
			bgGradient = newGradient;
			selectionGlow.color = colors[0];
		}
	}

	function _openSubstate(label:String):Void
	{
		if (label != Language.getPhrase('opt_delay_combo', 'Delay & Combo'))
		{
			removeTouchPad();
			persistentUpdate = false;
		}

		_stopMusic();

		playExitAnimation(function() {
			if      (label == Language.getPhrase('opt_note_colors',   'Note Colors'))            openSubState(new options.NotesColorSubState());
			else if (label == Language.getPhrase('opt_controls',      'Controls'))               openSubState(new options.ControlsSubState());
			else if (label == Language.getPhrase('opt_graphics',      'Graphics & Performance')) openSubState(new options.GraphicsSettingsSubState());
			else if (label == Language.getPhrase('opt_interface',     'Interface & Visuals'))    openSubState(new options.VisualsSettingsSubState());
			else if (label == Language.getPhrase('opt_gameplay',      'Gameplay'))               openSubState(new options.GameplaySettingsSubState());
			else if (label == Language.getPhrase('opt_delay_combo',   'Delay & Combo'))          MusicBeatState.switchState(new options.NoteOffsetState());
			else if (label == Language.getPhrase('opt_language',      'Language'))               openSubState(new options.LanguageSubState());
			else if (label == Language.getPhrase('opt_peu',           'P.E.U Settings'))         openSubState(new options.PEUSettingsState());
			else if (label == Language.getPhrase('opt_menu_settings', 'Menu Settings'))          openSubState(new options.MainMenuSettingsState());
			#if mobile
			else if (label == Language.getPhrase('opt_mobile', 'Mobile Settings'))              openSubState(new mobile.options.MobileOptionsSubState());
			#end
		});
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		_secretIdx = 0;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Settings Menu", null);
		#end

		controls.isInSubstate = false;
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_C');
		persistentUpdate = true;

		_buildLanguageData();
		_startMusic();
		_carouselGroup.alpha = 1;
		_applyCarousel(curSelected, 0);
		_updateDescBar();
		playEntranceAnimation();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (_exiting) return;

		_syncLayerVolume();

		if (FlxG.keys.justPressed.ANY)
		{
			var k = FlxG.keys.firstJustPressed();
			var skip = (k == FlxKey.UP || k == FlxKey.DOWN || k == FlxKey.LEFT ||
			            k == FlxKey.RIGHT || k == FlxKey.ENTER || k == FlxKey.ESCAPE ||
			            k == FlxKey.W || k == FlxKey.A || k == FlxKey.S || k == FlxKey.D);
			if (!skip)
			{
				if (k == _secretCode[_secretIdx])
				{
					if (++_secretIdx >= _secretCode.length)
					{
						_secretIdx = 0;
						FlxG.sound.play(Paths.sound('confirmMenu'));
						FlxG.camera.flash(0x66FF00FF, 0.5);
						new FlxTimer().start(0.3, function(_)
							openSubState(new options.XqOptionsState()));
					}
				}
				else _secretIdx = 0;
			}
		}

		animTimer += elapsed;
		pulseTimer += elapsed;
		waveTimer += elapsed * 2;
		floatTimer += elapsed * 1.5;
		glowTimer += elapsed * 3;
		orbTimer += elapsed * 0.5;

		if (bg != null)
		{
			bg.angle = Math.sin(animTimer * 0.3) * 3;
			bg.scale.set(1.5 + Math.sin(floatTimer * 0.3) * 0.02,
			             1.5 + Math.cos(floatTimer * 0.3) * 0.02);
		}

		if (glowEffect != null)
		{
			glowEffect.alpha = 0.1 + Math.sin(pulseTimer * 1.5) * 0.05;
			glowEffect.angle += elapsed * 8;
			glowEffect.scale.set(1 + Math.sin(floatTimer * 0.5) * 0.15,
			                     1 + Math.cos(floatTimer * 0.5) * 0.15);
		}

		if (selectionGlow != null && _icons.length > 2)
		{
			var targetIcon = _icons[2];
			if (targetIcon != null)
			{
				selectionGlow.x = FlxMath.lerp(selectionGlow.x, targetIcon.x - 40, elapsed * 12);
				selectionGlow.y = FlxMath.lerp(selectionGlow.y, targetIcon.y - 40, elapsed * 12);
				selectionGlow.alpha = 0.15 + Math.sin(glowTimer) * 0.08;
			}
		}

		for (orb in bgOrbs)
		{
			orb.x += Math.sin(orbTimer + orb.ID * 0.8) * 0.5;
			orb.y += Math.cos(orbTimer + orb.ID * 0.8) * 0.3;
			orb.alpha = 0.08 + Math.sin(orbTimer * 2 + orb.ID) * 0.04;
			orb.angle += elapsed * (5 + orb.ID * 2);
		}

		for (shape in floatingShapes)
		{
			shape.y += Math.sin(floatTimer * 0.8 + shape.ID * 0.5) * 0.3;
			shape.x += Math.cos(floatTimer * 0.6 + shape.ID * 0.5) * 0.2;
			shape.alpha = 0.1 + Math.sin(floatTimer * 2 + shape.ID) * 0.05;
			shape.angle += elapsed * (10 + shape.ID);
		}

		if (headerGlow != null)
			headerGlow.alpha = 0.5 + Math.sin(waveTimer) * 0.2;

		var lerpVal:Float = Math.max(0, Math.min(1, elapsed * 6));
		camFollowPos.setPosition(
			FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal),
			FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal)
		);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			_exiting = true;
			_stopMusic();
			if (onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			_openSubstate(_options[curSelected]);
		}
		else if (controls.UI_LEFT_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			_applyCarousel(_wrapIdx(curSelected - 1), -1);
			_updateDescBar();
		}
		else if (controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			_applyCarousel(_wrapIdx(curSelected + 1), 1);
			_updateDescBar();
		}

		var cPressed = (touchPad != null && touchPad.buttonC != null
		                && touchPad.buttonC.justPressed);
		if (cPressed || (FlxG.keys.justPressed.CONTROL && controls.mobileC))
		{
			persistentUpdate = false;
			removeTouchPad();
			openSubState(new mobile.substates.MobileControlSelectSubState());
		}
	}

	override function destroy()
	{
		if (_musicLayer != null) { _musicLayer.stop(); _musicLayer.destroy(); }
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}