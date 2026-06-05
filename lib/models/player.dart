class Player {
  final String id;
  final String name;
  final int totalWins;
  final int totalMatches;

  const Player({
    required this.id,
    required this.name,
    this.totalWins = 0,
    this.totalMatches = 0,
  });

  Player copyWith({
    String? id,
    String? name,
    int? totalWins,
    int? totalMatches,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      totalWins: totalWins ?? this.totalWins,
      totalMatches: totalMatches ?? this.totalMatches,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalWins': totalWins,
      'totalMatches': totalMatches,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
      totalMatches: (json['totalMatches'] as num?)?.toInt() ?? 0,
    );
  }
}
