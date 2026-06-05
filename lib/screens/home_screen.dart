import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../utils/date_formatter.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────
class _C {
  static const bg           = Color(0xFFF6F4FF);
  static const surface      = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE2DCF5);
  static const accent       = Color(0xFF5B4FCF);
  static const accentSoft   = Color(0xFFEDE9FF);
  static const gold         = Color(0xFFD4960A);
  static const goldBg       = Color(0xFFFFF8E6);
  static const textPrimary  = Color(0xFF1A1535);
  static const textSecond   = Color(0xFF7B7295);
}
// ───────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<GameMatch>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    context.read<MatchProvider>().loadActiveMatch();
    _matchesFuture = StorageService.instance.getAllMatches();
  }



  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final matchProvider = context.watch<MatchProvider>();
    final isDark        = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF120F20) : _C.bg,
      appBar: _buildAppBar(context, themeProvider, isDark),
      body: SafeArea(
        child: FutureBuilder<List<GameMatch>>(
          future: _matchesFuture,
          builder: (context, snapshot) {
            final matches = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _GameRow(isDark: isDark),
                const SizedBox(height: 12),
                if (matchProvider.currentMatch != null) ...[
                  _ContinueCard(
                    match: matchProvider.currentMatch!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                ],
                _StatsRow(matches: matches, isDark: isDark),
                const SizedBox(height: 24),
                _SectionHeader(title: AppStrings.recentMatches),
                const SizedBox(height: 10),
                if (matches.isEmpty)
                  _EmptyState(isDark: isDark)
                else
                  ...matches.take(5).map((m) => _MatchTile(
                        match: m,
                        winnerName: _winnerName(m),
                        isDark: isDark,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.historyDetail,
                          arguments: m,
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeProvider tp,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1A1535) : _C.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🃏', style: const TextStyle(fontSize: 25)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Card Score Tracker',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : _C.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [
        _AppBarBtn(
          icon: tp.themeMode == ThemeMode.dark
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          onTap: tp.toggleTheme,
          isDark: isDark,
        ),
      _AppBarBtn(
          icon: Icons.history_rounded,
          onTap: () => Navigator.pushNamed(context, AppRoutes.history),
          isDark: isDark,
        ),
        const SizedBox(width: 5),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: isDark ? Colors.white10 : _C.border,
        ),
      ),
    );
  }

  String _winnerName(GameMatch match) {
    if (match.players.isEmpty) return '—';
    return match.players
        .firstWhere((p) => p.id == match.winnerId,
            orElse: () => match.players.first)
        .name;
  }
}

// ─── App Bar Button ─────────────────────────────────────────────────────────
class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _AppBarBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2148) : _C.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white70 : _C.accent,
          ),
        ),
      ),
    );
  }
}

// ─── Game Selection Row ──────────────────────────────────────────────────────
class _GameRow extends StatelessWidget {
  final bool isDark;

  const _GameRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GameCard(
            title: 'Call Break',
            sub: '4 Players',
            suit: '♠',
            isDark: isDark,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.callbreakSetup),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GameCard(
            title: 'Marriage',
            sub: '3–6 Players',
            suit: '♥',
            isDark: isDark,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.marriageSetup),
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String sub;
  final String suit;
  final bool isDark;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.sub,
    required this.suit,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1A38) : _C.surface;
    final borderCol = isDark ? const Color(0xFF3A3360) : _C.border;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                suit,
                style: TextStyle(
                  fontSize: 38,
                  color: _C.gold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : _C.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                style: TextStyle(
                  color: isDark ? Colors.white54 : _C.textSecond,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Continue Card ───────────────────────────────────────────────────────────
class _ContinueCard extends StatelessWidget {
  final GameMatch match;
  final bool isDark;

  const _ContinueCard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isCallbreak = match.gameType == AppStrings.gameTypeCallbreak;
    final label = isCallbreak ? 'Call Break' : 'Marriage';
    final cardBg = isDark ? const Color(0xFF1E1A38) : _C.surface;
    final borderCol = isDark ? const Color(0xFF3A3360) : _C.border;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          isCallbreak ? AppRoutes.callbreakGame : AppRoutes.marriageGame,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2D2860)
                      : _C.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.replay_rounded,
                  color: isDark ? Colors.white70 : _C.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Active Match',
                      style: TextStyle(
                        color: isDark ? Colors.white : _C.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$label · ${DateFormatter.formatDateTime(match.startTime)}',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : _C.textSecond,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : _C.textSecond,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<GameMatch> matches;
  final bool isDark;

  const _StatsRow({required this.matches, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final completed = matches.where((m) => m.isCompleted).toList();
    final players   = <String>{};
    final wins      = <String, int>{};
    String topName  = '—';
    int topWins     = 0;

    for (final m in completed) {
      for (final p in m.players) {
        players.add(p.id);
      }
      if (m.winnerId != null) {
        wins[m.winnerId!] = (wins[m.winnerId!] ?? 0) + 1;
      }
    }
    wins.forEach((id, cnt) {
      if (cnt > topWins) {
        topWins = cnt;
        final p = completed
            .expand((m) => m.players)
            .where((p) => p.id == id)
            .firstOrNull;
        if (p != null) topName = p.name;
      }
    });

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            value: '${completed.length}',
            label: 'Total Matches',
            icon: null,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '${players.length}',
            label: 'Total Players',
            icon: null,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: topName,
            label: 'Top Winner',
            icon: Icons.emoji_events_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final bool isDark;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg    = isDark ? const Color(0xFF1E1A38) : _C.surface;
    final borderCol = isDark ? const Color(0xFF3A3360) : _C.border;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, color: _C.gold, size: 22)
          else
            Text(
              value,
              style: TextStyle(
                color: _C.accent,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          const SizedBox(height: 5),
          if (icon != null) ...[
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : _C.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white38 : _C.textSecond,
                fontSize: 11,
              ),
            ),
          ] else
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white38 : _C.textSecond,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ─── Match Tile ──────────────────────────────────────────────────────────────
class _MatchTile extends StatelessWidget {
  final GameMatch match;
  final String winnerName;
  final bool isDark;
  final VoidCallback onTap;

  const _MatchTile({
    required this.match,
    required this.winnerName,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCallbreak = match.gameType == AppStrings.gameTypeCallbreak;
    final suit        = isCallbreak ? '♠' : '♥';
    final label       = isCallbreak ? 'Call Break' : 'Marriage';
    final cardBg      = isDark ? const Color(0xFF1E1A38) : _C.surface;
    final borderCol   = isDark ? const Color(0xFF3A3360) : _C.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol, width: 1),
            ),
            child: Row(
              children: [
                // Suit badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2148)
                        : _C.goldBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      suit,
                      style: const TextStyle(
                        fontSize: 20,
                        color: _C.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isDark ? Colors.white : _C.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatDateTime(match.startTime),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : _C.textSecond,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Winner: $winnerName',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : _C.textSecond,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Round count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${match.rounds.length}',
                      style: TextStyle(
                        color: _C.accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Rounds',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : _C.textSecond,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A38) : _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3360) : _C.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.style_rounded,
            size: 40,
            color: isDark ? Colors.white24 : _C.textSecond.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No matches yet.\nStart a game to see history here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : _C.textSecond,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}