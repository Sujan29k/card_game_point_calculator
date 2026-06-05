import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_strings.dart';
import '../../providers/match_provider.dart';

class CallBreakSetupScreen extends StatefulWidget {
  const CallBreakSetupScreen({super.key});

  @override
  State<CallBreakSetupScreen> createState() => _CallBreakSetupScreenState();
}

class _CallBreakSetupScreenState extends State<CallBreakSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _players = List.generate(4, (i) => TextEditingController());
  final _roundCountController = TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _players.length; i++) {
      _players[i].text = '${AppStrings.playerDefault} ${i + 1}';
    }
  }

  @override
  void dispose() {
    for (final c in _players) {
      c.dispose();
    }
    _roundCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.callbreakTitle)),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roundCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: AppStrings.numberOfRounds,
                    helperText: AppStrings.numberOfRoundsHint,
                  ),
                  validator: _validateRoundCount,
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
          validator: (value) =>
              value == null || value.trim().isEmpty ? AppStrings.valueInvalid : null,
        ),
      );
    });
  }

  String? _validateRoundCount(String? value) {
    if (value == null || value.isEmpty) return AppStrings.valueInvalid;
    final n = int.tryParse(value);
    if (n == null || n < 0) return AppStrings.valueInvalid;
    return null;
  }

  void _startMatch() {
    if (!_formKey.currentState!.validate()) return;
    final names = _players.map((c) => c.text.trim()).toList();
    final roundCount = int.tryParse(_roundCountController.text) ?? 4;
    context.read<MatchProvider>().createMatch(
      gameType: AppStrings.gameTypeCallbreak,
      playerNames: names,
      roundCount: roundCount <= 0 ? null : roundCount,
    );
    Navigator.pushReplacementNamed(context, AppRoutes.callbreakGame);
  }
}
