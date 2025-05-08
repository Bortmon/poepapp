// lib/screens/nickname_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'home_screen.dart';

class NicknameSetupScreen extends StatefulWidget {
  const NicknameSetupScreen({super.key});

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitNickname() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.setUserName(_nicknameController.text.trim());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welkom, Poepende Held!',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Voer een nickname in. Deze wordt gebruikt op het leaderboard zodat andere helden je kunnen herkennen.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    hintText: 'Bijv. Koning Kak',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Voer alsjeblieft een nickname in.';
                    }
                    if (value.trim().length < 3) {
                      return 'Nickname moet minimaal 3 tekens lang zijn.';
                    }
                    if (value.trim().length > 20) {
                      return 'Nickname mag maximaal 20 tekens lang zijn.';
                    }
                    return null;
                  },
                  maxLength: 20,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Doorgaan'),
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        onPressed: _submitNickname,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}