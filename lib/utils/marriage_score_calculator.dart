import '../models/marriage_round_meta.dart';

/// Implements the official Marriage card-game scoring rules.
///
/// Scoring table (from official rules):
/// ┌──────────────────────┬────────┬────────┬────────┬─────────┐
/// │ Item                 │ Single │ Double │ Triple │ Tunnela │
/// ├──────────────────────┼────────┼────────┼────────┼─────────┤
/// │ Ordinary card        │   —    │   —    │   —    │    5    │
/// │ Ordinary joker       │   —    │   —    │   —    │   10    │
/// │ Poplu / jhiplu (mal) │   2    │   5    │   10   │   20    │
/// │ Tiplu                │   3    │   7    │   —    │   —     │
/// │ Marriage             │  10    │  30    │   —    │   —     │
/// └──────────────────────┴────────┴────────┴────────┴─────────┘
///
/// Net payment formula:
///   T  = sum of ALL players' card points
///   w  = 3 (if seen joker) or 10 (if not seen), plus 5 if winner used dublees
///   payment_i = T + w_i − (n × S_i)
///   • positive → player pays that amount to the winner
///   • negative → winner pays that amount to the player
class MarriageScoreCalculator {
  MarriageScoreCalculator._();

  // ── Card-point values ────────────────────────────────────────────────────

  static const int _malSinglePts        = 2;
  static const int _malDoublePts        = 5;
  static const int _malTriplePts        = 10;
  static const int _malTunnelaPts       = 20;
  static const int _tipluSinglePts      = 3;
  static const int _tipluDoublePts      = 7;
  static const int _marriageSinglePts   = 10;
  static const int _marriageDoublePts   = 30;
  static const int _tunnelaNormalPts    = 5;
  static const int _tunnelaOrdJokerPts  = 10;

  /// Returns the raw card-point total for one player in a single deal.
  static int cardPoints(MarriageRoundMeta meta) {
    int pts = 0;

    // Tiplu
    if (meta.tipluCount == 1) pts += _tipluSinglePts;
    if (meta.tipluCount == 2) pts += _tipluDoublePts;

    // Mal (poplu / jhiplu)
    pts += meta.malSingle  * _malSinglePts;
    pts += meta.malDouble  * _malDoublePts;
    pts += meta.malTriple  * _malTriplePts;
    pts += meta.malTunnela * _malTunnelaPts;

    // Marriage
    pts += meta.marriageSingle * _marriageSinglePts;
    pts += meta.marriageDouble * _marriageDoublePts;

    // Tunnelas
    pts += meta.tunnelaNormal       * _tunnelaNormalPts;
    pts += meta.tunnelaOrdinaryJoker * _tunnelaOrdJokerPts;

    return pts;
  }

  /// Computes the net payment each player owes to (or receives from) the winner.
  ///
  /// Returns a map keyed by player ID.
  /// Positive value  → the player pays that many points to the winner.
  /// Negative value  → the winner pays that many points to the player.
  ///
  /// [allMeta]  – map of playerId → MarriageRoundMeta for all players.
  /// [winnerId] – the player who ended the game this deal.
  static Map<String, int> computeNetPayments({
    required Map<String, MarriageRoundMeta> allMeta,
    required String winnerId,
  }) {
    final n = allMeta.length;
    final winnerMeta = allMeta[winnerId];
    final isDubleeWin = winnerMeta?.dubleeWin ?? false;

    // T = sum of all players' card points
    final T = allMeta.values.fold<int>(0, (sum, m) => sum + cardPoints(m));

    final payments = <String, int>{};
    allMeta.forEach((playerId, meta) {
      final S = cardPoints(meta);
      // w = 3 if seen joker, 10 if not seen, +5 if winner used dublees
      final w = (meta.seenJoker ? 3 : 10) + (isDubleeWin ? 5 : 0);
      payments[playerId] = T + w - (n * S);
    });

    return payments;
  }

  /// Convenience: format a payment value for display.
  /// Positive = paying the winner, shown with + prefix.
  /// Negative = receiving from winner, shown as-is.
  static String formatPayment(int payment) {
    if (payment > 0) return '+$payment';
    return '$payment';
  }

  /// Card-point breakdown label for a single player (for display/tooltip).
  static String breakdownLabel(MarriageRoundMeta meta) {
    final parts = <String>[];

    if (meta.tipluCount == 1) parts.add('Tiplu(1)=3');
    if (meta.tipluCount == 2) parts.add('Tiplu(2)=7');

    if (meta.malSingle  > 0) parts.add('Mal×${meta.malSingle}=${meta.malSingle * _malSinglePts}');
    if (meta.malDouble  > 0) parts.add('Mal×2×${meta.malDouble}=${meta.malDouble * _malDoublePts}');
    if (meta.malTriple  > 0) parts.add('Mal×3×${meta.malTriple}=${meta.malTriple * _malTriplePts}');
    if (meta.malTunnela > 0) parts.add('MalTun×${meta.malTunnela}=${meta.malTunnela * _malTunnelaPts}');

    if (meta.marriageSingle > 0) parts.add('Marriage(1)=10');
    if (meta.marriageDouble > 0) parts.add('Marriage(2)=30');

    if (meta.tunnelaNormal       > 0) parts.add('Tunnela×${meta.tunnelaNormal}=${meta.tunnelaNormal * _tunnelaNormalPts}');
    if (meta.tunnelaOrdinaryJoker > 0) parts.add('JkrTun×${meta.tunnelaOrdinaryJoker}=${meta.tunnelaOrdinaryJoker * _tunnelaOrdJokerPts}');

    if (parts.isEmpty) return '0 pts';
    return '${parts.join(' + ')} = ${cardPoints(meta)} pts';
  }
}
