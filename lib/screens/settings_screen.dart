// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatefulWidget
{
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
{
  late TextEditingController _wageController;
  late TextEditingController _nicknameController;
  late TextEditingController _statusController; // Nieuwe controller
  final _formKey = GlobalKey<FormState>();

  @override
  void initState()
  {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _wageController = TextEditingController(
      text: appState.hourlyWage > 0 ? appState.hourlyWage.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _nicknameController = TextEditingController(text: appState.userName == "Anonieme Held" ? "" : appState.userName);
    _statusController = TextEditingController(text: appState.userStatus); // Initialiseer status
  }

  @override
  void dispose()
  {
    _wageController.dispose();
    _nicknameController.dispose();
    _statusController.dispose(); // Dispose
    super.dispose();
  }

  void _saveWage()
  {
    if (_wageController.text.trim().isNotEmpty) {
        final wage = double.tryParse(_wageController.text.replaceAll(',', '.'));
        if (wage != null && wage > 0)
        {
            Provider.of<AppState>(context, listen: false).setHourlyWage(wage);
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Uurloon opgeslagen!'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
            ),
            );
        }
        else
        {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Voer een geldig uurloon in.'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(10),
            ),
            );
        }
    } else {
        Provider.of<AppState>(context, listen: false).setHourlyWage(0.0);
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Uurloon verwijderd.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
    }
  }

  void _saveNickname() {
    if (_formKey.currentState!.validate()) {
        final newName = _nicknameController.text.trim();
        Provider.of<AppState>(context, listen: false).setUserName(newName);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: const Text('Nickname opgeslagen!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            ),
        );
    }
  }

  void _saveStatus() { // Nieuwe methode
    final newStatus = _statusController.text.trim();
    Provider.of<AppState>(context, listen: false).setUserStatus(newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
        content: const Text('Troon Gedachten opgeslagen!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        ),
    );
  }


  Future<void> _confirmAndResetData() async
  {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext)
      {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Reset Bevestigen'),
          content: const Text('Weet je zeker dat je alle opgeslagen gegevens (uurloon, nickname, status, sessiegeschiedenis en prestaties) wilt verwijderen? Dit reset ook je leaderboard score.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: ()
              {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Resetten'),
              onPressed: ()
              {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted)
    {
      await Provider.of<AppState>(context, listen: false).resetAllData();
      _wageController.clear();
      _nicknameController.clear();
      _statusController.clear(); // Wis status veld
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alle gegevens zijn gereset!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSectionTitle(context, 'Jouw Profiel'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  hintText: 'Bijv. Koning Kak',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                style: theme.textTheme.titleMedium,
                maxLength: 20,
                validator: (value) {
                    if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
                      return 'Nickname moet minimaal 3 tekens lang zijn.';
                    }
                    return null;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saveNickname,
                child: const Text('Nickname Opslaan'),
              ),
              const SizedBox(height: 24),
              TextFormField( // Troon Gedachten Veld
                controller: _statusController,
                decoration: const InputDecoration(
                  labelText: 'Troon Gedachten (Status)',
                  hintText: 'Deel je wijsheid...',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                ),
                style: theme.textTheme.titleMedium,
                maxLength: 50, // Limiteer de lengte
                maxLines: null, // Sta meerdere regels toe indien nodig, of zet op 1
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saveStatus,
                child: const Text('Status Opslaan'),
              ),


              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Financiële Instellingen'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wageController,
                decoration: const InputDecoration(
                  labelText: 'Uurloon',
                  hintText: 'bijv. 15,50',
                  prefixIcon: Icon(Icons.euro_symbol_rounded),
                ),
                style: theme.textTheme.titleMedium,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),
               ElevatedButton(
                onPressed: _saveWage,
                child: const Text('Uurloon Opslaan'),
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 1),
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Gevaarlijke Zone', color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Hiermee wis je al je opgeslagen uurloon, nickname, status, sessiegeschiedenis en prestaties. Je score op het leaderboard wordt ook gereset.',
                 style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(180)
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
                label: Text(
                  'Reset Alle Gegevens',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: theme.colorScheme.error.withAlpha(150)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _confirmAndResetData,
              ),
              const SizedBox(height: 50),
              Text(
                'Made by Bart Akkerman',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha((0.6 * 255).round())
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {Color? color}) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: color ?? theme.colorScheme.primary,
      ),
    );
  }
}