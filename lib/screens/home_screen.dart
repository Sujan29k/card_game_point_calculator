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
  // Light
  static const bg           = Color(0xFFF4F1FF);
  static const surface      = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE2DCF5);
  static const accent       = Color(0xFF6C4FFF);
  static const accentSoft   = Color(0xFFEDE9FF);
  static const gold         = Color(0xFFD4960A);
  static const textPrimary  = Color(0xFF1A1535);
  static const textSecond   = Color(0xFF7B7295);

  // Dark
  static const darkBg       = Color(0xFF0F0B1E);
  static const darkSurface  = Color(0xFF1A1535);
  static const darkCard     = Color(0xFF1E1945);
  static const darkBorder   = Color(0xFF332B60);
  static const darkAccent   = Color(0xFFB48EFF);
  static const darkGold     = Color(0xFFFFD060);
  static const darkTextPri  = Color(0xFFF0ECFF);
  static const darkTextSec  = Color(0xFF9B8FCC);
}
// ───────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<GameMatch>> _matchesFuture;
  late AnimationController _helloCtrl;
  late Animation<double> _helloAnim;

  @override
  void initState() {
    super.initState();
    context.read<MatchProvider>().loadActiveMatch();
    _matchesFuture = StorageService.instance.getAllMatches();
    _helloCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _helloAnim = CurvedAnimation(parent: _helloCtrl, curve: Curves.easeOut);
    _helloCtrl.forward();
  }

  @override
  void dispose() {
    _helloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final matchProvider = context.watch<MatchProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? _C.darkBg : _C.bg,
      appBar: _buildAppBar(context, themeProvider, isDark),
      body: SafeArea(
        child: FutureBuilder<List<GameMatch>>(
          future: _matchesFuture,
          builder: (context, snapshot) {
            final matches = snapshot.data ?? [];
            return FadeTransition(
              opacity: _helloAnim,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  _GameRow(isDark: isDark),
                  const SizedBox(height: 14),
                  if (matchProvider.currentMatch != null) ...[
                    _ContinueCard(
                        match: matchProvider.currentMatch!, isDark: isDark),
                    const SizedBox(height: 14),
                  ],
                  _StatsRow(matches: matches, isDark: isDark),
                  const SizedBox(height: 24),
                  _SectionHeader(title: AppStrings.recentMatches, isDark: isDark),
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
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ThemeProvider tp, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? _C.darkSurface : _C.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🃏', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Card Score Tracker',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? _C.darkTextPri : _C.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
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
        const SizedBox(width: 6),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDark ? _C.darkBorder : _C.border,
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

  const _AppBarBtn(
      {required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark ? _C.darkCard : _C.accentSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? _C.darkAccent : _C.accent,
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
            sub: '4 Players · Tricks',
            emoji: '♠',
            gradient: isDark
                ? [const Color(0xFF1B3A6B), const Color(0xFF0D1F3C)]
                : [const Color(0xFFE8F0FF), const Color(0xFFCFDEFF)],
            emojiColor: isDark ? const Color(0xFF5BB8FF) : const Color(0xFF1E5FCC),
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, AppRoutes.callbreakSetup),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GameCard(
            title: 'Marriage',
            sub: '2–5 Players · Rummy',
            emoji: '♥',
            gradient: isDark
                ? [const Color(0xFF5B1A3A), const Color(0xFF2B0A1E)]
                : [const Color(0xFFFFEAF0), const Color(0xFFFFCEDE)],
            emojiColor: isDark ? const Color(0xFFFF6B9D) : const Color(0xFFCC1455),
            isDark: isDark,
            onTap: () => Navigator.pushNamed(context, AppRoutes.marriageSetup),
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatefulWidget {
  final String title;
  final String sub;
  final String emoji;
  final List<Color> gradient;
  final Color emojiColor;
  final bool isDark;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.sub,
    required this.emoji,
    required this.gradient,
    required this.emojiColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hover;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _hover, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark ? _C.darkBorder : _C.border;

    return GestureDetector(
      onTapDown: (_) => _hover.forward(),
      onTapUp: (_) {
        _hover.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hover.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: widget.emojiColor.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background watermark suit
              Positioned(
                right: -10,
                bottom: -14,
                child: Text(
                  widget.emoji,
                  style: TextStyle(
                    fontSize: 80,
                    color: widget.emojiColor.withValues(alpha: 0.08),
                    height: 1,
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.emoji,
                      style: TextStyle(
                        fontSize: 36,
                        color: widget.emojiColor,
                        shadows: [
                          Shadow(
                            color: widget.emojiColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                        height: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isDark ? _C.darkTextPri : _C.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.sub,
                      style: TextStyle(
                        color: widget.isDark
                            ? _C.darkTextSec
                            : _C.textSecond,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
    final emoji = isCallbreak ? '♠' : '♥';
    final accentColor = isCallbreak
        ? const Color(0xFF5BB8FF)
        : const Color(0xFFFF6B9D);

    return Material(
      color: isDark ? _C.darkCard : _C.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          isCallbreak ? AppRoutes.callbreakGame : AppRoutes.marriageGame,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: 22, color: accentColor),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue $label',
                      style: TextStyle(
                        color: isDark ? _C.darkTextPri : _C.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${match.rounds.length} rounds · ${DateFormatter.formatDateTime(match.startTime)}',
                      style: TextStyle(
                        color: isDark ? _C.darkTextSec : _C.textSecond,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Resume',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
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
    final players = <String>{};
    final wins = <String, int>{};
    String topName = '—';
    int topWins = 0;

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
            label: 'Matches',
            icon: Icons.sports_esports_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: '${players.length}',
            label: 'Players',
            icon: Icons.people_rounded,
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
            isGold: true,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;
  final bool isGold;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.isDark,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isGold ? (isDark ? _C.darkGold : _C.gold) : (isDark ? _C.darkAccent : _C.accent);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? _C.darkCard : _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _C.darkBorder : _C.border,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? _C.darkTextPri : _C.textPrimary,
              fontSize: isGold ? 12 : 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? _C.darkTextSec : _C.textSecond,
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
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: isDark ? _C.darkAccent : _C.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isDark ? _C.darkTextPri : _C.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
    final emoji = isCallbreak ? '♠' : '♥';
    final label = isCallbreak ? 'Call Break' : 'Marriage';
    final accentColor = isCallbreak
        ? const Color(0xFF5BB8FF)
        : const Color(0xFFFF6B9D);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? _C.darkCard : _C.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isDark ? _C.darkBorder : _C.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Suit badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style:
                          TextStyle(fontSize: 22, color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isDark ? _C.darkTextPri : _C.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatDateTime(match.startTime),
                        style: TextStyle(
                          color: isDark ? _C.darkTextSec : _C.textSecond,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Winner: $winnerName',
                        style: TextStyle(
                          color: isDark ? _C.darkTextSec : _C.textSecond,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${match.rounds.length}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Rounds',
                      style: TextStyle(
                        color: isDark ? _C.darkTextSec : _C.textSecond,
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
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: isDark ? _C.darkCard : _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? _C.darkBorder : _C.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '🃏',
            style: TextStyle(
              fontSize: 44,
              shadows: [
                Shadow(
                  color: (isDark ? _C.darkAccent : _C.accent)
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No matches yet',
            style: TextStyle(
              color: isDark ? _C.darkTextPri : _C.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a game above to see your history here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? _C.darkTextSec : _C.textSecond,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}