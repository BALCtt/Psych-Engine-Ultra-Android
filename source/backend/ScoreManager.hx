package backend;

class ScoreManager {

    public static var onScoreSubmitted:(ultraPoints:Float, upDelta:Float, newLevel:Int, newBestAcc:Float) -> Void = null;
    public static var onScoreRejected:(reason:String) -> Void = null;
    public static var onNotImproved:(existingScore:Int) -> Void = null;

    public static function submitScore(
        songName:  String,
        difficulty:String,
        score:     Int,
        accuracy:  Float,
        rank:      String,
        misses:    Int,
        maxCombo:  Int
    ):Void {
        if (!AuthManager.isLoggedIn) return;

        var normalizedAcc = accuracy > 1.0 ? accuracy : accuracy * 100.0;

        if (!clientSideValidate(score, normalizedAcc, misses, maxCombo, rank)) return;

        var token    = SupabaseClient.getToken();
        var playerId = SupabaseClient.getUserId();

        if (token == null || token == "" || playerId == null || playerId == "") return;

        var body = {
            p_player_id:  playerId,
            p_username:   AuthManager.currentUsername,
            p_song_name:  songName,
            p_difficulty: difficulty,
            p_score:      score,
            p_accuracy:   normalizedAcc,
            p_rank:       rank,
            p_misses:     misses,
            p_max_combo:  maxCombo
        };

        SupabaseClient.postAsync(
            '/rest/v1/rpc/submit_score_secure',
            body,
            token,
            function(status:Int, data:String) {
                handleRPCResponse(status, data, score);
            }
        );
    }

    static function handleRPCResponse(status:Int, data:String, score:Int):Void {
        if (status == 0 || data == null || data == "") {
            trace("[ScoreManager] connection error status=" + status);
            if (onScoreRejected != null) onScoreRejected("connection_error");
            return;
        }

        try {
            var result:Dynamic = haxe.Json.parse(data);
            var resultStatus:String = Std.string(result.status != null ? result.status : (result.error != null ? result.error : "unknown"));

            switch (resultStatus) {
                case "success":
                    var up:Float      = result.ultra_points != null ? result.ultra_points : 0.0;
                    var delta:Float   = result.up_delta != null ? result.up_delta : 0.0;
                    var level:Int     = result.new_level != null ? Std.int(result.new_level) : 1;
                    var bestAcc:Float = result.new_best_acc != null ? result.new_best_acc : 0.0;

                    AuthManager.currentLevel       = level;
                    AuthManager.currentUltraPoints = result.new_total_up != null ? result.new_total_up : 0.0;

                    trace("[ScoreManager] success UP=" + up + " delta=" + delta + " level=" + level + " bestAcc=" + bestAcc);

                    if (onScoreSubmitted != null) onScoreSubmitted(up, delta, level, bestAcc);

                case "not_improved":
                    var existing:Int = result.existing_score != null ? Std.int(result.existing_score) : 0;
                    if (onNotImproved != null) onNotImproved(existing);

                case "rate_limited":
                    if (onScoreRejected != null) onScoreRejected("rate_limited");

                case "unauthorized":
                    trace("[ScoreManager] unauthorized");
                    if (onScoreRejected != null) onScoreRejected("unauthorized");

                case "suspicious_data":
                    trace("[ScoreManager] suspicious: " + (result.detail != null ? result.detail : ""));
                    if (onScoreRejected != null) onScoreRejected("suspicious_data");

                case "server_error":
                    trace("[ScoreManager] server_error: " + (result.detail != null ? result.detail : ""));
                    if (onScoreRejected != null) onScoreRejected("server_error");

                default:
                    trace("[ScoreManager] unknown: " + data);
                    if (onScoreRejected != null) onScoreRejected("unknown");
            }

        } catch(e:Dynamic) {
            trace("[ScoreManager] parse error: " + e + " raw: " + data);
        }
    }

    static function clientSideValidate(score:Int, accuracy:Float, misses:Int, maxCombo:Int, rank:String):Bool {
        if (score < 0 || score > 1000000) return false;
        if (accuracy < 0 || accuracy > 100) return false;
        if (misses < 0) return false;
        if (maxCombo < 0) return false;
        var validRanks = ["SSS", "SS", "S", "A", "B", "C", "D", "F", "?"];
        if (!validRanks.contains(rank)) return false;
        return true;
    }

    public static function estimateUltraPoints(score:Int, accuracy:Float, misses:Int, maxCombo:Int):Float {
        var acc         = accuracy > 1.0 ? accuracy : accuracy * 100.0;
        var baseUP      = score / 10000.0;
        var accMult     = Math.pow(Math.max(acc, 0) / 100.0, 2);
        var missPenalty = misses * 0.15;
        var comboBonus  = (maxCombo / 500.0) * 0.5;
        return Math.max(0, Math.min((baseUP * accMult) - missPenalty + comboBonus, 30.0));
    }

    public static function getLevelFromUP(totalUP:Float):Int {
        var thresholds = [
            0.0, 10.0, 20.0, 30.0, 40.0,
            58.0, 76.0, 94.0, 112.0, 130.0,
            160.0, 190.0, 220.0, 250.0, 280.0, 310.0, 340.0, 370.0, 400.0, 430.0,
            485.0, 540.0, 595.0, 650.0, 705.0, 760.0, 815.0, 870.0, 925.0, 980.0,
            1035.0, 1090.0, 1145.0, 1200.0, 1255.0,
            1345.0, 1435.0, 1525.0, 1615.0, 1705.0,
            1795.0, 1885.0, 1975.0, 2065.0, 2155.0,
            2245.0, 2335.0, 2425.0, 2515.0, 2605.0
        ];
        var level = 1;
        for (i in 0...thresholds.length) {
            if (totalUP >= thresholds[i]) level = i + 1;
            else break;
        }
        return level;
    }

    public static function getUPForNextLevel(currentLevel:Int):Float {
        var thresholds = [
            0.0, 10.0, 20.0, 30.0, 40.0,
            58.0, 76.0, 94.0, 112.0, 130.0,
            160.0, 190.0, 220.0, 250.0, 280.0, 310.0, 340.0, 370.0, 400.0, 430.0,
            485.0, 540.0, 595.0, 650.0, 705.0, 760.0, 815.0, 870.0, 925.0, 980.0,
            1035.0, 1090.0, 1145.0, 1200.0, 1255.0,
            1345.0, 1435.0, 1525.0, 1615.0, 1705.0,
            1795.0, 1885.0, 1975.0, 2065.0, 2155.0,
            2245.0, 2335.0, 2425.0, 2515.0, 2605.0
        ];
        if (currentLevel >= thresholds.length) return -1.0;
        return thresholds[currentLevel];
    }

    public static function formatUP(up:Float):String {
        return "+" + (Math.round(up * 10) / 10) + " UP";
    }
}
