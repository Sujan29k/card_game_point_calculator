import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../providers/match_provider.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF0F0B1E);
  static const surface   = Color(0xFF1A1535);
  static const card      = Color(0xFF1E1945);
  static const border    = Color(0xFF332B60);
  static const accent    = Color(0xFFB48EFF);
  static const gold      = Color(0xFFFFD060);
  static const textPri   = Color(0xFFF0ECFF);
  static const textSec   = Color(0xFF9B8FCC);

  static const List<Color> avatarColors = [
    Color(0xFF6C4FFF),
    Color(0xFFFF6B9D),
    Color(0xFF4FFFB0),
    Color(0xFFFFD060),
    Color(0xFF5BBFFF),
  ];
}

class MarriageSetupScreen extends StatefulWidget {
  const MarriageSetupScreen({super.key});

  @override
  State<MarriageSetupScreen> createState() => _MarriageSetupScreenState();
}

class _MarriageSetupScreenState extends State<MarriageSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _players = [
    TextEditingController(text: 'Player 1'),
    TextEditingController(text: 'Player 2'),
    TextEditingController(text: 'Player 3'),
    TextEditingController(text: 'Player 4'),
  ];

  late AnimationController _suitCtrl;
  late Animation<double> _suitAnim;

  @override
  void initState() {
    super.initState();
    _suitCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _suitAnim = CurvedAnimation(parent: _suitCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    for (final c in _players) {
      c.dispose();
    }
    _suitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _C.textPri),
        title: const Text(
          'Marriage Setup',
          style: TextStyle(
              color: _C.textPri, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              _buildHeroCard(),
              const SizedBox(height: 24),
              const Text(
                'PLAYERS',
                style: TextStyle(
                  color: _C.textSec,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ..._buildPlayerFields(),
              const SizedBox(height: 10),
              _buildPlayerControls(),
              const SizedBox(height: 16),
              _buildRuleCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildStartButton(),
    );
  }

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _suitAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                  const Color(0xFF3B1FA8), const Color(0xFF8B1A6B), _suitAnim.value)!,
              Color.lerp(
                  const Color(0xFF1A0F3C), const Color(0xFF2B0A4A), _suitAnim.value)!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color.lerp(_C.accent, _C.gold, _suitAnim.value)!
                .withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SuitBadge('♥', _C.gold),
                const SizedBox(width: 10),
                _SuitBadge('♦', _C.gold.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                _SuitBadge('♣', _C.accent),
                const SizedBox(width: 10),
                _SuitBadge('♠', _C.accent.withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Marriage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '3-pack Rummy · Nepal',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _C.accent, size: 15),
              SizedBox(width: 6),
              Text(
                'Quick Rules',
                style: TextStyle(
                  color: _C.textPri,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            ('💍', 'Marriage = jhiplu + tiplu + poplu (10 pts)'),
            ('🃏', 'Tiplu = chosen wild card (3 / 7 pts)'),
            ('⭐', 'Mal = cards next to tiplu (2–20 pts)'),
            ('🔁', 'Tunnela = 3 identical cards (5–20 pts)'),
            ('👁', 'Seen joker: pay 3 pts · Unseen: pay 10 pts'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                          color: _C.textSec, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerFields() {
    return List.generate(_players.length, (i) {
      final color = _C.avatarColors[i % _C.avatarColors.length];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _players[i],
                style: const TextStyle(color: _C.textPri),
                cursorColor: _C.accent,
                decoration: InputDecoration(
                  labelText: 'Player ${i + 1}',
                  labelStyle: const TextStyle(color: _C.textSec),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _C.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: color, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFFF6B8A)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFFF6B8A)),
                  ),
                  filled: true,
                  fillColor: _C.card,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? AppStrings.valueInvalid
                    : null,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlayerControls() {
    return Row(
      children: [
        if (_players.length < 5)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.accent,
              side: const BorderSide(color: _C.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _addPlayer,
            icon: const Icon(Icons.person_add_rounded, size: 16),
            label: const Text('Add Player'),
          ),
        if (_players.length < 5 && _players.length > 2)
          const SizedBox(width: 10),
        if (_players.length > 2)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B8A),
              side: const BorderSide(color: _C.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _removePlayer,
            icon: const Icon(Icons.person_remove_rounded, size: 16),
            label: const Text('Remove'),
          ),
        const Spacer(),
        Text(
          '${_players.length} / 5',
          style: const TextStyle(color: _C.textSec, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _C.accent,
          foregroundColor: _C.bg,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 16),
        ),
        onPressed: _startMatch,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💍', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Text('Start Marriage Game'),
          ],
        ),
      ),
    );
  }

  void _addPlayer() {
    if (_players.length >= 5) return;
    setState(() => _players.add(
          TextEditingController(text: 'Player ${_players.length + 1}'),
        ));
  }

  void _removePlayer() {
    if (_players.length <= 2) return;
    setState(() => _players.removeLast().dispose());
  }

  void _startMatch() {
    if (!_formKey.currentState!.validate()) return;
    final names = _players.map((c) => c.text.trim()).toList();
    context.read<MatchProvider>().createMatch(
          gameType: AppStrings.gameTypeMarriage,
          playerNames: names,
        );
    Navigator.pushReplacementNamed(context, AppRoutes.marriageGame);
  }
}

class _SuitBadge extends StatelessWidget {
  final String suit;
  final Color color;
  const _SuitBadge(this.suit, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      suit,
      style: TextStyle(
        fontSize: 32,
        color: color,
        shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 12)],
      ),
    );
  }
}
