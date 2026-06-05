import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../models/match.dart';
import '../utils/date_formatter.dart';

class MatchCard extends StatelessWidget {
  final GameMatch match;
  final String winnerName;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.winnerName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gameLabel = match.gameType == AppStrings.gameTypeCallbreak
        ? AppStrings.callbreakTitle
        : AppStrings.marriageTitle;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          match.gameType == AppStrings.gameTypeCallbreak
              ? Icons.sports_esports
              : Icons.celebration,
        ),
        title: Text(gameLabel),
        subtitle: Text(DateFormatter.formatDate(match.startTime)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(AppStrings.winner),
            Text(winnerName, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
