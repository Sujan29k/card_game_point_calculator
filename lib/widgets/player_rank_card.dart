import 'package:flutter/material.dart';

class PlayerRankCard extends StatelessWidget {
  final String playerName;
  final int wins;

  const PlayerRankCard({
    super.key,
    required this.playerName,
    required this.wins,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.emoji_events),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                playerName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text('$wins', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
