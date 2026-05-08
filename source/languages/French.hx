package languages;

class French implements ILanguage
{
    public var langName:String = "Français";
    public var alphabetPath:String = "alphabet";
    
    public var phrases:Map<String, String> = [
        // Options
        "opt_note_colors"        => "Couleurs des Notes",
        "opt_controls"           => "Contrôles",
        "opt_delay_combo"        => "Délai et Combo",
        "opt_graphics"           => "Graphismes et Performance",
        "opt_interface"          => "Interface et Visuels",
        "opt_gameplay"           => "Gameplay",
        "opt_language"           => "Langue",
        "opt_peu"                => "Paramètres P.E.U",
        "opt_menu_settings"      => "Paramètres du Menu",
        "opt_mobile"             => "Paramètres Mobile",
        
        // Language System
        "language_locked_title"  => "Langue Verrouillée!",
        "language_locked_msg"    => "Cette langue n'est pas disponible actuellement.",
        "language_changed_title" => "Langue Changée!",
        "language_changed_msg"   => "Votre langue a été changée avec succès."
    ];
    
    public var imageOverrides:Map<String, String> = [];
    
    public function new() {}
}