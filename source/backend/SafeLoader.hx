package backend;

import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flash.media.Sound;
import haxe.Exception;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class SafeLoader
{
    private static var CRASH_FLAG_FILE:String = "CRASH_FLAG";
    private static var CRASH_LOG_FILE:String = "crash_log.txt";
    private static var SAFE_MODE_FILE:String = "SAFE_MODE";
    
    public static var safeMode:Bool = false;
    public static var lastCrashReason:String = "";
    public static var failedAssets:Array<String> = [];
    public static var failedMods:Array<String> = [];
    
    private static var errorCount:Int = 0;
    private static var maxErrorsBeforeRecovery:Int = 5;
    
    public static function init():Bool
    {
        #if sys
        trace('[SafeLoader] Initializing crash recovery system...');
        
        var crashFlagPath = getCrashFlagPath();
        var safeModePath = getSafeModePath();
        
        if (FileSystem.exists(safeModePath))
        {
            trace('[SafeLoader] Safe mode file detected - entering safe mode');
            safeMode = true;
            disableAllMods();
            return true;
        }
        
        if (FileSystem.exists(crashFlagPath))
        {
            trace('[SafeLoader] Previous session crashed!');
            
            try {
                lastCrashReason = File.getContent(crashFlagPath);
                trace('[SafeLoader] Crash reason: ' + lastCrashReason);
            } catch(e:Dynamic) {}
            
            try { FileSystem.deleteFile(crashFlagPath); } catch(e:Dynamic) {}
            
            if (lastCrashReason.indexOf("mods/") != -1 || 
                lastCrashReason.indexOf("Mod") != -1 ||
                lastCrashReason.indexOf("lime") != -1 ||
                lastCrashReason.indexOf("Null") != -1)
            {
                trace('[SafeLoader] Mod-related crash detected - disabling mods');
                safeMode = true;
                disableAllMods();
                logCrash("Auto-recovery: Mods disabled due to crash");
                return true;
            }
        }
        
        createCrashFlag("Session started");
        validateAllMods();
        
        trace('[SafeLoader] Initialization complete. Failed mods: ' + failedMods.length);
        #end
        return true;
    }
    
    public static function createCrashFlag(reason:String):Void
    {
        #if sys
        try {
            var path = getCrashFlagPath();
            var dir = haxe.io.Path.directory(path);
            if (dir.length > 0 && !FileSystem.exists(dir))
                FileSystem.createDirectory(dir);
            File.saveContent(path, reason + "\n" + Date.now().toString());
        } catch(e:Dynamic) {
            trace('[SafeLoader] Could not create crash flag: ' + e);
        }
        #end
    }
    
    public static function clearCrashFlag():Void
    {
        #if sys
        try {
            var path = getCrashFlagPath();
            if (FileSystem.exists(path))
                FileSystem.deleteFile(path);
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function onCleanExit():Void
    {
        clearCrashFlag();
        trace('[SafeLoader] Clean exit - crash flag cleared');
    }
    
    public static function validateAllMods():Void
    {
        #if (sys && MODS_ALLOWED)
        trace('[SafeLoader] Validating all mods...');
        
        var modsListPath = getModsListPath();
        if (!FileSystem.exists(modsListPath)) return;
        
        try {
            var content = File.getContent(modsListPath);
            var lines = content.split('\n');
            var validLines:Array<String> = [];
            var invalidCount = 0;
            
            for (line in lines)
            {
                var trimmed = StringTools.trim(line);
                if (trimmed.length == 0) continue;
                
                var parts = trimmed.split('|');
                var modName = parts[0];
                var enabled = (parts.length > 1) ? (parts[1] == '1') : true;
                
                if (!enabled)
                {
                    validLines.push(trimmed);
                    continue;
                }
                
                if (validateMod(modName))
                {
                    validLines.push(trimmed);
                }
                else
                {
                    trace('[SafeLoader] Invalid mod disabled: ' + modName);
                    failedMods.push(modName);
                    validLines.push(modName + '|0');
                    invalidCount++;
                }
            }
            
            if (invalidCount > 0)
            {
                File.saveContent(modsListPath, validLines.join('\n'));
                trace('[SafeLoader] Disabled ' + invalidCount + ' invalid mods');
            }
            
        } catch(e:Dynamic) {
            trace('[SafeLoader] Error validating mods: ' + e);
        }
        #end
    }
    
    public static function validateMod(modName:String):Bool
    {
        #if (sys && MODS_ALLOWED)
        if (modName == null || modName.length == 0) return false;
        
        var modPath = Paths.mods(modName);
        
        if (!FileSystem.exists(modPath))
        {
            trace('[SafeLoader] Mod folder not found: ' + modName);
            return false;
        }
        
        if (!FileSystem.isDirectory(modPath))
        {
            trace('[SafeLoader] Not a directory: ' + modName);
            return false;
        }
        
        var packPath = modPath + '/pack.json';
        if (FileSystem.exists(packPath))
        {
            try {
                var content = File.getContent(packPath);
                if (content != null && content.length > 0)
                {
                    haxe.Json.parse(content);
                }
            } catch(e:Dynamic) {
                trace('[SafeLoader] Invalid pack.json in mod: ' + modName + ' - ' + e);
                return false;
            }
        }
        
        return true;
        #else
        return true;
        #end
    }
    
    public static function disableAllMods():Void
    {
        #if (sys && MODS_ALLOWED)
        trace('[SafeLoader] Disabling all mods...');
        
        var modsListPath = getModsListPath();
        
        try {
            if (!FileSystem.exists(modsListPath))
            {
                File.saveContent(modsListPath, '');
                return;
            }
            
            var content = File.getContent(modsListPath);
            var lines = content.split('\n');
            var newLines:Array<String> = [];
            
            for (line in lines)
            {
                var trimmed = StringTools.trim(line);
                if (trimmed.length == 0) continue;
                
                var parts = trimmed.split('|');
                var modName = parts[0];
                
                newLines.push(modName + '|0');
            }
            
            File.saveContent(modsListPath, newLines.join('\n'));
            trace('[SafeLoader] All mods disabled');
            
        } catch(e:Dynamic) {
            trace('[SafeLoader] Error disabling mods: ' + e);
            try { FileSystem.deleteFile(modsListPath); } catch(e2:Dynamic) {}
        }
        #end
    }
    
    public static function resetModsList():Void
    {
        #if sys
        try {
            var path = getModsListPath();
            File.saveContent(path, '');
            trace('[SafeLoader] ModsList reset');
        } catch(e:Dynamic) {
            trace('[SafeLoader] Could not reset modsList: ' + e);
        }
        #end
    }
    
    public static function loadBitmapData(path:String):BitmapData
    {
        try {
            #if sys
            if (FileSystem.exists(path))
            {
                var bmp = BitmapData.fromFile(path);
                if (bmp != null) return bmp;
            }
            #end
            
            if (OpenFlAssets.exists(path))
            {
                return OpenFlAssets.getBitmapData(path);
            }
        } catch(e:Dynamic) {
            logAssetError('BitmapData', path, Std.string(e));
        }
        
        return new BitmapData(1, 1, true, 0x00000000);
    }
    
    public static function loadSound(path:String):Sound
    {
        try {
            #if sys
            if (FileSystem.exists(path))
            {
                var snd = Sound.fromFile(path);
                if (snd != null) return snd;
            }
            #end
        } catch(e:Dynamic) {
            logAssetError('Sound', path, Std.string(e));
        }
        
        return new Sound();
    }
    
    public static function loadText(path:String):String
    {
        #if sys
        try {
            if (FileSystem.exists(path))
                return File.getContent(path);
        } catch(e:Dynamic) {
            logAssetError('Text', path, Std.string(e));
        }
        #end
        return null;
    }
    
    public static function parseJSON(content:String, ?sourcePath:String):Dynamic
    {
        if (content == null || content.length == 0) return null;
        
        try {
            return haxe.Json.parse(content);
        } catch(e:Dynamic) {
            logAssetError('JSON', sourcePath != null ? sourcePath : "unknown", Std.string(e));
        }
        
        return null;
    }
    
    public static function logAssetError(type:String, path:String, error:String):Void
    {
        errorCount++;
        var msg = '[' + type + '] ' + path + ' - ' + error;
        trace('[SafeLoader] Asset error: ' + msg);
        failedAssets.push(msg);
        
        if (path != null && path.indexOf('mods/') != -1)
        {
            var parts = path.split('/');
            for (i in 0...parts.length)
            {
                if (parts[i] == 'mods' && i + 1 < parts.length)
                {
                    var modName = parts[i + 1];
                    if (!failedMods.contains(modName))
                        failedMods.push(modName);
                    break;
                }
            }
        }
        
        if (errorCount >= maxErrorsBeforeRecovery)
        {
            createCrashFlag("Too many asset errors");
        }
    }
    
    public static function logCrash(reason:String):Void
    {
        #if sys
        try {
            var logPath = getCrashLogPath();
            var existing = "";
            
            if (FileSystem.exists(logPath))
            {
                try { existing = File.getContent(logPath); } catch(e:Dynamic) {}
            }
            
            var entry = "\n=== " + Date.now().toString() + " ===\n" + reason + "\n";
            
            if (failedMods.length > 0)
                entry += "Failed mods: " + failedMods.join(", ") + "\n";
            
            if (failedAssets.length > 0)
                entry += "Failed assets (first 10): " + failedAssets.slice(0, 10).join("\n  ") + "\n";
            
            File.saveContent(logPath, existing + entry);
            
        } catch(e:Dynamic) {
            trace('[SafeLoader] Could not write crash log: ' + e);
        }
        #end
    }
    
    public static function setupExceptionHandler():Void
    {
        #if cpp
        untyped __global__.__hxcpp_set_critical_error_handler(function(msg:String) {
            trace('[SafeLoader] Critical error: ' + msg);
            createCrashFlag("Critical: " + msg);
            logCrash("Critical error: " + msg);
        });
        #end
    }
    
    private static function getCrashFlagPath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + CRASH_FLAG_FILE;
        #elseif sys
        return Sys.getCwd() + CRASH_FLAG_FILE;
        #else
        return CRASH_FLAG_FILE;
        #end
    }
    
    private static function getSafeModePath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + SAFE_MODE_FILE;
        #elseif sys
        return Sys.getCwd() + SAFE_MODE_FILE;
        #else
        return SAFE_MODE_FILE;
        #end
    }
    
    private static function getCrashLogPath():String
    {
        #if android
        return StorageUtil.getExternalStorageDirectory() + CRASH_LOG_FILE;
        #elseif sys
        return Sys.getCwd() + CRASH_LOG_FILE;
        #else
        return CRASH_LOG_FILE;
        #end
    }
    
    private static function getModsListPath():String
    {
        #if MODS_ALLOWED
        var customPath = ClientPrefs.data.modsPath;
        if (customPath != null && customPath.length > 0)
            return haxe.io.Path.addTrailingSlash(customPath) + 'modsList.txt';
        
        #if android
        return StorageUtil.getExternalStorageDirectory() + 'modsList.txt';
        #elseif sys
        return Sys.getCwd() + 'modsList.txt';
        #else
        return 'modsList.txt';
        #end
        #else
        return 'modsList.txt';
        #end
    }
    
    public static function enableSafeModeOnNextBoot():Void
    {
        #if sys
        try {
            File.saveContent(getSafeModePath(), "Safe mode requested at " + Date.now().toString());
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function clearSafeMode():Void
    {
        #if sys
        try {
            var path = getSafeModePath();
            if (FileSystem.exists(path))
                FileSystem.deleteFile(path);
        } catch(e:Dynamic) {}
        #end
    }
    
    public static function disableFailedMods():Void
    {
        #if (sys && MODS_ALLOWED)
        if (failedMods.length == 0) return;
        
        trace('[SafeLoader] Disabling failed mods: ' + failedMods.join(", "));
        
        var modsListPath = getModsListPath();
        
        try {
            if (!FileSystem.exists(modsListPath)) return;
            
            var content = File.getContent(modsListPath);
            var lines = content.split('\n');
            var newLines:Array<String> = [];
            
            for (line in lines)
            {
                var trimmed = StringTools.trim(line);
                if (trimmed.length == 0) continue;
                
                var parts = trimmed.split('|');
                var modName = parts[0];
                
                if (failedMods.contains(modName))
                    newLines.push(modName + '|0');
                else
                    newLines.push(trimmed);
            }
            
            File.saveContent(modsListPath, newLines.join('\n'));
            
        } catch(e:Dynamic) {
            trace('[SafeLoader] Error disabling failed mods: ' + e);
        }
        #end
    }
    
    public static function getSafeModeTitle():String
    {
        return Language.getPhrase('safemode_title', 'Safe Mode Active');
    }
    
    public static function getSafeModeMessage():String
    {
        return Language.getPhrase('safemode_message', 'An error occurred in the previous session.\nMods have been temporarily disabled for safety.');
    }
    
    public static function getSafeModeModsInfo():String
    {
        return Language.getPhrase('safemode_mods_info', 'Problematic mods:');
    }
    
    public static function getSafeModeReenableHint():String
    {
        return Language.getPhrase('safemode_reenable_hint', 'You can re-enable mods from the settings.');
    }
}