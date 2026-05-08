package backend;

class LeaderboardAPI {
    static final BASE_URL = "https://ubhglndbbzidunjgnpqi.supabase.co";
    static final API_KEY  = "sb_publishable_xShtsNZot0C3cIDqj3s2Ew_V3zJs_1k";

    // Skoru gönder ve seviyeyi güncelle
    public static function submitScore(username:String, songName:String, score:Int, accuracy:Float, rank:String) {
        // 1) Skoru kaydet
        var scoreHttp = new haxe.Http('$BASE_URL/scores');
        scoreHttp.setHeader("apikey", API_KEY);
        scoreHttp.setHeader("Content-Type", "application/json");
        scoreHttp.setHeader("Prefer", "return=minimal");

        var body = haxe.Json.stringify({
            username: username,
            song_name: songName,
            score: score,
            accuracy: accuracy,
            rank: rank
        });
        scoreHttp.setPostData(body);
        scoreHttp.onStatus = function(status) {
            if (status == 201) updatePlayerScore(username, score);
        };
        scoreHttp.request(true);
    }

    // Oyuncunun toplam skorunu ve seviyesini güncelle
    static function updatePlayerScore(username:String, newScore:Int) {
        var http = new haxe.Http('$BASE_URL/rpc/upsert_player_score');
        http.setHeader("apikey", API_KEY);
        http.setHeader("Content-Type", "application/json");
        http.setPostData(haxe.Json.stringify({
            p_username: username,
            p_score: newScore
        }));
        http.request(true);
    }

    // Leaderboard çek
    public static function getLeaderboard(callback:Array<Dynamic>->Void) {
        var http = new haxe.Http('$BASE_URL/leaderboard?select=*');
        http.setHeader("apikey", API_KEY);
        http.onData = function(data) {
            var parsed = haxe.Json.parse(data);
            callback(parsed);
        };
        http.onError = function(e) callback([]);
        http.request(false);
    }
}