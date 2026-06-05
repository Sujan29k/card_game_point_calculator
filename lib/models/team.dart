class Team {
  final String id;
  final String name;
  final List<String> playerIds;

  const Team({required this.id, required this.name, required this.playerIds});

  Team copyWith({String? id, String? name, List<String>? playerIds}) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      playerIds: playerIds ?? this.playerIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'playerIds': playerIds};
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      playerIds: (json['playerIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
