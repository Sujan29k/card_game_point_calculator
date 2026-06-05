import 'package:flutter/material.dart';

import '../../constants/app_strings.dart';
import '../../models/match.dart';
import '../../services/storage_service.dart';
import '../../utils/date_formatter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<GameMatch>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = StorageService.instance.getAllMatches();
  }

  Future<void> _confirmResetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset History'),
        content: const Text(
          'This will permanently delete all game history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.instance.clearAllHistory();
      if (!mounted) return;
      setState(
        () => _matchesFuture = StorageService.instance.getAllMatches(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All history cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.history),
        actions: [
          FutureBuilder<List<GameMatch>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              final matches = snapshot.data ?? [];
              final hasHistory = matches.any((m) => m.isCompleted);
              if (!hasHistory) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                tooltip: 'Reset All History',
                onPressed: _confirmResetAll,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<GameMatch>>(
          future: _matchesFuture,
          builder: (context, snapshot) {
            final matches = snapshot.data ?? [];
            final completed = matches.where((m) => m.isCompleted).toList();
            if (completed.isEmpty) {
              return _EmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: completed.length,
              itemBuilder: (context, index) {
                final match = completed[index];
                return Dismissible(
                  key: ValueKey(match.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteMatch(match),
                  child: _MatchTile(match: match),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteMatch(GameMatch match) async {
    await StorageService.instance.deleteMatch(match.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(AppStrings.confirmDeleteMatch),
        action: SnackBarAction(
          label: AppStrings.undo,
          onPressed: () async {
            await StorageService.instance.saveMatch(match);
            setState(
              () => _matchesFuture = StorageService.instance.getAllMatches(),
            );
          },
        ),
      ),
    );
    setState(() => _matchesFuture = StorageService.instance.getAllMatches());
  }
}

class _MatchTile extends StatelessWidget {
  final GameMatch match;

  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final winner = match.players
        .firstWhere(
          (p) => p.id == match.winnerId,
          orElse: () => match.players.first,
        )
        .name;
    return Card(
      child: ListTile(
        leading: Icon(
          match.gameType == AppStrings.gameTypeCallbreak
              ? Icons.sports_esports
              : Icons.celebration,
        ),
        title: Text(
          match.gameType == AppStrings.gameTypeCallbreak
              ? AppStrings.callbreakTitle
              : AppStrings.marriageTitle,
        ),
        subtitle: Text(DateFormatter.formatDate(match.startTime)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${AppStrings.rounds}: ${match.rounds.length}'),
            Text('${AppStrings.winner}: $winner'),
          ],
        ),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.historyDetail,
          arguments: match,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 48),
          const SizedBox(height: 12),
          const Text(AppStrings.noRecentMatches),
        ],
      ),
    );
  }
}
