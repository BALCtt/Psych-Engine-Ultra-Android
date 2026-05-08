package objects;

import backend.AuthManager;
import backend.SupabaseClient;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class ProfileBox extends FlxSpriteGroup {

    // ── Renkler ──
    static final COL_BG_LOGGEDIN    = 0xCC0D0D1A;
    static final COL_BG_LOGGEDOUT   = 0xCC1A0A0A;
    static final COL_BORDER_IN      = 0xFF2A2A4A;
    static final COL_BORDER_OUT     = 0xFF3A1A1A;
    static final COL_PURPLE         = 0xFFC084FC;
    static final COL_RED            = 0xFFF87171;
    static final COL_MUTED          = 0xFF8888AA;
    static final COL_GREEN          = 0xFF34D399;
    static final COL_GOLD           = 0xFFFBBF24;

    static final BOX_W = 260;
    static final BOX_H = 70;

    var bg:FlxSprite;
    var statusText:FlxText;
    var nameText:FlxText;
    var avatarSprite:FlxSprite;
    var onlineDot:FlxSprite;

    var _isLoggedIn:Bool = false;

    public function new() {
        super();
        build();
    }

    function build() {
        // Temizle
        forEach(function(s) remove(s));

        _isLoggedIn = AuthManager.isLoggedIn;

        // ── Arka plan ──
        bg = new FlxSprite();
        bg.makeGraphic(BOX_W, BOX_H,
            _isLoggedIn ? COL_BG_LOGGEDIN : COL_BG_LOGGEDOUT);
        bg.alpha = 0.88;
        add(bg);

        // ── Sol renkli şerit ──
        var accent = new FlxSprite(0, 0);
        accent.makeGraphic(3, BOX_H,
            _isLoggedIn ? COL_PURPLE : COL_RED);
        accent.alpha = 0.7;
        add(accent);

        if (_isLoggedIn) {
            buildLoggedIn();
        } else {
            buildLoggedOut();
        }

        // Giriş animasyonu
        alpha = 0;
        x += 20;
        FlxTween.tween(this, {alpha: 1, x: x - 20}, 0.4,
            {ease: FlxEase.quartOut, startDelay: 0.2});
    }

    function buildLoggedIn() {
        // ── Yeşil online dot ──
        onlineDot = new FlxSprite(BOX_W - 14, 8);
        onlineDot.makeGraphic(8, 8, COL_GREEN);
        add(onlineDot);

        // ── Durum ──
        statusText = new FlxText(14, 8, BOX_W - 30, "GİRİŞ YAPILDI!");
        statusText.setFormat("VCR OSD Mono", 11, COL_GREEN, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(statusText);

        // ── Kullanıcı adı ──
        var username = AuthManager.currentUsername ?? "Oyuncu";
        nameText = new FlxText(14, 26, BOX_W - 30, username);
        nameText.setFormat("VCR OSD Mono", 17, COL_PURPLE, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(nameText);

        // ── Ultra Points ve Level ──
        var up    = AuthManager.currentUltraPoints ?? 0.0;
        var level = AuthManager.currentLevel ?? 1;
        var infoText = new FlxText(14, 46, BOX_W - 30,
            "Lv." + level + "  •  " + FlxMath.roundDecimal(up, 1) + " UP");
        infoText.setFormat("VCR OSD Mono", 11, COL_MUTED, LEFT);
        add(infoText);
    }

    function buildLoggedOut() {
        // ── Kırmızı X dot ──
        var dot = new FlxSprite(BOX_W - 14, 8);
        dot.makeGraphic(8, 8, COL_RED);
        add(dot);

        // ── Durum ──
        statusText = new FlxText(14, 8, BOX_W - 30, "GİRİŞ YAPILMADI!");
        statusText.setFormat("VCR OSD Mono", 11, COL_RED, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(statusText);

        // ── Yönlendirme ──
        nameText = new FlxText(14, 26, BOX_W - 30, "Giriş yapmak için");
        nameText.setFormat("VCR OSD Mono", 13, FlxColor.WHITE, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(nameText);

        var hint = new FlxText(14, 44, BOX_W - 30, "Online'a gidin →");
        hint.setFormat("VCR OSD Mono", 12, COL_MUTED, LEFT,
            FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(hint);
    }

    /**
     * AuthManager'dan güncel veriyi yeniden çek ve kutuyu yeniden çiz.
     * Giriş/çıkış sonrası çağır.
     */
    public function refresh() {
        build();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        // ── Hover efekti ──
        final hovered = FlxG.mouse.overlaps(this);
        bg.alpha = hovered ? 1.0 : 0.88;

        // ── Tıklama ──
        if (hovered && FlxG.mouse.justPressed) {
            if (_isLoggedIn) {
                // Giriş yapılmış: profil bilgisini göster (ileride genişletilebilir)
                // Şimdilik sadece leaderboard'a git
                FlxG.switchState(() -> new states.MultiplayerState());
            } else {
                // Giriş yapılmamış: Auth ekranını aç
                #if AUTHSTATE_EXISTS
                FlxG.switchState(() -> new states.AuthState());
                #else
				AlertMsg.show(
					Language.getPhrase('language_changed_title', 'Daha gelmedi!'),
					Language.getPhrase('language_changed_msg', 'yok.'),
					4,
					AlertMsg.COLOR_ERROR
				);
                #end
            }
        }
    }
}
