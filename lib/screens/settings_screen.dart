// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'achievements_screen.dart'; // Importeer AchievementsScreen

class SettingsScreen extends StatefulWidget
{
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
{
  late TextEditingController _wageController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState()
  {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _wageController = TextEditingController(
      text: appState.hourlyWage > 0 ? appState.hourlyWage.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
  }

  @override
  void dispose()
  {
    _wageController.dispose();
    super.dispose();
  }

  void _saveSettings()
  {
    if (_formKey.currentState!.validate())
    {
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
      else if (_wageController.text.isNotEmpty)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voer een geldig bedrag in.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
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
          content: const Text('Weet je zeker dat je alle opgeslagen gegevens (uurloon en sessiegeschiedenis) wilt verwijderen? Dit kan niet ongedaan worden gemaakt.'),
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
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Jouw Uurloon',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              Text(
                'Voer hieronder in hoeveel je per uur verdient. Dit wordt gebruikt om je WC-inkomsten te berekenen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).round())
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _wageController,
                decoration: const InputDecoration(
                  labelText: 'Uurloon',
                  hintText: 'bijv. 15,50',
                  prefixText: '€ ',
                ),
                style: theme.textTheme.titleMedium,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
                ],
                validator: (value)
                {
                  if (value == null || value.isEmpty)
                  {
                    return null;
                  }
                  final n = double.tryParse(value.replaceAll(',', '.'));
                  if (n == null || n <= 0)
                  {
                    return 'Voer een geldig positief bedrag in.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveSettings,
                style: theme.elevatedButtonTheme.style?.copyWith(
                  minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
                ),
                child: const Text('Uurloon Opslaan'),
              ),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.military_tech_outlined, color: theme.colorScheme.primary),
                title: Text('Mijn Prestaties', style: theme.textTheme.titleMedium),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AchievementsScreen()));
                },
              ),
              const Divider(),
              const SizedBox(height: 20),
              Text(
                'Gevaarlijke Zone',
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              Text(
                'Hiermee wis je al je opgeslagen uurloon en sessiegeschiedenis.',
                 style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha((0.7 * 255).round())
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                label: Text(
                  'Reset Alle Gegevens',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: theme.colorScheme.error.withAlpha((0.5 * 255).round())),
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
}