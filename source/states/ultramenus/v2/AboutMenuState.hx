package states.ultramenus.v2;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import lime.app.Application;
import states.MusicBeatState;

class AboutMenuState extends MusicBeatState
{
	static final PRIMARY:FlxColor = 0xFF6366F1;
	static final SECONDARY:FlxColor = 0xFF8B5CF6;
	static final ACCENT:FlxColor = 0xFFEC4899;
	static final SUCCESS:FlxColor = 0xFF10B981;
	static final WARNING:FlxColor = 0xFFF59E0B;
	static final DARK:FlxColor = 0xFF0F0F23;
	static final CARD_BG:FlxColor = 0x8818182B;
	
	var bg:FlxSprite;
	var bgGrid:FlxBackdrop;
	var headerBar:FlxSprite;
	var titleText:FlxText;
	var backButton:FlxSprite;
	var backText:FlxText;
	
	var contentPanel:FlxSprite;
	var scrollBar:FlxSprite;
	var scrollHandle:FlxSprite;
	
	var sections:Array<AboutSection> = [];
	var currentScroll:Float = 0;
	var targetScroll:Float = 0;
	var maxScroll:Float = 0;
	
	var selectedSomethin:Bool = false;
	var camFollow:FlxObject;
	var ambientTime:Float = 0;
	var isDragging:Bool = false;
	var dragStartY:Float = 0;
	var dragStartScroll:Float = 0;
	
	override function create()
	{
		super.create();
		
		persistentUpdate = persistentDraw = true;
		
		createBackground();
		createHeader();
		createContent();
		createScrollBar();
		setupCamera();
		
		FlxG.camera.fade(FlxColor.BLACK, 0.5, true);
		playIntroAnimation();
	}
	
	function createBackground()
	{
		bg = FlxGradient.createGradientFlxSprite(
			FlxG.width, FlxG.height,
			[DARK, 0xFF1A1A3E, 0xFF16213E, DARK],
			[0, 0.3, 0.7, 1], 1
		);
		add(bg);
		
		bgGrid = new FlxBackdrop(Paths.image('menu/grid'), 1, 1);
		bgGrid.velocity.set(8, 6);
		bgGrid.alpha = 0.05;
		add(bgGrid);
	}
	
	function createHeader()
	{
		headerBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0x88000000);
		add(headerBar);
		
		titleText = new FlxText(30, 20, 0, "HAKKINDA", 36);
		titleText.setFormat(Paths.font("vcr.ttf"), 36, PRIMARY, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		titleText.borderSize = 3;
		add(titleText);
		
		backButton = new FlxSprite(FlxG.width - 120, 20).makeGraphic(80, 40, 0x44FFFFFF);
		backButton.alpha = 0.6;
		add(backButton);
		
		backText = new FlxText(FlxG.width - 120, 30, 80, "GERİ", 16);
		backText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		add(backText);
	}
	
	function createContent()
	{
		var panelWidth:Int = Std.int(FlxG.width * 0.8);
		var panelHeight:Int = FlxG.height - 140;
		var panelX:Int = Std.int((FlxG.width - panelWidth) / 2);
		var panelY:Int = 120;
		
		contentPanel = new FlxSprite(panelX, panelY).makeGraphic(panelWidth, panelHeight, 0x4418182B);
		contentPanel.alpha = 0.8;
		add(contentPanel);
		
		// Bölümleri oluştur
		var sectionY:Float = 20;
		
		// Engine Bilgisi
		sections.push(new AboutSection(
			"🚀 PSYCH ENGINE ULTRA",
			"Next Generation Friday Night Funkin' Engine\n\n" +
			"Psych Engine Ultra, Friday Night Funkin' için geliştirilmiş\n" +
			"yenilikçi ve modern bir oyun motorudur. Klasik Psych Engine\n" +
			"deneyimini alıp下一代 teknolojiyle birleştirir.",
			PRIMARY,
			panelX + 30,
			sectionY,
			panelWidth - 60
		));
		sectionY += 180;
		
		// Özellikler
		sections.push(new AboutSection(
			"✨ ÖZELLİKLER",
			"• Modern ve şık arayüz\n" +
			"• Gelişmiş partikül efektleri\n" +
			"• Kategori tabanlı menü sistemi\n" +
			"• Interactive gallery ve ekstralar\n" +
			"• Gelişmiş animasyon sistemleri\n" +
			"• Türkçe dil desteği\n" +
			"• Özelleştirilebilir tema sistemi",
			SUCCESS,
			panelX + 30,
			sectionY,
			panelWidth - 60
		));
		sectionY += 200;
		
		// Versiyon Bilgisi
		var version = Application.current.meta.get('version');
		sections.push(new AboutSection(
			"📋 VERSİYON BİLGİSİ",
			"Psych Engine Ultra v2.0.0\n" +
			"Friday Night Funkin' v$version\n\n" +
			"Build Date: ${Date.now().toString()}\n" +
			"Platform: ${#if windows Windows #else Linux #end}\n" +
			"Compiler: Haxe ${haxe.Info.version}",
			WARNING,
			panelX + 30,
			sectionY,
			panelWidth - 60
		));
		sectionY += 160;
		
		// Kredi Bilgisi
		sections.push(new AboutSection(
			"👥 EMEĞİ GEÇENLER",
			"• Original Psych Engine: Shadow Mario\n" +
			"• Friday Night Funkin': ninjamuffin99\n" +
			"• Ultra V2 Design: AI Assistant\n" +
			"• Turkish Localization: Community\n" +
			"• Special Thanks: All Contributors",
			SECONDARY,
			panelX + 30,
			sectionY,
			panelWidth - 60
		));
		sectionY += 140;
		
		// Teşekkür
		sections.push(new AboutSection(
			"💝 TEŞEKKÜRLER",
			"Bu motoru kullanan, test eden ve gelişimine katkıda\n" +
			"bulunan herkese teşekkür ederiz. Psych Engine Ultra,\n" +
			"community'nin gücüyle hayata geçirilmiştir.",
			ACCENT,
			panelX + 30,
			sectionY,
			panelWidth - 60
		));
		sectionY += 120;
		
		// Bölümleri sahneye ekle
		for (section in sections)
		{
			add(section.title);
			add(section.content);
		}
		
		maxScroll = Math.max(0, sectionY - (panelHeight - 40));
	}
	
	function createScrollBar()
	{
		var barWidth:Int = 8;
		var barHeight:Int = FlxG.height - 160;
		var barX:Int = FlxG.width - 30;
		var barY:Int = 140;
		
		scrollBar = new FlxSprite(barX, barY).makeGraphic(barWidth, barHeight, 0x44FFFFFF);
		scrollBar.alpha = 0.6;
		add(scrollBar);
		
		var handleHeight:Int = Std.int(Math.max(30, barHeight * (1 - maxScroll / 500)));
		scrollHandle = new FlxSprite(barX, barY).makeGraphic(barWidth, handleHeight, PRIMARY);
		scrollHandle.alpha = 0.8;
		add(scrollHandle);
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
		
		contentPanel.alpha = 0;
		contentPanel.scale.set(0.9, 0.9);
		FlxTween.tween(contentPanel, {alpha: 0.8, "scale.x": 1, "scale.y": 1}, 0.6, {ease: FlxEase.backOut, startDelay: 0.3});
		
		for (i in 0...sections.length)
		{
			var section = sections[i];
			section.title.alpha = 0;
			section.content.alpha = 0;
			
			FlxTween.tween(section.title, {alpha: 1}, 0.4, {startDelay: 0.5 + i * 0.1});
			FlxTween.tween(section.content, {alpha: 0.9}, 0.4, {startDelay: 0.6 + i * 0.1});
		}
		
		scrollBar.alpha = 0;
		scrollHandle.alpha = 0;
		FlxTween.tween(scrollBar, {alpha: 0.6}, 0.4, {startDelay: 0.8});
		FlxTween.tween(scrollHandle, {alpha: 0.8}, 0.4, {startDelay: 0.8});
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		ambientTime += elapsed;
		
		bgGrid.x -= 8 * elapsed;
		bgGrid.y -= 6 * elapsed;
		
		var breathe = 1 + Math.sin(ambientTime * 1.5) * 0.02;
		titleText.scale.set(breathe, breathe);
		
		updateScrolling(elapsed);
		updateScrollBar();
		updateInteractions();
		
		if (!selectedSomethin)
		{
			handleInput();
		}
	}
	
	function updateScrolling(elapsed:Float)
	{
		// Smooth scrolling
		currentScroll = FlxMath.lerp(currentScroll, targetScroll, 0.15);
		
		// Update section positions
		for (section in sections)
		{
			section.title.y = section.originalY - currentScroll + 140;
			section.content.y = section.originalY + 35 - currentScroll + 140;
			
			// Fade in/out based on visibility
			var panelTop = 140;
			var panelBottom = FlxG.height - 20;
			var titleCenter = section.title.y + section.title.height / 2;
			var contentCenter = section.content.y + section.content.height / 2;
			
			if (titleCenter >= panelTop && titleCenter <= panelBottom)
			{
				section.title.alpha = FlxMath.lerp(section.title.alpha, 1, 0.1);
			}
			else
			{
				section.title.alpha = FlxMath.lerp(section.title.alpha, 0, 0.1);
			}
			
			if (contentCenter >= panelTop && contentCenter <= panelBottom)
			{
				section.content.alpha = FlxMath.lerp(section.content.alpha, 0.9, 0.1);
			}
			else
			{
				section.content.alpha = FlxMath.lerp(section.content.alpha, 0, 0.1);
			}
		}
	}
	
	function updateScrollBar()
	{
		if (maxScroll > 0)
		{
			var scrollRatio = currentScroll / maxScroll;
			var maxHandleY = scrollBar.y + scrollBar.height - scrollHandle.height;
			scrollHandle.y = scrollBar.y + (maxHandleY - scrollBar.y) * scrollRatio;
		}
	}
	
	function updateInteractions()
	{
		// Mouse wheel scrolling
		if (FlxG.mouse.wheel != 0)
		{
			targetScroll -= FlxG.mouse.wheel * 20;
			targetScroll = FlxMath.bound(targetScroll, 0, maxScroll);
		}
		
		// Scroll handle dragging
		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		
		var isOverHandle = mouseX >= scrollHandle.x && mouseX <= scrollHandle.x + scrollHandle.width &&
						  mouseY >= scrollHandle.y && mouseY <= scrollHandle.y + scrollHandle.height;
		
		if (isOverHandle)
		{
			scrollHandle.alpha = FlxMath.lerp(scrollHandle.alpha, 1, 0.2);
			scrollHandle.color = FlxMath.lerpColor(scrollHandle.color, SECONDARY, 0.2);
			
			if (FlxG.mouse.justPressed)
			{
				isDragging = true;
				dragStartY = mouseY;
				dragStartScroll = currentScroll;
			}
		}
		else
		{
			scrollHandle.alpha = FlxMath.lerp(scrollHandle.alpha, 0.8, 0.2);
			scrollHandle.color = FlxMath.lerpColor(scrollHandle.color, PRIMARY, 0.2);
		}
		
		if (isDragging)
		{
			if (FlxG.mouse.pressed)
			{
				var dragDistance = mouseY - dragStartY;
				var scrollRatio = dragDistance / (scrollBar.height - scrollHandle.height);
				targetScroll = dragStartScroll + scrollRatio * maxScroll;
				targetScroll = FlxMath.bound(targetScroll, 0, maxScroll);
			}
			else
			{
				isDragging = false;
			}
		}
		
		// Back button hover
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
	
	function handleInput()
	{
		// Keyboard scrolling
		if (controls.UI_UP_P)
		{
			targetScroll -= 100;
			targetScroll = FlxMath.bound(targetScroll, 0, maxScroll);
		}
		else if (controls.UI_DOWN_P)
		{
			targetScroll += 100;
			targetScroll = FlxMath.bound(targetScroll, 0, maxScroll);
		}
		
		// Page scrolling
		if (controls.UI_LEFT_P)
		{
			targetScroll = 0;
		}
		else if (controls.UI_RIGHT_P)
		{
			targetScroll = maxScroll;
		}
		
		if (controls.BACK)
		{
			goBack();
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
		
		FlxTween.cancelTweensOf(titleText.scale);
		titleText.scale.set(1.06, 1.06);
		FlxTween.tween(titleText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});
		
		// Content panel beat
		FlxTween.cancelTweensOf(contentPanel);
		contentPanel.color = PRIMARY;
		FlxTween.color(contentPanel, 0.3, PRIMARY, 0x4418182B);
	}
}

class AboutSection
{
	public var title:FlxText;
	public var content:FlxText;
	public var originalY:Float;
	
	public function new(titleText:String, contentText:String, color:FlxColor, x:Float, y:Float, width:Int)
	{
		originalY = y;
		
		title = new FlxText(x, y, width, titleText, 24);
		title.setFormat(Paths.font("vcr.ttf"), 24, color, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		title.borderSize = 2;
		
		content = new FlxText(x, y + 35, width, contentText, 16);
		content.setFormat(Paths.font("vcr.ttf"), 16, 0xFFCCCCCC, LEFT);
		content.wordWrap = true;
	}
}
