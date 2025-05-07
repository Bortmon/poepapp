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
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Jouw Uurloon',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Voer hieronder in hoeveel je per uur verdient. Dit wordt gebruikt om je WC-inkomsten te berekenen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
                ),
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
                    return 'Voer een uurloon in.';
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
                  minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
                ),
                child: const Text('Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}