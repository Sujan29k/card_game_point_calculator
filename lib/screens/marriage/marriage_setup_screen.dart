import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../providers/match_provider.dart';

class MarriageSetupScreen extends StatefulWidget {
  const MarriageSetupScreen({super.key});

  @override
  State<MarriageSetupScreen> createState() => _MarriageSetupScreenState();
}

class _MarriageSetupScreenState extends State<MarriageSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _players = [
    TextEditingController(text: '${AppStrings.playerDefault} 1'),
    TextEditingController(text: '${AppStrings.playerDefault} 2'),
    TextEditingController(text: '${AppStrings.playerDefault} 3'),
    TextEditingController(text: '${AppStrings.playerDefault} 4'),
  ];

  final _maalController = TextEditingController(text: '10');
  final _seenController = TextEditingController(text: '10');
  final _marriageController = TextEditingController(text: '30');

  @override
  void dispose() {
    for (final controller in _players) {
      controller.dispose();
    }
    _maalController.dispose();
    _seenController.dispose();
    _marriageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.marriageTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  AppStrings.players,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ..._buildPlayerFields(),
                _PlayerControls(
                  canAdd: _players.length < 6,
                  canRemove: _players.length > 3,
                  onAdd: _addPlayer,
                  onRemove: _removePlayer,
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text(AppStrings.bonusConfig),
                  children: [
                    _buildBonusField(AppStrings.maalBonus, _maalController),
                    const SizedBox(height: 12),
                    _buildBonusField(AppStrings.seenBonus, _seenController),
                    const SizedBox(height: 12),
                    _buildBonusField(
                      AppStrings.marriageBonus,
                      _marriageController,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _startMatch,
                  child: const Text(AppStrings.startMatch),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlayerFields() {
    return List.generate(_players.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _players[index],
          decoration: InputDecoration(
            labelText: '${AppStrings.playerName} ${index + 1}',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? AppStrings.valueInvalid
              : null,
        ),
      );
    });
  }

  Widget _buildBonusField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse(value ?? '');
        if (parsed == null) return AppStrings.valueInvalid;
        return null;
      },
    );
  }

  void _addPlayer() {
    if (_players.length >= 6) return;
    setState(
      () => _players.add(
        TextEditingController(
          text: '${AppStrings.playerDefault} ${_players.length + 1}',
        ),
      ),
    );
  }

  void _removePlayer() {
    if (_players.length <= 3) return;
    setState(() => _players.removeLast().dispose());
  }

  void _startMatch() {
    if (!_formKey.currentState!.validate()) return;
    final names = _players.map((c) => c.text.trim()).toList();
    final bonusConfig = {
      'maal': int.tryParse(_maalController.text) ?? 10,
      'seen': int.tryParse(_seenController.text) ?? 10,
      'marriage': int.tryParse(_marriageController.text) ?? 30,
    };
    context.read<MatchProvider>().createMatch(
      gameType: AppStrings.gameTypeMarriage,
      playerNames: names,
      bonusConfig: bonusConfig,
    );
    Navigator.pushReplacementNamed(context, AppRoutes.marriageGame);
  }
}

class _PlayerControls extends StatelessWidget {
  final bool canAdd;
  final bool canRemove;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _PlayerControls({
    required this.canAdd,
    required this.canRemove,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: canAdd ? onAdd : null,
          icon: const Icon(Icons.person_add),
          label: const Text(AppStrings.addPlayer),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: canRemove ? onRemove : null,
          icon: const Icon(Icons.person_remove),
          label: const Text(AppStrings.removePlayer),
        ),
      ],
    );
  }
}
