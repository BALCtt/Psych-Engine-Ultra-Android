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
import flixel.addons.display.FlxBackdrop;
import states.MusicBeatState;

class GalleryMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;
	public static var curCategory:Int = 0;
	
	var categories:Array<Array<GalleryItem>> = [
		// Concept Art
		[
			new GalleryItem('boyfriend_concept', 'Boyfriend Concept', 'Karakterin ilk taslakları'),
			new GalleryItem('gf_concept', 'GF Concept', 'Girlfriend konsepti'),
			new GalleryItem('daddy_concept', 'Daddy Dearest', 'Daddy Dearest tasarımları'),
			new GalleryItem('mommy_concept', 'Mommy Mearest', 'Mommy Mearest konsepti'),
			new GalleryItem('monster_concept', 'Monster', 'Monster karakter taslakları')
		],
		// Backgrounds
		[
			new GalleryItem('week1_bg', 'Week 1 Background', 'Parking sahnesi'),
			new GalleryItem('week2_bg', 'Week 2 Background', 'Alley sahnesi'),
			new GalleryItem('week3_bg', 'Week 3 Background', 'Metro sahnesi'),
			new GalleryItem('week4_bg', 'Week 4 Background', 'Liman sahnesi'),
			new GalleryItem('week5_bg', 'Week 5 Background', 'Okul sahnesi'),
			new GalleryItem('week6_bg', 'Week 6 Background', 'Satan sahnesi'),
			new GalleryItem('week7_bg', 'Week 7 Background', 'Tankman sahnesi')
		],
		// Special
		[
			new GalleryItem('title_screen', 'Title Screen', 'Ana ekran konsepti'),
			new GalleryItem('menu_assets', 'Menu Assets', 'Menü grafikleri'),
			new GalleryItem('ui_elements', 'UI Elements', 'Arayüz elementleri'),
			new GalleryItem('notes_and_arrows', 'Notes & Arrows', 'Not ve ok tasarımları'),
			new GalleryItem('special_effects', 'Special Effects', 'Özel efektler')
		]
	];
	
	var categoryNames:Array<String> = ['CONCEPT ART', 'ARKA PLANLAR', 'ÖZEL'];
	var categoryIcons:Array<String> = ['🎨', '🏞️', '✨'];
	
	static final PRIMARY:FlxColor = 0xFF6366F1;
	static final SECONDARY:FlxColor = 0xFF8B5CF6;
	static final ACCENT:FlxColor = 0xFFEC4899;
	static final DARK:FlxColor = 0xFF0F0F23;
	static final CARD_BG:FlxColor = 0x8818182B;
	
	var bg:FlxSprite;
	var bgGrid:FlxBackdrop;
	var headerBar:FlxSprite;
	var titleText:FlxText;
	var backButton:FlxSprite;
	var backText:FlxText;
	
	var categoryTabs:Array<FlxSprite> = [];
	var categoryTexts:Array<FlxText> = [];
	var categoryIndicator:FlxSprite;
	
	var galleryItems:Array<GalleryCard> = [];
	var selectedItem:GalleryCard = null;
	var viewerPanel:FlxSprite;
	var viewerImage:FlxSprite;
	var viewerTitle:FlxText;
	var viewerDesc:FlxText;
	var viewerClose:FlxSprite;
	var viewerCloseText:FlxText;
	
	var selectedSomethin:Bool = false;
	var camFollow:FlxObject;
	var ambientTime:Float = 0;
	var isViewerOpen:Bool = false;
	
	override function create()
	{
		super.create();
		
		persistentUpdate = persistentDraw = true;
		
		createBackground();
		createHeader();
		createCategories();
		createGalleryItems();
		createViewer();
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
		bgGrid.velocity.set(10, 8);
		bgGrid.alpha = 0.06;
		add(bgGrid);
	}
	
	function createHeader()
	{
		headerBar = new FlxSprite(0, 0).makeGraphic(FlxG.width, 80, 0x88000000);
		add(headerBar);
		
		titleText = new FlxText(30, 20, 0, "GALERİ", 36);
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
	
	function createCategories()
	{
		var tabWidth:Int = 150;
		var startX:Int = Std.int((FlxG.width - (tabWidth * 3)) / 2);
		
		for (i in 0...categories.length)
		{
			var tab = new FlxSprite(startX + i * tabWidth, 85).makeGraphic(tabWidth - 10, 35, 0x44FFFFFF);
			tab.alpha = i == curCategory ? 0.3 : 0.1;
			add(tab);
			categoryTabs.push(tab);
			
			var text = new FlxText(startX + i * tabWidth, 90, tabWidth - 10, categoryNames[i], 14);
			text.setFormat(Paths.font("vcr.ttf"), 14, i == curCategory ? PRIMARY : 0xFFAAAAAA, CENTER);
			add(text);
			categoryTexts.push(text);
		}
		
		categoryIndicator = new FlxSprite(startX, 118).makeGraphic(tabWidth - 10, 2, PRIMARY);
		add(categoryIndicator);
	}
	
	function createGalleryItems()
	{
		updateGalleryItems();
	}
	
	function updateGalleryItems()
	{
		// Mevcut itemları temizle
		for (item in galleryItems)
		{
			remove(item.bg);
			remove(item.image);
			remove(item.title);
			remove(item.desc);
		}
		galleryItems = [];
		
		var currentCategory = categories[curCategory];
		var cardWidth:Int = 180;
		var cardHeight:Int = 140;
		var cols:Int = 4;
		var spacingX:Int = 20;
		var spacingY:Int = 20;
		var startX:Int = Std.int((FlxG.width - (cols * cardWidth + (cols - 1) * spacingX)) / 2);
		var startY:Int = 150;
		
		for (i in 0...currentCategory.length)
		{
			var col = i % cols;
			var row = Std.int(i / cols);
			var x = startX + col * (cardWidth + spacingX);
			var y = startY + row * (cardHeight + spacingY);
			
			var item = new GalleryCard(x, y, cardWidth, cardHeight, currentCategory[i]);
			galleryItems.push(item);
			
			add(item.bg);
			add(item.image);
			add(item.title);
			add(item.desc);
		}
	}
	
	function createViewer()
	{
		// Viewer panel (başlangıçta gizli)
		viewerPanel = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
		viewerPanel.alpha = 0;
		add(viewerPanel);
		
		viewerImage = new FlxSprite();
		viewerImage.alpha = 0;
		add(viewerImage);
		
		viewerTitle = new FlxText(0, 100, FlxG.width, "", 32);
		viewerTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		viewerTitle.borderSize = 3;
		viewerTitle.alpha = 0;
		add(viewerTitle);
		
		viewerDesc = new FlxText(0, 150, FlxG.width - 100, "", 18);
		viewerDesc.setFormat(Paths.font("vcr.ttf"), 18, 0xFFCCCCCC, CENTER);
		viewerDesc.screenCenter(X);
		viewerDesc.alpha = 0;
		add(viewerDesc);
		
		viewerClose = new FlxSprite(FlxG.width - 100, 50).makeGraphic(60, 40, 0x44FFFFFF);
		viewerClose.alpha = 0;
		add(viewerClose);
		
		viewerCloseText = new FlxText(FlxG.width - 100, 60, 60, "X", 20);
		viewerCloseText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
		viewerCloseText.alpha = 0;
		add(viewerCloseText);
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
		
		for (i in 0...categoryTabs.length)
		{
			categoryTabs[i].y = 85 - 30;
			categoryTexts[i].y = 90 - 30;
			
			FlxTween.tween(categoryTabs[i], {y: 85}, 0.5, {ease: FlxEase.backOut, startDelay: 0.2 + i * 0.1});
			FlxTween.tween(categoryTexts[i], {y: 90}, 0.5, {ease: FlxEase.backOut, startDelay: 0.2 + i * 0.1});
		}
		
		for (i in 0...galleryItems.length)
		{
			var item = galleryItems[i];
			item.bg.alpha = 0;
			item.bg.scale.set(0.8, 0.8);
			
			FlxTween.tween(item.bg, {alpha: 0.8, "scale.x": 1, "scale.y": 1}, 0.5, {
				ease: FlxEase.backOut,
				startDelay: 0.4 + i * 0.05
			});
			
			FlxTween.tween(item.image, {alpha: 1}, 0.4, {startDelay: 0.5 + i * 0.05});
			FlxTween.tween(item.title, {alpha: 1}, 0.4, {startDelay: 0.6 + i * 0.05});
			FlxTween.tween(item.desc, {alpha: 0.8}, 0.4, {startDelay: 0.7 + i * 0.05});
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		ambientTime += elapsed;
		
		bgGrid.x -= 10 * elapsed;
		bgGrid.y -= 8 * elapsed;
		
		var breathe = 1 + Math.sin(ambientTime * 1.5) * 0.02;
		titleText.scale.set(breathe, breathe);
		
		updateCategoryIndicator();
		updateGalleryInteractions();
		updateViewerInteractions();
		
		if (!selectedSomethin && !isViewerOpen)
		{
			handleInput();
		}
		
		if (isViewerOpen)
		{
			handleViewerInput();
		}
	}
	
	function updateCategoryIndicator()
	{
		if (categoryTabs.length > 0)
		{
			var targetX = categoryTabs[curCategory].x;
			categoryIndicator.x = FlxMath.lerp(categoryIndicator.x, targetX, 0.2);
		}
	}
	
	function updateGalleryInteractions()
	{
		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		
		for (i in 0...galleryItems.length)
		{
			var item = galleryItems[i];
			var isHovering = mouseX >= item.bg.x && mouseX <= item.bg.x + item.bg.width &&
							mouseY >= item.bg.y && mouseY <= item.bg.y + item.bg.height;
			
			var targetAlpha:Float = 0.8;
			var targetScale:Float = 1;
			
			if (i == curSelected)
			{
				targetAlpha = 1;
				targetScale = 1.05;
			}
			else if (isHovering)
			{
				targetAlpha = 0.9;
				targetScale = 1.02;
			}
			else
			{
				targetAlpha = 0.6;
				targetScale = 0.95;
			}
			
			item.bg.alpha = FlxMath.lerp(item.bg.alpha, targetAlpha, 0.15);
			item.bg.scale.set(
				FlxMath.lerp(item.bg.scale.x, targetScale, 0.15),
				FlxMath.lerp(item.bg.scale.y, targetScale, 0.15)
			);
			
			if (isHovering && FlxG.mouse.justPressed && curSelected != i)
			{
				curSelected = i;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
			}
		}
	}
	
	function updateViewerInteractions()
	{
		if (!isViewerOpen) return;
		
		var mouseX = FlxG.mouse.screenX;
		var mouseY = FlxG.mouse.screenY;
		
		// Close button hover
		if (mouseX >= viewerClose.x && mouseX <= viewerClose.x + viewerClose.width &&
			mouseY >= viewerClose.y && mouseY <= viewerClose.y + viewerClose.height)
		{
			viewerClose.alpha = FlxMath.lerp(viewerClose.alpha, 0.9, 0.2);
			viewerCloseText.color = FlxMath.lerpColor(viewerCloseText.color, ACCENT, 0.2);
			
			if (FlxG.mouse.justPressed)
			{
				closeViewer();
			}
		}
		else
		{
			viewerClose.alpha = FlxMath.lerp(viewerClose.alpha, 0.6, 0.2);
			viewerCloseText.color = FlxMath.lerpColor(viewerCloseText.color, FlxColor.WHITE, 0.2);
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
			changeSelection(-4);
		}
		else if (controls.UI_DOWN_P)
		{
			changeSelection(4);
		}
		
		// Kategori değiştirme (Q/E)
		if (controls.UI_LEFT_P && FlxG.keys.pressed.SHIFT)
		{
			changeCategory(-1);
		}
		else if (controls.UI_RIGHT_P && FlxG.keys.pressed.SHIFT)
		{
			changeCategory(1);
		}
		
		if (controls.ACCEPT)
		{
			openViewer();
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
	
	function handleViewerInput()
	{
		if (controls.BACK || controls.ACCEPT)
		{
			closeViewer();
		}
	}
	
	function changeSelection(change:Int)
	{
		curSelected += change;
		
		if (curSelected >= galleryItems.length) curSelected = 0;
		if (curSelected < 0) curSelected = galleryItems.length - 1;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	
	function changeCategory(change:Int)
	{
		curCategory += change;
		if (curCategory >= categories.length) curCategory = 0;
		if (curCategory < 0) curCategory = categories.length - 1;
		
		curSelected = 0;
		updateGalleryItems();
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		for (i in 0...categoryTabs.length)
		{
			var targetAlpha = (i == curCategory) ? 0.3 : 0.1;
			FlxTween.tween(categoryTabs[i], {alpha: targetAlpha}, 0.3);
			
			var targetColor = (i == curCategory) ? PRIMARY : 0xFFAAAAAA;
			FlxTween.color(categoryTexts[i], 0.3, categoryTexts[i].color, targetColor);
		}
	}
	
	function openViewer()
	{
		if (galleryItems.length == 0) return;
		
		selectedItem = galleryItems[curSelected];
		isViewerOpen = true;
		
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		// Viewer'ı aç
		FlxTween.tween(viewerPanel, {alpha: 1}, 0.3);
		
		// İçeriği yükle
		viewerTitle.text = selectedItem.item.title;
		viewerDesc.text = selectedItem.item.description;
		
		// Resim yükle (örnek olarak placeholder)
		try
		{
			viewerImage.loadGraphic(Paths.image('gallery/${selectedItem.item.id}'));
		}
		catch (e)
		{
			viewerImage.makeGraphic(400, 300, 0x44FFFFFF);
		}
		
		viewerImage.screenCenter();
		viewerImage.setGraphicSize(Std.int(FlxG.width * 0.6), 0);
		viewerImage.updateHitbox();
		
		// Animasyonlar
		viewerImage.alpha = 0;
		viewerImage.scale.set(0.8, 0.8);
		FlxTween.tween(viewerImage, {alpha: 1, "scale.x": 1, "scale.y": 1}, 0.4, {ease: FlxEase.backOut});
		
		viewerTitle.alpha = 0;
		viewerTitle.y = 50;
		FlxTween.tween(viewerTitle, {alpha: 1, y: 100}, 0.4, {ease: FlxEase.backOut, startDelay: 0.1});
		
		viewerDesc.alpha = 0;
		FlxTween.tween(viewerDesc, {alpha: 1}, 0.4, {startDelay: 0.2});
		
		viewerClose.alpha = 0;
		viewerCloseText.alpha = 0;
		FlxTween.tween(viewerClose, {alpha: 0.8}, 0.3, {startDelay: 0.3});
		FlxTween.tween(viewerCloseText, {alpha: 1}, 0.3, {startDelay: 0.3});
	}
	
	function closeViewer()
	{
		isViewerOpen = false;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		
		FlxTween.tween(viewerPanel, {alpha: 0}, 0.3);
		FlxTween.tween(viewerImage, {alpha: 0, "scale.x": 0.8, "scale.y": 0.8}, 0.3);
		FlxTween.tween(viewerTitle, {alpha: 0, y: 50}, 0.3);
		FlxTween.tween(viewerDesc, {alpha: 0}, 0.3);
		FlxTween.tween(viewerClose, {alpha: 0}, 0.3);
		FlxTween.tween(viewerCloseText, {alpha: 0}, 0.3);
	}
	
	function goBack()
	{
		if (isViewerOpen)
		{
			closeViewer();
			return;
		}
		
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		
		FlxTween.tween(FlxG.camera, {alpha: 0}, 0.3, {
			onComplete: function(t:FlxTween) {
				MusicBeatState.switchState(new ExtrasMenuState());
			}
		});
	}
	
	override function beatHit()
	{
		super.beatHit();
		
		FlxTween.cancelTweensOf(titleText.scale);
		titleText.scale.set(1.06, 1.06);
		FlxTween.tween(titleText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});
		
		if (galleryItems.length > 0 && !isViewerOpen)
		{
			var selectedItem = galleryItems[curSelected];
			FlxTween.cancelTweensOf(selectedItem.bg.scale);
			selectedItem.bg.scale.set(1.1, 1.1);
			FlxTween.tween(selectedItem.bg.scale, {x: 1.05, y: 1.05}, 0.4, {ease: FlxEase.quadOut});
		}
	}
}

class GalleryItem
{
	public var id:String;
	public var title:String;
	public var description:String;
	
	public function new(id:String, title:String, description:String)
	{
		this.id = id;
		this.title = title;
		this.description = description;
	}
}

class GalleryCard
{
	public var bg:FlxSprite;
	public var image:FlxSprite;
	public var title:FlxText;
	public var desc:FlxText;
	public var item:GalleryItem;
	
	public function new(x:Float, y:Float, width:Int, height:Int, item:GalleryItem)
	{
		this.item = item;
		
		// Kart arka planı
		bg = new FlxSprite(x, y);
		bg.makeGraphic(width, height, 0x8818182B);
		bg.updateHitbox();
		
		// Resim alanı
		image = new FlxSprite(x + 5, y + 5);
		image.makeGraphic(width - 10, Std.int(height * 0.6), 0x44FFFFFF);
		
		// Başlık
		title = new FlxText(x + 10, y + height - 40, width - 20, item.title, 14);
		title.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		title.borderSize = 1;
		
		// Açıklama
		desc = new FlxText(x + 10, y + height - 22, width - 20, item.description, 10);
		desc.setFormat(Paths.font("vcr.ttf"), 10, 0xFFCCCCCC, LEFT);
	}
}
