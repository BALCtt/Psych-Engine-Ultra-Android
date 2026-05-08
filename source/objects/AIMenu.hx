package objects;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.Assets;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldType;
import openfl.text.TextFormatAlign;
import openfl.geom.ColorTransform;
import openfl.Lib;
import haxe.Timer;
import haxe.Http;
import haxe.Json;

class AIMenu extends Sprite {

	static inline var API_KEY:String  = "AIzaSyD2tuwrwPbHYUF5I_smOKuCXWqFZg2UrqM";
	static inline var API_URL:String  = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=";

	private static var _instance:AIMenu = null;

	public static function getInstance():AIMenu {
		if (_instance == null) _instance = new AIMenu();
		return _instance;
	}

	public static function addToStage():Void {
		var inst = getInstance();
		if (inst.parent == null)
			Lib.current.stage.addChild(inst);
	}

	static inline var SYSTEM_PROMPT:String =
		"Sen 'Psych AI 2.5' adında, Gemini 2.5 Flash mimarisiyle güçlendirilmiş bir yardımcı yapay zekasın. " +
		"Friday Night Funkin' ve Psych Engine (Haxe, Lua, GLSL) konularında ileri düzey uzmansın. " +
		"Kullanıcıya teknik çözümler sunarken kod bloklarını temiz tut. Yanıtların hızlı ve etkili olmalı.";

	public static var menuScale:Float = 1.0;

	static inline var MENU_W:Int    = 380;
	static inline var MENU_H:Int    = 560;
	static inline var HEADER_H:Int  = 58;
	static inline var CHAT_H:Int    = 350;
	static inline var INPUT_H:Int   = 42;
	static inline var ICON_SIZE:Int = 80;

	static inline var COL_ACCENT:Int     = 0x00AEEF;
	static inline var COL_DARK:Int       = 0x0D0D0D;
	static inline var COL_PANEL:Int      = 0x1A1A2E;
	static inline var COL_INPUT_BG:Int   = 0x252540;
	static inline var COL_BUBBLE_AI:Int  = 0x1A2A4A;
	static inline var COL_BUBBLE_USR:Int = 0x1A3A2A;
	static inline var COL_SEND:Int       = 0x0078D4;
	static inline var COL_ICON_BG:Int    = 0x000000;

	private var icon:Sprite;
	private var container:Sprite;
	private var chatLayer:Sprite;
	private var chatMask:Shape;
	private var inputField:TextField;
	private var sendBtn:Sprite;
	private var statusTf:TextField;

	private var isDragging:Bool       = false;
	private var lastMouseY:Float      = 0;
	private var scrollDist:Float      = 0;
	private var chatScrollY:Float     = 0;
	private var startX:Float;
	private var startY:Float;

	private var history:Array<Dynamic> = [];
	private var isWaiting:Bool = false;
	private var chatContentH:Float = 0;

	public function new(startX:Float = 160, startY:Float = 50) {
		super();
		this.startX = startX;
		this.startY = startY;
		if (stage != null) init();
		else addEventListener(Event.ADDED_TO_STAGE, function(_) init());
	}

	private function init() {
		buildIcon();
		buildContainer();
		updateScale();
	}

	private function buildIcon() {
		icon = new Sprite();
		icon.x = startX;
		icon.y = startY;

		var bg = new Shape();
		bg.graphics.beginFill(COL_ICON_BG, 0.95);
		bg.graphics.drawRoundRect(0, 0, ICON_SIZE, ICON_SIZE, 22, 22);
		icon.addChild(bg);

		var border = new Shape();
		border.graphics.lineStyle(2, COL_ACCENT, 0.6);
		border.graphics.drawRoundRect(0, 0, ICON_SIZE, ICON_SIZE, 22, 22);
		icon.addChild(border);

		try {
			var bitmapData:BitmapData = Assets.getBitmapData("assets/shared/images/pet/peulogo.png");
			if (bitmapData != null) {
				var bitmap = new Bitmap(bitmapData);
				var imgSize = 50;
				bitmap.width = imgSize;
				bitmap.height = imgSize;
				bitmap.x = (ICON_SIZE - imgSize) / 2;
				bitmap.y = 6;
				icon.addChild(bitmap);
			} else {
				var fallbackSym = makeTF(0, 12, "⚡", 28, ICON_SIZE, true);
				icon.addChild(fallbackSym);
			}
		} catch (e:Dynamic) {
			var fallbackSym = makeTF(0, 12, "⚡", 28, ICON_SIZE, true);
			icon.addChild(fallbackSym);
		}

		var lbl = makeTF(0, 58, "AI", 14, ICON_SIZE, true);
		lbl.textColor = COL_ACCENT;
		icon.addChild(lbl);

		var mouseDownX:Float = 0;
		var mouseDownY:Float = 0;

		icon.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
			mouseDownX = e.stageX;
			mouseDownY = e.stageY;
			icon.startDrag();
		});
		icon.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) {
			icon.stopDrag();
			var dx = Math.abs(e.stageX - mouseDownX);
			var dy = Math.abs(e.stageY - mouseDownY);
			if (dx < 8 && dy < 8) toggleMenu(true);
		});

		icon.buttonMode = true;
		addChild(icon);
	}

	private function buildContainer() {
		container = new Sprite();
		container.visible = false;
		container.alpha   = 0;
		container.x = startX;
		container.y = startY;
		addChild(container);

		var bg = new Shape();
		bg.graphics.beginFill(COL_DARK, 0.97);
		bg.graphics.drawRoundRect(0, 0, MENU_W, MENU_H, 16, 16);
		container.addChild(bg);

		var topLine = new Shape();
		topLine.graphics.beginFill(COL_ACCENT);
		topLine.graphics.drawRoundRect(0, 0, MENU_W, 4, 2, 2);
		container.addChild(topLine);

		buildHeader();
		buildChatArea();
		buildInputBar();
		buildFooterButtons();
	}

	private function buildHeader() {
		var hdr = new Sprite();
		hdr.graphics.beginFill(COL_PANEL, 0.9);
		hdr.graphics.drawRoundRect(0, 4, MENU_W, HEADER_H, 14, 14);
		container.addChild(hdr);

		var logoBg = new Shape();
		logoBg.graphics.beginFill(COL_ICON_BG);
		logoBg.graphics.drawCircle(0, 0, 18);
		logoBg.x = 30;
		logoBg.y = 4 + HEADER_H / 2;
		container.addChild(logoBg);

		var logoRing = new Shape();
		logoRing.graphics.lineStyle(2, COL_ACCENT, 0.8);
		logoRing.graphics.drawCircle(0, 0, 18);
		logoRing.x = 30;
		logoRing.y = 4 + HEADER_H / 2;
		container.addChild(logoRing);

		try {
			var logoBitmapData:BitmapData = Assets.getBitmapData("assets/shared/images/pet/peulogo.png");
			if (logoBitmapData != null) {
				var logoBitmap = new Bitmap(logoBitmapData);
				var logoSize = 28;
				logoBitmap.width = logoSize;
				logoBitmap.height = logoSize;
				logoBitmap.x = 30 - logoSize / 2;
				logoBitmap.y = 4 + HEADER_H / 2 - logoSize / 2;
				container.addChild(logoBitmap);
			} else {
				var fallbackLogo = makeTF(14, 4 + HEADER_H / 2 - 14, "⚡", 16, 32, true);
				container.addChild(fallbackLogo);
			}
		} catch (e:Dynamic) {
			var fallbackLogo = makeTF(14, 4 + HEADER_H / 2 - 14, "⚡", 16, 32, true);
			container.addChild(fallbackLogo);
		}

		var title = makeTF(55, 4 + 8, "Psych AI", 20, 200);
		container.addChild(title);

		var sub = makeTF(55, 4 + 32, "Oyun Asistanı / Yardımcı", 11, 250);
		sub.alpha = 0.55;
		container.addChild(sub);

		var closeBtn = new Sprite();
		closeBtn.graphics.beginFill(0xCC0000, 0.9);
		closeBtn.graphics.drawCircle(0, 0, 14);
		closeBtn.x = MENU_W - 22;
		closeBtn.y = 4 + HEADER_H / 2;
		container.addChild(closeBtn);

		var xLine1 = new Shape();
		xLine1.graphics.lineStyle(3, 0xFFFFFF, 1);
		xLine1.graphics.moveTo(-6, -6);
		xLine1.graphics.lineTo(6, 6);
		xLine1.x = MENU_W - 22;
		xLine1.y = 4 + HEADER_H / 2;
		container.addChild(xLine1);

		var xLine2 = new Shape();
		xLine2.graphics.lineStyle(3, 0xFFFFFF, 1);
		xLine2.graphics.moveTo(6, -6);
		xLine2.graphics.lineTo(-6, 6);
		xLine2.x = MENU_W - 22;
		xLine2.y = 4 + HEADER_H / 2;
		container.addChild(xLine2);

		var closeBtnHit = new Sprite();
		closeBtnHit.graphics.beginFill(0x000000, 0);
		closeBtnHit.graphics.drawCircle(0, 0, 16);
		closeBtnHit.x = MENU_W - 22;
		closeBtnHit.y = 4 + HEADER_H / 2;
		closeBtnHit.buttonMode = true;
		closeBtnHit.addEventListener(MouseEvent.CLICK, function(_) toggleMenu(false));
		container.addChild(closeBtnHit);

		var drag = new Sprite();
		drag.graphics.beginFill(0, 0);
		drag.graphics.drawRect(0, 0, MENU_W - 44, HEADER_H + 4);
		drag.addEventListener(MouseEvent.MOUSE_DOWN, function(_) container.startDrag());
		drag.addEventListener(MouseEvent.MOUSE_UP,   function(_) container.stopDrag());
		container.addChild(drag);

		statusTf = makeTF(10, 4 + HEADER_H + 4, "", 11, MENU_W - 20);
		statusTf.textColor = COL_ACCENT;
		statusTf.alpha = 0.8;
		container.addChild(statusTf);
	}

	private function buildChatArea() {
		var offsetY = HEADER_H + 22;

		chatMask = new Shape();
		chatMask.graphics.beginFill(0xFFFFFF);
		chatMask.graphics.drawRect(0, offsetY, MENU_W, CHAT_H);
		container.addChild(chatMask);

		chatLayer = new Sprite();
		chatLayer.y = offsetY;
		chatLayer.mask = chatMask;
		container.addChild(chatLayer);

		container.addEventListener(MouseEvent.MOUSE_DOWN, onScrollDown);
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onScrollMove);
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP,   onScrollUp);

		addBubble("ai", "Merhaba! Ben Psych AI \nGemini ile çalışan bir asistanım.\nOyunda bir sorun yaşıyorsan veya yardım istiyorsan yardımcı olabilirim!.");
	}

	private function buildInputBar() {
		var barY = HEADER_H + 22 + CHAT_H + 6;

		var barBg = new Shape();
		barBg.graphics.beginFill(COL_PANEL);
		barBg.graphics.drawRoundRect(8, barY, MENU_W - 16, INPUT_H + 8, 10, 10);
		container.addChild(barBg);

		inputField = new TextField();
		var fmt = new TextFormat("_sans", 14, 0xFFFFFF);
		inputField.defaultTextFormat = fmt;
		inputField.type = TextFieldType.INPUT;
		inputField.background = true;
		inputField.backgroundColor = COL_INPUT_BG;
		inputField.border = false;
		inputField.text = "";
		inputField.x = 14;
		inputField.y = barY + 6;
		inputField.width  = MENU_W - 90;
		inputField.height = INPUT_H - 4;
		inputField.multiline = false;
		inputField.wordWrap  = false;

		inputField.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
			if (e.keyCode == Keyboard.ENTER) sendMessage();
		});
		inputField.addEventListener(MouseEvent.MOUSE_UP, function(_) {
			if (!isDragging && stage != null) stage.focus = inputField;
		});
		container.addChild(inputField);

		sendBtn = new Sprite();
		sendBtn.graphics.beginFill(COL_SEND);
		sendBtn.graphics.drawRoundRect(0, 0, 62, INPUT_H - 4, 10, 10);
		sendBtn.x = MENU_W - 76;
		sendBtn.y = barY + 6;
		sendBtn.addChild(makeTF(0, 6, "Gönder", 13, 62, true));
		sendBtn.buttonMode = true;
		sendBtn.addEventListener(MouseEvent.CLICK, function(_) sendMessage());
		container.addChild(sendBtn);
	}

	private function buildFooterButtons() {
		var footerY = MENU_H - 52;

		var clearBtn = makeFooterBtn("🗑 Sohbeti Temizle", 10, footerY, 160, function() {
			history = [];
			while (chatLayer.numChildren > 0) chatLayer.removeChildAt(0);
			chatContentH = 0;
			chatScrollY  = 0;
			chatLayer.y  = Std.int(HEADER_H + 22);
			addBubble("ai", "Sohbet temizlendi. Yeni sorun nedir?");
		});
		container.addChild(clearBtn);

		var minBtn = makeFooterBtn("⬇ Küçült", MENU_W - 170, footerY, 160, function() toggleMenu(false));
		container.addChild(minBtn);
	}

	private function makeFooterBtn(label:String, bx:Float, by:Float, bw:Int, cb:Void->Void):Sprite {
		var btn = new Sprite();
		btn.graphics.beginFill(0x2A2A3A);
		btn.graphics.drawRoundRect(0, 0, bw, 36, 8, 8);
		btn.x = bx;
		btn.y = by;
		btn.addChild(makeTF(0, 7, label, 14, bw, true));
		btn.buttonMode = true;
		btn.addEventListener(MouseEvent.CLICK, function(_) {
			applyFlash(btn);
			cb();
		});
		return btn;
	}

	private function sendMessage() {
		if (isWaiting) return;
		var text = StringTools.trim(inputField.text);
		if (text == "" || text.length < 2) return;

		inputField.text = "";
		if (stage != null) stage.focus = null;

		addBubble("user", text);

		history.push({ role: "user", parts: [{ text: text }] });

		isWaiting = true;
		setStatus("⚡ Psych AI yazıyor...");
		sendBtn.alpha = 0.4;

		callGemini(function(reply:String) {
			history.push({ role: "model", parts: [{ text: reply }] });
			addBubble("ai", reply);
			isWaiting = false;
			setStatus("");
			sendBtn.alpha = 1.0;
		}, function(err:String) {
			addBubble("ai", "⚠️ Hata: " + err + "\nAPI key'ini kontrol et.");
			isWaiting = false;
			setStatus("");
			sendBtn.alpha = 1.0;
		});
	}

	private function callGemini(onSuccess:String->Void, onError:String->Void) {
		var http = new Http(API_URL + API_KEY);

		var payload:Dynamic = {
			contents: history,
			system_instruction: { 
				parts: [{ text: SYSTEM_PROMPT }] 
			},
			generationConfig: {
				temperature: 0.7,
				topK: 40,
				topP: 0.95,
				maxOutputTokens: 1024,
				responseMimeType: "text/plain"
			}
		};

		var body = Json.stringify(payload);
		http.setPostData(body);
		http.setHeader("Content-Type", "application/json");

		http.onStatus = function(status:Int) {
			if (status == 429) {
				setStatus("⚠️ HIZ SINIRI: Lütfen bekleyin...");
				trace("Hata 429: Gemini API Kota Sınırı Aşıldı.");
			}
		};

		http.onData = function(data:String) {
			try {
				var parsed:Dynamic = Json.parse(data);
				
				if (parsed.error != null) {
					var errorMsg = parsed.error.message;
					if (parsed.error.code == 429) {
						setStatus("Limit doldu. 1 dakika sonra tekrar deneyin.");
					}
					onError(errorMsg);
					return;
				}

				var reply:String = parsed.candidates[0].content.parts[0].text;
				onSuccess(reply);
			} catch (e:Dynamic) {
				onError("JSON parse hatası: " + Std.string(e));
			}
		};

		http.onError = function(err:String) {
			if (err.indexOf("429") != -1) {
				setStatus("Çok hızlı yazıyorsun! Biraz yavaşla...");
				onError("Rate Limit Exceeded (429)");
			} else {
				onError("Bağlantı Hatası: " + err);
			}
		};

		http.request(true);
	}

	private function addBubble(role:String, text:String) {
		var isAI    = (role == "ai");
		var bubbleW = MENU_W - 40;
		var pad     = 10;

		var measurer = new TextField();
		measurer.defaultTextFormat = new TextFormat("_sans", 13, 0xFFFFFF);
		measurer.wordWrap  = true;
		measurer.multiline = true;
		measurer.width     = bubbleW - pad * 2;
		measurer.text      = text;
		measurer.height    = measurer.textHeight + 12;

		var bubbleH = measurer.height + pad * 2 + 14;

		var bubble = new Sprite();
		var bg = new Shape();
		bg.graphics.beginFill(isAI ? COL_BUBBLE_AI : COL_BUBBLE_USR, 0.9);
		bg.graphics.drawRoundRect(0, 0, bubbleW, bubbleH, 12, 12);
		bubble.addChild(bg);

		var stripe = new Shape();
		stripe.graphics.beginFill(isAI ? COL_ACCENT : 0x00AA44);
		stripe.graphics.drawRoundRect(0, 0, 3, bubbleH, 2, 2);
		bubble.addChild(stripe);

		var roleLabel = isAI ? "⚡ Psych AI" : "👤 Sen";
		var roleTf = makeTF(pad + 4, pad - 2, roleLabel, 11, bubbleW);
		roleTf.alpha = 0.6;
		bubble.addChild(roleTf);

		var msgTf = new TextField();
		msgTf.defaultTextFormat = new TextFormat("_sans", 13, 0xFFFFFF);
		msgTf.wordWrap   = true;
		msgTf.multiline  = true;
		msgTf.selectable = false;
		msgTf.mouseEnabled = false;
		msgTf.x      = pad + 4;
		msgTf.y      = pad + 14;
		msgTf.width  = bubbleW - pad * 2 - 4;
		msgTf.height = measurer.height;
		msgTf.text   = text;
		bubble.addChild(msgTf);

		bubble.x = 10;
		bubble.y = chatContentH + 6;
		chatLayer.addChild(bubble);

		chatContentH += bubbleH + 10;

		scrollToBottom();
	}

	private function scrollToBottom() {
		var visibleH  = CHAT_H;
		var maxScroll = chatContentH - visibleH;
		if (maxScroll > 0) {
			chatScrollY = maxScroll;
			chatLayer.y = Std.int(HEADER_H + 22) - chatScrollY;
		}
	}

	private function onScrollDown(e:MouseEvent) {
		isDragging = false;
		scrollDist = 0;
		lastMouseY = e.stageY;
	}

	private function onScrollMove(e:MouseEvent) {
		if (!container.visible || !e.buttonDown) return;
		var delta = e.stageY - lastMouseY;
		lastMouseY = e.stageY;
		scrollDist += Math.abs(delta);
		if (scrollDist > 6) {
			isDragging  = true;
			chatScrollY -= delta;
			clampScroll();
			chatLayer.y  = Std.int(HEADER_H + 22) - Std.int(chatScrollY);
		}
	}

	private function onScrollUp(e:MouseEvent) {
		Timer.delay(function() { isDragging = false; }, 50);
	}

	private function clampScroll() {
		if (chatScrollY < 0) chatScrollY = 0;
		var max = chatContentH - CHAT_H;
		if (max > 0 && chatScrollY > max) chatScrollY = max;
		if (max <= 0) chatScrollY = 0;
	}

	private function toggleMenu(show:Bool) {
		if (show) {
			container.visible = true;
			container.alpha   = 0;
			container.x = icon.x;
			container.y = icon.y;
			icon.visible = false;

			var frames = 0;
			var t = new Timer(14);
			t.run = function() {
				container.alpha += 0.12;
				frames++;
				if (frames >= 9) { container.alpha = 1; t.stop(); }
			};

			Timer.delay(function() {
				if (stage != null) stage.focus = inputField;
			}, 150);
		} else {
			icon.x = container.x;
			icon.y = container.y;
			icon.visible = true;
			container.visible = false;
		}
	}

	private function setStatus(msg:String) {
		statusTf.text = msg;
	}

	private function applyFlash(s:Sprite) {
		s.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0, 100, 180, 0);
		Timer.delay(function() { s.transform.colorTransform = new ColorTransform(); }, 120);
	}

	private function makeTF(x:Float, y:Float, str:String, size:Int, w:Float, center:Bool = false):TextField {
		var tf  = new TextField();
		var fmt = new TextFormat("_sans", size, 0xFFFFFF, true);
		if (center) fmt.align = TextFormatAlign.CENTER;
		tf.defaultTextFormat = fmt;
		tf.text = str;
		tf.x = x;
		tf.y = y;
		tf.width = w;
		tf.selectable = false;
		tf.mouseEnabled = false;
		return tf;
	}

	public function updateScale() {
		this.scaleX = this.scaleY = menuScale;
	}
}