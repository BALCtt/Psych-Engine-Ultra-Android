package languages;

class Azerbaycan implements ILanguage
{
    public var langName:String = "Azərbaycan";
    public var alphabetPath:String = "alphabet";
    
    public var phrases:Map<String, String> = [
        // Options
        "opt_note_colors"        => "Not Rəngləri",
        "opt_controls"           => "İdarəetmə",
        "opt_delay_combo"        => "Gecikmə və Kombo",
        "opt_graphics"           => "Qrafika və Performans",
        "opt_interface"          => "İnterfeys və Vizuallar",
        "opt_gameplay"           => "Oyun",
        "opt_language"           => "Dil",
        "opt_peu"                => "P.E.U Parametrləri",
        "opt_menu_settings"      => "Menyu Parametrləri",
        "opt_mobile"             => "Mobil Parametrlər",
        
        // Language System
        "language_locked_title"  => "Dil Kilidlənib!",
        "language_locked_msg"    => "Bu dil hazırda mövcud deyil.",
        "language_changed_title" => "Dil Dəyişdirildi!",
        "language_changed_msg"   => "Diliniz uğurla dəyişdirildi."
    ];
    
    public var imageOverrides:Map<String, String> = [];
    
    public function new() {}
}