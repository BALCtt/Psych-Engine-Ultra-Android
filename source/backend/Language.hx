package backend;

import languages.ILanguage;
import languages.English;
import languages.Turkish;
import languages.Spanish;
import languages.French;
import languages.Mexico;
import languages.Azerbaycan;

class Language
{
    public static var defaultLangName:String = 'English (US)';
    public static var defaultLangKey:String  = 'english';

    public static var registeredLanguages:Map<String, ILanguage> = [];
    private static var _languagesRegistered:Bool = false;

    #if TRANSLATIONS_ALLOWED
    public static var currentLang:ILanguage = null;
    private static var phrases:Map<String, String> = [];
    private static var imageOverrides:Map<String, String> = [];
    #end

    public static function registerLanguages():Void
    {
        if (_languagesRegistered) return;
        _languagesRegistered = true;

        // Ana Diller
        registeredLanguages.set('english',    new English());
        registeredLanguages.set('turkish',    new Turkish());
        registeredLanguages.set('spanish',    new Spanish());
        
        // Ek Diller (Kilitli olanlar dahil)
        registeredLanguages.set('french',     new French());
        registeredLanguages.set('mexico',     new Mexico());
        registeredLanguages.set('azerbaycan', new Azerbaycan());
    }
    
    public static function getAlphabetPath():String
    {
        #if TRANSLATIONS_ALLOWED
        if (currentLang != null && currentLang.alphabetPath != null)
            return currentLang.alphabetPath;
        #end
        return 'alphabet';
    }

    public static function reloadPhrases():Void
    {
        if (!_languagesRegistered)
            registerLanguages();

        #if TRANSLATIONS_ALLOWED
        var langKey:String = (ClientPrefs.data.language != null && ClientPrefs.data.language.length > 0)
            ? ClientPrefs.data.language.toLowerCase().trim()
            : defaultLangKey;
            
        final aliases:Map<String, String> = [
            'en-us'    => 'english',
            'en'       => 'english',
            'tr'       => 'turkish',
            'tr-tr'    => 'turkish',
            'es'       => 'spanish',
            'es-es'    => 'spanish',
            'fr'       => 'french',
            'fr-fr'    => 'french',
            'es-mx'    => 'mexico',
            'mx'       => 'mexico',
            'az'       => 'azerbaycan',
            'az-az'    => 'azerbaycan',
        ];
        
        if (aliases.exists(langKey))
            langKey = aliases.get(langKey);

        currentLang = registeredLanguages.get(langKey);

        if (currentLang == null)
        {
            trace('[Language] "$langKey" not found, Turning Back To English.');
            ClientPrefs.data.language = defaultLangKey;
            currentLang = registeredLanguages.get(defaultLangKey);
        }

        phrases        = (currentLang != null) ? currentLang.phrases        : [];
        imageOverrides = (currentLang != null) ? currentLang.imageOverrides : [];

        var alphaPath:String = (currentLang != null && currentLang.alphabetPath != null)
            ? currentLang.alphabetPath
            : 'alphabet';
        AlphaCharacter.loadAlphabetData(alphaPath);

        trace('[Language] Loaded: ' + langKey + ' (' + Lambda.count(phrases) + ' phrases)');
        #else
        AlphaCharacter.loadAlphabetData();
        #end
    }

    inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
    {
        #if TRANSLATIONS_ALLOWED
        var str:String = (phrases != null) ? phrases.get(formatKey(key)) : null;
        if (str == null) str = defaultPhrase;
        #else
        var str:String = defaultPhrase;
        #end

        if (str == null) str = key;

        if (values != null)
            for (num => value in values)
                str = str.replace('{${num + 1}}', Std.string(value));

        return str;
    }

    public static function getFileTranslation(key:String):String
    {
        #if TRANSLATIONS_ALLOWED
        if (imageOverrides == null) return key;

        var trimmed:String = key.trim().toLowerCase();

        var translated:String = imageOverrides.get(trimmed);
        if (translated != null) return translated;

        if (trimmed.startsWith('images/'))
        {
            translated = imageOverrides.get(trimmed.substr('images/'.length));
            if (translated != null) return 'images/' + translated;
        }
        #end
        return key;
    }

    public static function getLangDisplayName(key:String):String
    {
        if (!_languagesRegistered)
            registerLanguages();

        var lang:ILanguage = registeredLanguages.get(key.toLowerCase());
        if (lang != null) return lang.langName;
        return key;
    }

    public static function getCurrentLangKey():String
    {
        return (ClientPrefs.data.language != null)
            ? ClientPrefs.data.language.toLowerCase().trim()
            : defaultLangKey;
    }

    #if TRANSLATIONS_ALLOWED
    inline static private function formatKey(key:String):String
    {
        final hideChars = ~/[~&\\\/;:<>#.,'"%?!]/g;
        return hideChars.replace(key.replace(' ', '_'), '').toLowerCase().trim();
    }
    #end

    #if LUA_ALLOWED
    public static function addLuaCallbacks(lua:State)
    {
        Lua_helper.add_callback(lua, "getTranslationPhrase", function(key:String, ?defaultPhrase:String, ?values:Array<Dynamic> = null) {
            return getPhrase(key, defaultPhrase, values);
        });
        Lua_helper.add_callback(lua, "getFileTranslation", function(key:String) {
            return getFileTranslation(key);
        });
    }
    #end
}