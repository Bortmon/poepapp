// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/session_data.dart';
import '../utils/currency_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controllers worden nu binnen de dialogen beheerd of direct via AppState

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(currentValue.isEmpty ? 'Niet ingesteld' : currentValue, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withAlpha(180))),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Future<void> _editNicknameDialog(BuildContext context, AppState appState) async {
    final TextEditingController nicknameController = TextEditingController(text: appState.userName == "Anonieme Held" ? "" : appState.userName);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Nickname Aanpassen'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nicknameController,
              decoration: const InputDecoration(hintText: "Voer je nickname in"),
              maxLength: 20,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
                  return 'Minimaal 3 tekens.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Opslaan'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  appState.setUserName(nicknameController.text.trim());
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editStatusDialog(BuildContext context, AppState appState) async {
    final TextEditingController statusController = TextEditingController(text: appState.userStatus);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Troon Gedachten Aanpassen'),
          content: TextFormField(
            controller: statusController,
            decoration: const InputDecoration(hintText: "Deel je wijsheid..."),
            maxLength: 50,
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Opslaan'),
              onPressed: () {
                appState.setUserStatus(statusController.text.trim());
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editHourlyWageDialog(BuildContext context, AppState appState) async {
    final TextEditingController wageController = TextEditingController(
      text: appState.hourlyWage > 0 ? appState.hourlyWage.toStringAsFixed(2).replaceAll('.', ',') : '',
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Uurloon Aanpassen'),
          content: TextFormField(
            controller: wageController,
            decoration: const InputDecoration(hintText: "bijv. 15,50", prefixText: "€ "),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}'))],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Opslaan'),
              onPressed: () {
                final wage = double.tryParse(wageController.text.replaceAll(',', '.'));
                if (wage != null && wage > 0) {
                  appState.setHourlyWage(wage);
                } else {
                  appState.setHourlyWage(0.0); // Zet op 0 als input ongeldig of leeg is
                }
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndDeleteSession(BuildContext context, AppState appState, SessionData session) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sessie Verwijderen?'),
          content: Text('Weet je zeker dat je de sessie van ${DateFormat('dd-MM-yyyy HH:mm').format(session.startTime)} wilt verwijderen? Dit beïnvloedt je totalen, rang en prestaties.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Verwijderen'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await appState.deleteSession(session);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessie verwijderd!')),
      );
    }
  }

  Future<void> _confirmAndResetData(BuildContext context, AppState appState) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Profiel Verwijderen?'),
          content: const Text('Weet je zeker dat je alle opgeslagen gegevens (uurloon, nickname, status, sessiegeschiedenis en prestaties) wilt verwijderen? Je score op het leaderboard wordt ook gereset. Deze actie kan niet ongedaan worden gemaakt.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Verwijder Profiel'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await appState.resetAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alle profielgegevens zijn gereset!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  String _formatDurationSettings(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return "${hours}u ${twoDigits(minutes)}m";
    if (minutes > 0) return "${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    return "${twoDigits(seconds)}s";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);

    List<SessionData> sortedSessions = List.from(appState.sessionsHistory);
    sortedSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
      ),
      body: ListView( // Gebruik ListView voor scrollbare secties
        padding: const EdgeInsets.only(bottom: 20.0),
        children: <Widget>[
          _buildSectionHeader(context, 'Profiel'),
          _buildSettingsTile(
            context: context,
            icon: Icons.person_outline_rounded,
            title: 'Nickname',
            currentValue: appState.userName,
            onTap: () => _editNicknameDialog(context, appState),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Troon Gedachten',
            currentValue: appState.userStatus,
            onTap: () => _editStatusDialog(context, appState),
          ),

          _buildSectionHeader(context, 'Financiën'),
          _buildSettingsTile(
            context: context,
            icon: Icons.euro_symbol_rounded,
            title: 'Uurloon',
            currentValue: appState.hourlyWage > 0 ? formatCurrencyStandard(appState.hourlyWage) : 'Niet ingesteld',
            onTap: () => _editHourlyWageDialog(context, appState),
          ),

          _buildSectionHeader(context, 'Sessiebeheer'),
          if (sortedSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Nog geen sessies om te beheren.", style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ),
              ),
            )
          else
            ...sortedSessions.take(5).map((session) => Card( // Neem de eerste 5 (nieuwste)
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: Icon(Icons.history_rounded, color: theme.colorScheme.onSurface.withAlpha(150)),
                    title: Text(DateFormat('dd-MM-yyyy HH:mm').format(session.startTime)),
                    subtitle: Text('Duur: ${_formatDurationSettings(session.duration)} - Verdiend: ${formatCurrencyStandard(session.earnedAmount)}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                      onPressed: () => _confirmAndDeleteSession(context, appState, session),
                      tooltip: 'Verwijder sessie',
                    ),
                  ),
                )
            ).toList(),
          if (sortedSessions.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Toont de 5 meest recente sessies.", style: theme.textTheme.bodySmall),
            ),


          _buildSectionHeader(context, 'Account'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            color: theme.colorScheme.errorContainer.withAlpha(100), // Subtiele error kleur
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              title: Text('Profiel Verwijderen', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error)),
              subtitle: Text('Reset alle app gegevens en leaderboard score.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer.withAlpha(200))),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _confirmAndResetData(context, appState),
            ),
          ),

          const SizedBox(height: 40),
          Text(
            'Made by Bart Akkerman',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(150)
            ),
          ),
        ],
      ),
    );
  }
}