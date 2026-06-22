/// Per-player metadata for one Marriage deal (round).
///
/// This holds the raw card-combination counts so the score calculator can
/// derive both card-point totals and net payment values.
class MarriageRoundMeta {
  /// Did this player look at the tiplu (seen joker)?
  final bool seenJoker;

  // ── Tiplu (wild card itself) ─────────────────────────────────
  /// Number of tiplu cards held (1 or 2; triple/tunnela not in table).
  final int tipluCount; // 0–2

  // ── Mal: poplu or jhiplu (cards immediately above/below tiplu) ──
  /// Single poplu/jhiplu held (each = 2 pts).
  final int malSingle; // 0–6  (up to 3 poplu + 3 jhiplu)

  /// Pair of identical mal held (poplu-poplu or jhiplu-jhiplu) = 5 pts.
  final int malDouble; // 0–3

  /// Triple identical mal = 10 pts.
  final int malTriple; // 0–2

  /// Tunnela of mal (three identical mal) = 20 pts.
  /// (e.g. all three jhiplu or all three poplu in hand)
  final int malTunnela; // 0–2

  // ── Marriage (jhiplu + tiplu + poplu in hand) ─────────────────
  /// Single marriage = 10 pts.
  final int marriageSingle; // 0–1

  /// Double marriage (player holds two marriages) = 30 pts each.
  final int marriageDouble; // 0–1 (each "double" marriage = 30 pts)

  // ── Tunnelas ─────────────────────────────────────────────────
  /// Exposed ordinary-card tunnelas = 5 pts each.
  final int tunnelaNormal; // 0–n

  /// Exposed ordinary-joker tunnelas = 10 pts each.
  final int tunnelaOrdinaryJoker; // 0–n

  // ── Win condition ────────────────────────────────────────────
  /// True if this player is the one who ended the deal (the "winner").
  final bool isWinner;

  /// True if winner ended with 8 dublees (extra 5 pts penalty for others).
  final bool dubleeWin;

  const MarriageRoundMeta({
    this.seenJoker = true,
    this.tipluCount = 0,
    this.malSingle = 0,
    this.malDouble = 0,
    this.malTriple = 0,
    this.malTunnela = 0,
    this.marriageSingle = 0,
    this.marriageDouble = 0,
    this.tunnelaNormal = 0,
    this.tunnelaOrdinaryJoker = 0,
    this.isWinner = false,
    this.dubleeWin = false,
  });

  MarriageRoundMeta copyWith({
    bool? seenJoker,
    int? tipluCount,
    int? malSingle,
    int? malDouble,
    int? malTriple,
    int? malTunnela,
    int? marriageSingle,
    int? marriageDouble,
    int? tunnelaNormal,
    int? tunnelaOrdinaryJoker,
    bool? isWinner,
    bool? dubleeWin,
  }) {
    return MarriageRoundMeta(
      seenJoker: seenJoker ?? this.seenJoker,
      tipluCount: tipluCount ?? this.tipluCount,
      malSingle: malSingle ?? this.malSingle,
      malDouble: malDouble ?? this.malDouble,
      malTriple: malTriple ?? this.malTriple,
      malTunnela: malTunnela ?? this.malTunnela,
      marriageSingle: marriageSingle ?? this.marriageSingle,
      marriageDouble: marriageDouble ?? this.marriageDouble,
      tunnelaNormal: tunnelaNormal ?? this.tunnelaNormal,
      tunnelaOrdinaryJoker: tunnelaOrdinaryJoker ?? this.tunnelaOrdinaryJoker,
      isWinner: isWinner ?? this.isWinner,
      dubleeWin: dubleeWin ?? this.dubleeWin,
    );
  }

  Map<String, dynamic> toJson() => {
        'seenJoker': seenJoker,
        'tipluCount': tipluCount,
        'malSingle': malSingle,
        'malDouble': malDouble,
        'malTriple': malTriple,
        'malTunnela': malTunnela,
        'marriageSingle': marriageSingle,
        'marriageDouble': marriageDouble,
        'tunnelaNormal': tunnelaNormal,
        'tunnelaOrdinaryJoker': tunnelaOrdinaryJoker,
        'isWinner': isWinner,
        'dubleeWin': dubleeWin,
      };

  factory MarriageRoundMeta.fromJson(Map<String, dynamic> json) =>
      MarriageRoundMeta(
        seenJoker: json['seenJoker'] as bool? ?? true,
        tipluCount: (json['tipluCount'] as num?)?.toInt() ?? 0,
        malSingle: (json['malSingle'] as num?)?.toInt() ?? 0,
        malDouble: (json['malDouble'] as num?)?.toInt() ?? 0,
        malTriple: (json['malTriple'] as num?)?.toInt() ?? 0,
        malTunnela: (json['malTunnela'] as num?)?.toInt() ?? 0,
        marriageSingle: (json['marriageSingle'] as num?)?.toInt() ?? 0,
        marriageDouble: (json['marriageDouble'] as num?)?.toInt() ?? 0,
        tunnelaNormal: (json['tunnelaNormal'] as num?)?.toInt() ?? 0,
        tunnelaOrdinaryJoker:
            (json['tunnelaOrdinaryJoker'] as num?)?.toInt() ?? 0,
        isWinner: json['isWinner'] as bool? ?? false,
        dubleeWin: json['dubleeWin'] as bool? ?? false,
      );
}
