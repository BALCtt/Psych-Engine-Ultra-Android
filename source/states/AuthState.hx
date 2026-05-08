package states;

import backend.AuthManager;
import backend.BadWordFilter;
import backend.SupabaseClient;
import backend.ui.PsychUIInputText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

class AuthState extends MusicBeatState {

    // ── Ekran boyutları ──────────────────────────────────────
    static final SW:Int  = 1280;
    static final SH:Int  = 720;

    // ── Panel düzeni ─────────────────────────────────────────
    // Sol panel (branding / dekorasyon)
    static final LEFT_W:Int   = 460;
    // Sağ panel — kart merkezde float eder
    static final CARD_W:Int   = 420;
    static final CARD_H:Int   = 580;
    static final CARD_X:Float = LEFT_W + ((SW - LEFT_W - CARD_W) / 2);
    static final CARD_Y:Float = (720 - CARD_H) / 2;   // dikey orta

    // Input alanı
    static final FIELD_W:Int = 360;
    static final FIELD_H:Int = 46;
    static final FIELD_X:Float = CARD_X + (CARD_W - FIELD_W) / 2;  // kart içinde ortalı

    // ── Renk paleti — "Fractured Neon Retro" ────────────────
    // Çok koyu navy arkaplan, keskin sarı-yeşil + kırmızı-turuncu aksan
    static final C_BG         = 0xFF04040c;   // neredeyse siyah navy
    static final C_LEFT_PANEL = 0xFF06061a;   // sol panel, hafif daha açık
    static final C_CARD       = 0xFF0b0b1f;   // yüzen kart
    static final C_CARD_EDGE  = 0xFF1a1a3a;   // kart kenar çizgisi
    static final C_FIELD_BG   = 0xFF080818;   // input içi
    static final C_FIELD_LINE = 0xFF1e1e40;   // input alt çizgi

    // Aksan renkleri
    static final C_ACCENT1    = 0xFFe8ff3c;   // keskin sarı-lime (ana aksan)
    static final C_ACCENT2    = 0xFFff4d1a;   // turuncu-kırmızı (ikincil)
    static final C_ACCENT3    = 0xFF3cffcc;   // mint/turkuaz (üçüncül)

    // Tipografi
    static final C_WHITE      = 0xFFffffff;
    static final C_OFF_WHITE  = 0xFFd4d4f0;
    static final C_MUTED      = 0xFF4a4a70;
    static final C_DIMMED     = 0xFF2a2a50;

    static final WHY_URL = "https://samedcan1234.github.io/Psych-Engine-Ultra-Android/privacy";

    // ── Ülkeler ───────────────────────────────────────────────
    static final COUNTRIES = [
        "Turkey","United States","United Kingdom",
        "Germany","France","Japan","Brazil","Russia","Other"
    ];

    // ── State değişkenleri ────────────────────────────────────
    var isLogin:Bool = true;

    // Tab butonları
    var tabLoginBg:FlxSprite;
    var tabRegBg:FlxSprite;
    var tabLoginTxt:FlxText;
    var tabRegTxt:FlxText;
    var tabIndicator:FlxSprite;  // hareketli alt çizgi göstergesi

    // Formlar
    var loginGroup:Array<FlxBasic>    = [];
    var registerGroup:Array<FlxBasic> = [];

    var loginUserField:PsychUIInputText;
    var loginPassField:PsychUIInputText;

    var regUserField:PsychUIInputText;
    var regEmailField:PsychUIInputText;
    var regPassField:PsychUIInputText;
    var countryIndex:Int = 0;
    var countryValTxt:FlxText;

    // Why link referansları
    var _loginWhyTxt:FlxText;
    var _regWhyTxt:FlxText;

    // Buton haritası
    var _btnMap:Map<FlxSprite, Void->Void> = new Map();
    var _btnLabels:Array<FlxText> = [];

    // Durum mesajı
    var statusTxt:FlxText;
    var statusBg:FlxSprite;

    // Dekoratif elementler (animasyon için referans)
    var _scanlineAlpha:Float = 0;
    var _glowPulse:Float     = 0;
    var _accentBar:FlxSprite;
    var _cornerTL:FlxSprite;
    var _cornerBR:FlxSprite;
    var _vertTicker:FlxSprite; // sol panelde kayan dikey çizgi

    // Kart giriş animasyonu tamamlandı mı
    var _cardReady:Bool = false;
    var _cardSprite:FlxSprite;

    // ── create ────────────────────────────────────────────────
    override function create() {
        super.create();

        buildBackground();
        buildLeftPanel();
        buildFloatingCard();
        buildRightContent();

        // Status kutusu — kartın altında
        statusBg = new FlxSprite(CARD_X, CARD_Y + CARD_H + 12)
            .makeGraphic(CARD_W, 30, 0xFF1a0000);
        statusBg.visible = false;
        add(statusBg);

        statusTxt = makeText(CARD_X, CARD_Y + CARD_H + 17, CARD_W, "", 11);
        statusTxt.alignment = CENTER;
        statusTxt.color = C_ACCENT2;
        statusTxt.visible = false;
        add(statusTxt);

        // Register inputlarını başta pasif bırak
        regUserField.active  = false;
        regEmailField.active = false;
        regPassField.active  = false;

        switchTab(true);
        playEntryAnim();
    }

    // ── ARKAPLAN ──────────────────────────────────────────────
    function buildBackground() {
        var bg = new FlxSprite().makeGraphic(SW, SH, C_BG);
        add(bg);

        // Yatay ince tarama çizgileri (scanlines) — renk bandları
        // Her 4px'de bir çok ince koyu şerit
        var y = 0;
        while (y < SH) {
            var line = new FlxSprite(0, y).makeGraphic(SW, 1, 0xFF080812);
            line.alpha = 0.35;
            add(line);
            y += 4;
        }

        // Sol üst köşe dekoratif nokta matrisi (3×6 grid)
        var dotStartX:Float = 30;
        var dotStartY:Float = 30;
        for (row in 0...6) {
            for (col in 0...3) {
                var dot = new FlxSprite(dotStartX + col * 14, dotStartY + row * 14)
                    .makeGraphic(3, 3, C_DIMMED);
                dot.alpha = 0.6;
                add(dot);
            }
        }

        // Sağ alt köşe dekoratif nokta matrisi
        for (row in 0...4) {
            for (col in 0...4) {
                var dot = new FlxSprite(SW - 80 + col * 14, SH - 80 + row * 14)
                    .makeGraphic(3, 3, C_DIMMED);
                dot.alpha = 0.5;
                add(dot);
            }
        }

        // Geniş diagonal dekoratif çizgiler (sağ üst köşe)
        for (i in 0...5) {
            var diag = new FlxSprite(SW - 200 + i * 18, 0).makeGraphic(1, 120, C_ACCENT1);
            diag.alpha = 0.04 + i * 0.008;
            diag.angle  = 30;
            add(diag);
        }
    }

    // ── SOL PANEL ─────────────────────────────────────────────
    function buildLeftPanel() {
        // Panel zemini
        var panelBg = new FlxSprite(0, 0).makeGraphic(LEFT_W, SH, C_LEFT_PANEL);
        add(panelBg);

        // Sağ kenar — çift çizgi efekti
        var border1 = new FlxSprite(LEFT_W - 2, 0).makeGraphic(1, SH, C_CARD_EDGE);
        var border2 = new FlxSprite(LEFT_W - 1, 0).makeGraphic(1, SH, C_ACCENT1);
        border1.alpha = 1.0;
        border2.alpha = 0.25;
        add(border1);
        add(border2);

        // Üst yatay aksent şeridi
        var topBar = new FlxSprite(0, 0).makeGraphic(LEFT_W, 3, C_ACCENT1);
        topBar.alpha = 0.7;
        add(topBar);

        // Alt yatay aksent şeridi
        var botBar = new FlxSprite(0, SH - 3).makeGraphic(LEFT_W, 3, C_ACCENT2);
        botBar.alpha = 0.5;
        add(botBar);

        // Kayan dikey accent ticker (ince yatay çizgi - update'de kaydırılacak)
        _vertTicker = new FlxSprite(0, 0).makeGraphic(LEFT_W - 2, 2, C_ACCENT1);
        _vertTicker.alpha = 0.15;
        add(_vertTicker);

        // ── Üst logo bloğu ──
        // "ENGINE" etiket çubuğu — küçük pill
        var pillBg = new FlxSprite(LEFT_W / 2 - 55, 115).makeGraphic(110, 20, C_ACCENT1);
        pillBg.alpha = 0.12;
        add(pillBg);
        var pillBorder = new FlxSprite(LEFT_W / 2 - 55, 115).makeGraphic(110, 1, C_ACCENT1);
        pillBorder.alpha = 0.5;
        add(pillBorder);
        var pillTxt = makeText(LEFT_W / 2 - 55, 117, 110, "◆  PSYCH ENGINE  ◆", 9);
        pillTxt.alignment = CENTER;
        pillTxt.color = C_ACCENT1;
        pillTxt.alpha = 0.85;
        add(pillTxt);

        // Ana başlık — büyük, bold
        var titleA = makeText(0, 140, LEFT_W, "ULTRA", 52);
        titleA.alignment = CENTER;
        titleA.color = C_WHITE;
        add(titleA);

        var titleB = makeText(0, 194, LEFT_W, "EDITION", 28);
        titleB.alignment = CENTER;
        titleB.color = C_ACCENT1;
        titleB.alpha = 0.9;
        add(titleB);

        // Ayraç — asimetrik
        var divL = new FlxSprite(LEFT_W / 2 - 80, 232).makeGraphic(60, 2, C_ACCENT1);
        var divR = new FlxSprite(LEFT_W / 2 + 20, 232).makeGraphic(20, 2, C_ACCENT2);
        add(divL); add(divR);

        // Açıklama metni
        var descTxt = makeText(50, 246, LEFT_W - 100,
            "Online leaderboard, profil sistemi\nve daha fazlası için hesap oluştur.", 12);
        descTxt.alignment = CENTER;
        descTxt.color = C_MUTED;
        add(descTxt);

        // ── İstatistik kartları ── (yatay sıra, 3 kart)
        buildStatCard(28,  330, "∞",    "SONGS",   C_ACCENT1);
        buildStatCard(168, 330, "#1",   "RANKING", C_ACCENT3);
        buildStatCard(308, 330, "GBL",  "GLOBAL",  C_ACCENT2);

        // ── Karakter sprite ──
        var charSprite = new FlxSprite(LEFT_W / 2 - 65, 420);
        try {
            charSprite.loadGraphic(Paths.image('ultra/login/bf'));
            charSprite.setGraphicSize(130, 130);
            charSprite.updateHitbox();
        } catch(e) {
            charSprite.makeGraphic(1, 1, FlxColor.TRANSPARENT);
        }
        add(charSprite);

        // Alt imza metni
        var signTxt = makeText(0, SH - 26, LEFT_W, "v2.0  ·  ULTRA BUILD", 9);
        signTxt.alignment = CENTER;
        signTxt.color = C_DIMMED;
        add(signTxt);
    }

    function buildStatCard(x:Float, y:Float, num:String, lbl:String, accent:Int) {
        // Kart zemin
        var cardW:Int = 114;
        var cardH:Int = 64;

        var bg = new FlxSprite(x, y).makeGraphic(cardW, cardH, C_CARD);
        add(bg);

        // Üst aksent çubuğu
        var topAccent = new FlxSprite(x, y).makeGraphic(cardW, 2, accent);
        topAccent.alpha = 0.8;
        add(topAccent);

        // Sol ince kenar
        var leftEdge = new FlxSprite(x, y).makeGraphic(1, cardH, accent);
        leftEdge.alpha = 0.3;
        add(leftEdge);

        // Sağ/alt kenar
        var rightEdge = new FlxSprite(x + cardW - 1, y).makeGraphic(1, cardH, C_CARD_EDGE);
        var botEdge   = new FlxSprite(x, y + cardH - 1).makeGraphic(cardW, 1, C_CARD_EDGE);
        add(rightEdge); add(botEdge);

        var n = makeText(x, y + 10, cardW, num, 22);
        n.alignment = CENTER;
        n.color = accent;
        add(n);

        var l = makeText(x, y + 40, cardW, lbl, 9);
        l.alignment = CENTER;
        l.color = C_MUTED;
        add(l);
    }

    // ── YÜZEN KART (sağ taraf zemin) ─────────────────────────
    function buildFloatingCard() {
        // Dıştaki glow efekti için hafif daha büyük arka plan
        var glowBg = new FlxSprite(CARD_X - 4, CARD_Y - 4)
            .makeGraphic(CARD_W + 8, CARD_H + 8, C_ACCENT1);
        glowBg.alpha = 0.04;
        add(glowBg);
        _accentBar = glowBg; // pulse için referans

        // Kart arkaplan
        _cardSprite = new FlxSprite(CARD_X, CARD_Y).makeGraphic(CARD_W, CARD_H, C_CARD);
        add(_cardSprite);

        // Kart kenar çizgileri — 4 köşe ayrı ayrı, köşeler boş
        var borderT = new FlxSprite(CARD_X + 20, CARD_Y).makeGraphic(CARD_W - 40, 1, C_CARD_EDGE);
        var borderB = new FlxSprite(CARD_X + 20, CARD_Y + CARD_H - 1).makeGraphic(CARD_W - 40, 1, C_CARD_EDGE);
        var borderL = new FlxSprite(CARD_X, CARD_Y + 20).makeGraphic(1, CARD_H - 40, C_CARD_EDGE);
        var borderR = new FlxSprite(CARD_X + CARD_W - 1, CARD_Y + 20).makeGraphic(1, CARD_H - 40, C_CARD_EDGE);
        add(borderT); add(borderB); add(borderL); add(borderR);

        // Köşe L-şekilleri (dekoratif corner brackets)
        buildCornerBracket(CARD_X,             CARD_Y,             C_ACCENT1, false, false);
        buildCornerBracket(CARD_X + CARD_W,    CARD_Y,             C_ACCENT1, true,  false);
        buildCornerBracket(CARD_X,             CARD_Y + CARD_H,    C_ACCENT2, false, true);
        buildCornerBracket(CARD_X + CARD_W,    CARD_Y + CARD_H,    C_ACCENT2, true,  true);

        // Kart üstü ince aksent çizgisi
        var topLine = new FlxSprite(CARD_X + 20, CARD_Y).makeGraphic(CARD_W - 40, 2, C_ACCENT1);
        topLine.alpha = 0.6;
        add(topLine);
    }

    function buildCornerBracket(x:Float, y:Float, color:Int, flipH:Bool, flipV:Bool) {
        var len:Int = 18;
        var thick:Int = 2;
        var hBar = new FlxSprite(flipH ? x - len : x, flipV ? y - thick : y)
            .makeGraphic(len, thick, color);
        var vBar = new FlxSprite(flipH ? x - thick : x, flipV ? y - len : y)
            .makeGraphic(thick, len, color);
        add(hBar); add(vBar);
    }

    // ── SAĞ İÇERİK (tab + formlar) ────────────────────────────
    function buildRightContent() {
        var innerX = CARD_X + (CARD_W - FIELD_W) / 2;  // FIELD_X ile aynı
        var startY = CARD_Y + 22;

        // ── Üst başlık ──
        var headerTxt = makeText(CARD_X, startY, CARD_W, "HESAP", 10);
        headerTxt.alignment = CENTER;
        headerTxt.color = C_MUTED;
        add(headerTxt);

        startY += 18;

        // ── Tab çubuğu ──
        buildTabBar(innerX, startY);
        startY += 52;

        // ── Login formu ──
        buildLoginForm(innerX, startY);

        // ── Register formu ──
        buildRegisterForm(innerX, startY);
    }

    function buildTabBar(x:Float, y:Float) {
        // Tab zemin
        var tabBg = new FlxSprite(x, y).makeGraphic(FIELD_W, 36, C_FIELD_BG);
        add(tabBg);
        // Tab alt çizgisi
        var tabBot = new FlxSprite(x, y + 35).makeGraphic(FIELD_W, 1, C_CARD_EDGE);
        add(tabBot);

        var halfW:Int = Std.int(FIELD_W / 2);

        tabLoginBg = new FlxSprite(x, y).makeGraphic(halfW, 36, C_FIELD_BG);
        tabRegBg   = new FlxSprite(x + halfW, y).makeGraphic(halfW, 36, C_FIELD_BG);
        add(tabLoginBg);
        add(tabRegBg);

        tabLoginTxt = makeText(x, y + 10, halfW, "GİRİŞ YAP", 11);
        tabLoginTxt.alignment = CENTER;
        tabLoginTxt.color = C_WHITE;

        tabRegTxt = makeText(x + halfW, y + 10, halfW, "KAYIT OL", 11);
        tabRegTxt.alignment = CENTER;
        tabRegTxt.color = C_MUTED;

        add(tabLoginTxt); add(tabRegTxt);

        // Hareketli alt gösterge çizgisi
        tabIndicator = new FlxSprite(x, y + 33).makeGraphic(halfW, 3, C_ACCENT1);
        add(tabIndicator);
    }

    // ── LOGIN FORMU ───────────────────────────────────────────
    function buildLoginForm(x:Float, startY:Float) {
        var ly:Float = startY;

        // Kullanıcı adı
        var luf = buildField(x, ly, "KULLANICI ADI", "bf");
        loginUserField = luf.input;
        loginGroup.push(luf.label); loginGroup.push(luf.bg);
        loginGroup.push(luf.icon);  loginGroup.push(luf.input);
        ly += FIELD_H + 30;

        // Şifre
        var lpf = buildField(x, ly, "ŞİFRE", "password", true);
        loginPassField = lpf.input;
        loginGroup.push(lpf.label); loginGroup.push(lpf.bg);
        loginGroup.push(lpf.icon);  loginGroup.push(lpf.input);
        ly += FIELD_H + 18;

        // Why link
        var lwhy = buildWhyLink(x, ly);
        _loginWhyTxt = lwhy.txt;
        loginGroup.push(lwhy.icon); loginGroup.push(lwhy.txt);
        ly += 32;

        // Şifremi unuttum (küçük link stili)
        loginGroup.push(buildLinkBtn(x, ly, "ŞİFREMİ UNUTTUM →", onForgot));
        ly += 28;

        // Ana giriş butonu — tam genişlik, çarpıcı
        loginGroup.push(buildMainBtn(x, ly, "GİRİŞ YAP", onLogin));
        ly += 52;

        // Ayraç
        loginGroup.push(buildDivider(x, ly, "veya"));
        ly += 30;

        // Atla butonu — outlined
        loginGroup.push(buildOutlineBtn(x, ly, "ŞİMDİLİK ATLA  ⟶", onSkip));

        for (o in loginGroup) add(o);
    }

    // ── REGISTER FORMU ────────────────────────────────────────
    function buildRegisterForm(x:Float, startY:Float) {
        var ry:Float = startY;

        var ruf = buildField(x, ry, "KULLANICI ADI", "bf");
        regUserField = ruf.input;
        registerGroup.push(ruf.label); registerGroup.push(ruf.bg);
        registerGroup.push(ruf.icon);  registerGroup.push(ruf.input);
        ry += FIELD_H + 22;

        var ref_ = buildField(x, ry, "E-POSTA", "bf");
        regEmailField = ref_.input;
        registerGroup.push(ref_.label); registerGroup.push(ref_.bg);
        registerGroup.push(ref_.icon);  registerGroup.push(ref_.input);
        ry += FIELD_H + 22;

        var rpf = buildField(x, ry, "ŞİFRE", "password", true);
        regPassField = rpf.input;
        registerGroup.push(rpf.label); registerGroup.push(rpf.bg);
        registerGroup.push(rpf.icon);  registerGroup.push(rpf.input);
        ry += FIELD_H + 18;

        // Ülke seçici
        var cLabel = makeText(x, ry, FIELD_W, "ÜLKE", 9);
        cLabel.color = C_MUTED;
        registerGroup.push(cLabel);
        ry += 16;

        var leftBtn  = buildArrowBtn(x,                   ry, "◀", function() {
            countryIndex = (countryIndex - 1 + COUNTRIES.length) % COUNTRIES.length;
            countryValTxt.text = COUNTRIES[countryIndex];
        });
        var rightBtn = buildArrowBtn(x + FIELD_W - 36,    ry, "▶", function() {
            countryIndex = (countryIndex + 1) % COUNTRIES.length;
            countryValTxt.text = COUNTRIES[countryIndex];
        });

        var ctrBg = new FlxSprite(x + 40, ry).makeGraphic(FIELD_W - 80, FIELD_H, C_FIELD_BG);
        // Ktr bg alt çizgisi (field stili gibi)
        var ctrLine = new FlxSprite(x + 40, ry + FIELD_H - 2).makeGraphic(FIELD_W - 80, 2, C_ACCENT3);
        ctrLine.alpha = 0.4;

        countryValTxt = makeText(x + 40, ry + 14, FIELD_W - 80, COUNTRIES[0], 12);
        countryValTxt.alignment = CENTER;
        countryValTxt.color = C_WHITE;

        registerGroup.push(leftBtn);  registerGroup.push(ctrBg);
        registerGroup.push(ctrLine);  registerGroup.push(countryValTxt);
        registerGroup.push(rightBtn);
        ry += FIELD_H + 14;

        // Why link
        var rwhy = buildWhyLink(x, ry);
        _regWhyTxt = rwhy.txt;
        registerGroup.push(rwhy.icon); registerGroup.push(rwhy.txt);
        ry += 30;

        registerGroup.push(buildMainBtn(x, ry, "KAYIT OL", onRegister));
        ry += 52;
        registerGroup.push(buildOutlineBtn(x, ry, "ŞİMDİLİK ATLA  ⟶", onSkip));

        for (o in registerGroup) add(o);
    }

    // ── YARDIMCI BUILDER'LAR ──────────────────────────────────

    function buildField(x:Float, y:Float, label:String, iconName:String, password:Bool = false):
        {label:FlxText, bg:FlxSprite, icon:FlxSprite, input:PsychUIInputText}
    {
        var lbl = makeText(x, y, FIELD_W, label, 9);
        lbl.color = C_MUTED;

        // Zemin
        var bg = new FlxSprite(x, y + 14).makeGraphic(FIELD_W, FIELD_H, C_FIELD_BG);

        // Alt aksent çizgisi (border yerine)
        var bottomLine = new FlxSprite(x, y + 14 + FIELD_H - 2).makeGraphic(FIELD_W, 2, C_ACCENT1);
        bottomLine.alpha = 0.4;
        add(bottomLine);

        // Sol ince aksent çubuğu
        var leftAccent = new FlxSprite(x, y + 14).makeGraphic(2, FIELD_H, C_ACCENT1);
        leftAccent.alpha = 0.3;
        add(leftAccent);

        // İkon
        var icon = new FlxSprite(x + 10, y + 14 + (FIELD_H - 20) / 2);
        try {
            icon.loadGraphic(Paths.image('ultra/login/' + iconName));
            icon.setGraphicSize(20, 20);
            icon.updateHitbox();
            icon.alpha = 0.5;
        } catch(e) {
            icon.makeGraphic(20, 20, C_MUTED);
            icon.alpha = 0.3;
        }

        // Input
        var input = new PsychUIInputText(x + 38, y + 14 + 8, FIELD_W - 46, "", 13);
        input.maxLength  = password ? 50 : 20;
        input.passwordMask = password;

        return {label: lbl, bg: bg, icon: icon, input: input};
    }

    function buildWhyLink(x:Float, y:Float):{icon:FlxSprite, txt:FlxText} {
        // Mini soru ikonu — küçük kare badge
        var badge = new FlxSprite(x, y + 2).makeGraphic(16, 16, C_ACCENT3);
        badge.alpha = 0.2;
        add(badge);
        var badgeTxt = makeText(x + 3, y + 3, 12, "?", 9);
        badgeTxt.color = C_ACCENT3;
        add(badgeTxt);

        var txt = makeText(x + 22, y + 3, FIELD_W - 22, "Bu verileri neden istiyoruz?", 10);
        txt.color = C_ACCENT3;
        txt.alpha = 0.75;

        return {icon: badge, txt: txt};
    }

    /**
     * Tam genişlik ana buton — dolgu renkli, sol çarpık kesim efekti
     */
    function buildMainBtn(x:Float, y:Float, label:String, cb:Void->Void):FlxSprite {
        // Gölge / glow
        var shadow = new FlxSprite(x + 3, y + 3).makeGraphic(FIELD_W, 42, C_ACCENT1);
        shadow.alpha = 0.08;
        add(shadow);

        var bg = new FlxSprite(x, y).makeGraphic(FIELD_W, 42, C_ACCENT1);

        // İçeri metin — koyu renk (açık arka üstünde)
        var txt = makeText(x, y + 13, FIELD_W, label, 12);
        txt.alignment = CENTER;
        txt.color = C_BG;

        _btnMap.set(bg, cb);
        _btnLabels.push(txt);
        add(txt);
        return bg;
    }

    /**
     * Outlined (çerçeveli) sekonder buton
     */
    function buildOutlineBtn(x:Float, y:Float, label:String, cb:Void->Void):FlxSprite {
        var bg = new FlxSprite(x, y).makeGraphic(FIELD_W, 38, C_FIELD_BG);

        // Üst + alt çizgiler
        var topLine = new FlxSprite(x, y).makeGraphic(FIELD_W, 1, C_CARD_EDGE);
        var botLine = new FlxSprite(x, y + 37).makeGraphic(FIELD_W, 1, C_CARD_EDGE);
        // Sağda küçük accent köşe
        var rightAccent = new FlxSprite(x + FIELD_W - 2, y).makeGraphic(2, 38, C_ACCENT2);
        rightAccent.alpha = 0.5;
        add(topLine); add(botLine); add(rightAccent);

        var txt = makeText(x, y + 11, FIELD_W, label, 10);
        txt.alignment = CENTER;
        txt.color = C_MUTED;

        _btnMap.set(bg, cb);
        _btnLabels.push(txt);
        add(txt);
        return bg;
    }

    /**
     * Sadece metin link butonu (şifremi unuttum tarzı)
     */
    function buildLinkBtn(x:Float, y:Float, label:String, cb:Void->Void):FlxSprite {
        // Tıklanabilir yüzey — invisible
        var bg = new FlxSprite(x, y).makeGraphic(FIELD_W, 20, FlxColor.TRANSPARENT);
        var txt = makeText(x, y + 1, FIELD_W, label, 9);
        txt.alignment = RIGHT;
        txt.color = C_MUTED;
        _btnMap.set(bg, cb);
        _btnLabels.push(txt);
        add(txt);
        return bg;
    }

    function buildArrowBtn(x:Float, y:Float, arrow:String, cb:Void->Void):FlxSprite {
        var bg = new FlxSprite(x, y).makeGraphic(36, FIELD_H, C_FIELD_BG);
        // üst çizgi
        var topLine = new FlxSprite(x, y).makeGraphic(36, 1, C_ACCENT1);
        topLine.alpha = 0.3;
        add(topLine);

        var txt = makeText(x, y + 14, 36, arrow, 13);
        txt.alignment = CENTER;
        txt.color = C_ACCENT3;
        _btnMap.set(bg, cb);
        _btnLabels.push(txt);
        add(txt);
        return bg;
    }

    /**
     * "veya" gibi ayraç çizgisi
     */
    function buildDivider(x:Float, y:Float, label:String):FlxSprite {
        // Tıklanamaz, görsel öğe — FlxSprite döndürüyoruz (dummy invisible)
        var dummy = new FlxSprite(x, y).makeGraphic(FIELD_W, 20, FlxColor.TRANSPARENT);
        var lineL = new FlxSprite(x, y + 9).makeGraphic(Std.int(FIELD_W / 2) - 30, 1, C_CARD_EDGE);
        var lineR = new FlxSprite(x + Std.int(FIELD_W / 2) + 30, y + 9).makeGraphic(Std.int(FIELD_W / 2) - 30, 1, C_CARD_EDGE);
        var txt   = makeText(x + Std.int(FIELD_W / 2) - 28, y, 56, label, 9);
        txt.alignment = CENTER;
        txt.color = C_DIMMED;
        add(lineL); add(lineR); add(txt);
        return dummy;
    }

    // ── TAB SWITCH ────────────────────────────────────────────
    function switchTab(login:Bool) {
        isLogin = login;

        var halfW:Int = Std.int(FIELD_W / 2);
        var indX:Float = FIELD_X + (login ? 0 : halfW);

        // Gösterge çizgisini kaydır
        if (_cardReady) {
            FlxTween.tween(tabIndicator, {x: indX}, 0.18, {ease: FlxEase.quartOut});
        } else {
            tabIndicator.x = indX;
        }

        tabLoginTxt.color = login ? C_WHITE  : C_MUTED;
        tabRegTxt.color   = login ? C_MUTED  : C_WHITE;

        for (o in loginGroup)    o.visible = login;
        for (o in registerGroup) o.visible = !login;

        if (login) {
            PsychUIInputText.focusOn = null;
            regUserField.active  = false;
            regEmailField.active = false;
            regPassField.active  = false;
            loginUserField.active = true;
            loginPassField.active = true;
        } else {
            PsychUIInputText.focusOn = null;
            loginUserField.active = false;
            loginPassField.active = false;
            regUserField.active  = true;
            regEmailField.active = true;
            regPassField.active  = true;
        }

        statusTxt.visible = false;
        statusBg.visible  = false;
        statusTxt.text    = "";
    }

    // ── GİRİŞ ANİMASYONU ─────────────────────────────────────
    function playEntryAnim() {
        if (_cardSprite == null) { _cardReady = true; return; }

        // Kart yukarıdan süzülür
        var origY = _cardSprite.y;
        _cardSprite.y = origY - 30;
        _cardSprite.alpha = 0;
        FlxTween.tween(_cardSprite, {y: origY, alpha: 1}, 0.45, {ease: FlxEase.quartOut});

        new FlxTimer().start(0.45, function(_) {
            _cardReady = true;
        });
    }

    // ── UPDATE ────────────────────────────────────────────────
    override function update(elapsed:Float) {
        super.update(elapsed);

        // Kayan dikey ticker animasyonu (sol panelde)
        if (_vertTicker != null) {
            _vertTicker.y += elapsed * 40;
            if (_vertTicker.y > SH) _vertTicker.y = -2;
        }

        // Glow pulse (kart çevresindeki glow)
        _glowPulse += elapsed * 1.5;
        if (_accentBar != null)
            _accentBar.alpha = 0.03 + Math.sin(_glowPulse) * 0.015;

        if (!FlxG.mouse.justPressed) return;
        var mx = FlxG.mouse.x;
        var my = FlxG.mouse.y;

        // ── Tab tıklama ──
        var tabY1 = CARD_Y + 22 + 18;           // tab bar başlangıç Y (headerTxt + boşluk)
        var tabY2 = tabY1 + 36;
        if (my >= tabY1 && my <= tabY2) {
            if (mx >= FIELD_X && mx < FIELD_X + FIELD_W / 2)
                switchTab(true);
            else if (mx >= FIELD_X + FIELD_W / 2 && mx <= FIELD_X + FIELD_W)
                switchTab(false);
            return;
        }

        // ── Buton tıklama ──
        for (spr => cb in _btnMap) {
            if (!spr.visible) continue;
            if (mx >= spr.x && mx <= spr.x + spr.width &&
                my >= spr.y && my <= spr.y + spr.height) {
                cb();
                return;
            }
        }

        // ── Why link tıklama ──
        if (isLogin) {
            if (_loginWhyTxt != null &&
                mx >= _loginWhyTxt.x && mx <= _loginWhyTxt.x + _loginWhyTxt.width &&
                my >= _loginWhyTxt.y && my <= _loginWhyTxt.y + _loginWhyTxt.height + 5)
                openLink(WHY_URL);
        } else {
            if (_regWhyTxt != null &&
                mx >= _regWhyTxt.x && mx <= _regWhyTxt.x + _regWhyTxt.width &&
                my >= _regWhyTxt.y && my <= _regWhyTxt.y + _regWhyTxt.height + 5)
                openLink(WHY_URL);
        }
    }

    // ── CALLBACK'LER ──────────────────────────────────────────
    function onLogin() {
        var user = loginUserField.text.trim();
        var pass = loginPassField.text;
        if (user == "") { err("Kullanıcı adı boş olamaz."); return; }
        if (pass == "") { err("Şifre boş olamaz.");         return; }

        info("Giriş yapılıyor...");

        AuthManager.loginWithUsername(user, pass, function(ok, msg) {
            if (ok) {
                AlertMsg.show(
                    Language.getPhrase('auth_welcome_title', 'Hoşgeldin, ' + AuthManager.currentUsername + '!'),
                    Language.getPhrase('auth_welcome_msg',   'Hesabına başarıyla giriş yapıldı.'),
                    3, AlertMsg.COLOR_SUCCESS
                );
                FlxG.switchState(new MainMenuState());
            } else err(msg);
        });
    }

    function onRegister() {
        var user    = regUserField.text.trim();
        var email   = regEmailField.text.trim();
        var pass    = regPassField.text;
        var country = COUNTRIES[countryIndex];

        if (user.length < 4)                     { err("Kullanıcı adı en az 4 karakter olmalı."); return; }
        if (BadWordFilter.contains(user))         { err("Uygunsuz kelime içeriyor.");              return; }
        if (email == "" || !email.contains("@")) { err("Geçerli bir e-posta girin.");              return; }
        if (pass.length < 6)                     { err("Şifre en az 6 karakter olmalı.");          return; }

        info("Kayıt olunuyor...");

        AuthManager.register(email, pass, user, country, function(ok:Bool, msg:String) {
            if (ok) {
                AlertMsg.show(
                    Language.getPhrase('auth_reg_title', 'Kayıt Başarılı!'),
                    Language.getPhrase('auth_reg_msg',   'Hoşgeldin, ' + user + '!'),
                    3, AlertMsg.COLOR_SUCCESS
                );
                FlxG.switchState(new MainMenuState());
            } else {
                err(msg);
            }
        });
    }

    function onForgot() {
        var user = loginUserField.text.trim();
        if (!user.contains("@")) {
            err("E-posta adresinizi kullanıcı adı alanına girin.");
            return;
        }
        AuthManager.forgotPassword(user, function(ok, msg) {
            statusTxt.text  = "Şifre sıfırlama e-postası gönderildi!";
            statusTxt.color = C_ACCENT3;
            statusTxt.visible = true;
            statusBg.visible  = true;
            statusBg.color    = 0xFF001a12;
        });
    }

    function onSkip() {
        FlxG.switchState(new MainMenuState());
    }

    // ── YARDIMCILAR ───────────────────────────────────────────
    function makeText(x:Float, y:Float, w:Float, text:String, size:Int):FlxText {
        var t = new FlxText(x, y, w, text, size);
        t.font  = Paths.font("vcr.ttf");
        t.color = C_WHITE;
        // NOT: add() çağrısı buildField gibi özel yerlerde manuel yapılıyor;
        //      makeText genel amaçlı olduğu için burada add() yok.
        return t;
    }

    function err(msg:String) {
        statusTxt.text    = "⚠  " + msg;
        statusTxt.color   = C_ACCENT2;
        statusTxt.visible = true;
        statusBg.visible  = true;
        statusBg.color    = 0xFF1a0000;
    }

    function info(msg:String) {
        statusTxt.text    = msg;
        statusTxt.color   = C_MUTED;
        statusTxt.visible = true;
        statusBg.visible  = true;
        statusBg.color    = 0xFF080818;
    }

    function openLink(url:String) {
        #if windows Sys.command('start "" "' + url + '"');
        #elseif mac  Sys.command('open "' + url + '"');
        #elseif linux Sys.command('xdg-open "' + url + '"');
        #else lime.app.Application.current.window.alert(url, "Link"); #end
    }
}
