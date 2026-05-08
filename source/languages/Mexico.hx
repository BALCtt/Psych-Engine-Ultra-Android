package languages;

class Mexico implements ILanguage
{
    public var langName:String = "Español (México)";
    public var alphabetPath:String = "alphabet";
    
    public var phrases:Map<String, String> = [
        // Options
        "opt_note_colors"        => "Colores de Notas",
        "opt_controls"           => "Controles",
        "opt_delay_combo"        => "Retraso y Combo",
        "opt_graphics"           => "Gráficos y Rendimiento",
        "opt_interface"          => "Interfaz y Visuales",
        "opt_gameplay"           => "Jugabilidad",
        "opt_language"           => "Idioma",
        "opt_peu"                => "Ajustes P.E.U",
        "opt_menu_settings"      => "Ajustes del Menú",
        "opt_mobile"             => "Ajustes Móviles",
        
        // Language System
        "language_locked_title"  => "¡Idioma Bloqueado!",
        "language_locked_msg"    => "Este idioma no está disponible actualmente.",
        "language_changed_title" => "¡Idioma Cambiado!",
        "language_changed_msg"   => "Tu idioma ha sido cambiado exitosamente."
    ];
    
    public var imageOverrides:Map<String, String> = [];
    
    public function new() {}
}