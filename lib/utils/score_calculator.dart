class ScoreCalculator {
  /// Maximum bid a player may enter in Call Break.
  static const int maxBid = 8;

  /// Maximum tricks per round (full deck, 4 players × 13 cards).
  static const int maxTricks = 13;

  /// Bid threshold at which winning triggers the Special-Round rule.
  static const int specialBidThreshold = 8;

  /// Regular-game cumulative threshold (in tenths) for "Double Money" status.
  /// 200 tenths = 20.0 actual points.
  static const int doubleMoneyThresholdTenths = 200;

  // ─── Call Break ────────────────────────────────────────────────────────────

  /// Returns the Call Break score stored as integer tenths.
  ///   tricks >= bid  →  +bid×10 + (tricks − bid)          e.g. 3.1 → 31
  ///   tricks <  bid  →  −bid×10                            e.g. −4.0 → −40
  static int callBreakScore({required int bid, required int tricks}) {
    if (tricks >= bid) {
      return (bid * 10) + (tricks - bid);
    }
    return -(bid * 10);
  }

  /// A "Special Win" occurs when a player bids [specialBidThreshold] or above
  /// AND wins (tricks ≥ bid). The round is then split: that player's score
  /// goes to the Special Game; other players' scores stay in the Regular Game.
  static bool isSpecialWin({required int bid, required int tricks}) {
    return bid >= specialBidThreshold && tricks >= bid;
  }

  // ─── Marriage ──────────────────────────────────────────────────────────────

  static int marriageScore({required int points}) {
    return points;
  }

  // ─── Display ───────────────────────────────────────────────────────────────

  /// Formats a score stored as integer tenths into a human-readable string.
  ///   isTenths=true : 31 → "3.1",  −40 → "−4.0"
  ///   isTenths=false: 42 → "42"
  static String formatScore(int value, {required bool isTenths}) {
    if (!isTenths) return value.toString();
    final sign = value < 0 ? '-' : '';
    final abs = value.abs();
    return '$sign${abs ~/ 10}.${abs % 10}';
  }
}
