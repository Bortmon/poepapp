// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
// import 'screens/home_screen.dart'; // Niet meer direct nodig hier
import 'screens/nickname_setup_screen.dart';
import 'screens/main_navigation_screen.dart'; // Importeer het nieuwe scherm

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('nl_NL', null);

  final prefs = await SharedPreferences.getInstance();
  final bool hasNickname = prefs.getString('userName') != null && prefs.getString('userName')!.isNotEmpty;

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MyApp(hasNickname: hasNickname),
    ),
  );
}

@immutable
class MyThemeColors extends ThemeExtension<MyThemeColors>
{
  const MyThemeColors({
    required this.moneyColor,
  });

  final Color? moneyColor;

  @override
  MyThemeColors copyWith({Color? moneyColor})
  {
    return MyThemeColors(
      moneyColor: moneyColor ?? this.moneyColor,
    );
  }

  @override
  MyThemeColors lerp(ThemeExtension<MyThemeColors>? other, double t)
  {
    if (other is! MyThemeColors)
    {
      return this;
    }
    return MyThemeColors(
      moneyColor: Color.lerp(moneyColor, other.moneyColor, t),
    );
  }

  static MyThemeColors? of(BuildContext context)
  {
    return Theme.of(context).extension<MyThemeColors>();
  }
}

class MyApp extends StatelessWidget
{
  final bool hasNickname;
  const MyApp({super.key, required this.hasNickname});

  @override
  Widget build(BuildContext context)
  {
    const Color seedColor = Color(0xFF8A3FFC);
    const Color cardBackgroundColor = Color(0xFF1E1E1E);
    const Color scaffoldBackgroundColor = Color(0xFF121212);
    const Color textColorOnDark = Color(0xFFE0E0E0);
    const Color moneyGreen = Color(0xFF00C853);

    ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      background: scaffoldBackgroundColor,
      surface: cardBackgroundColor,
      onBackground: textColorOnDark,
      onSurface: textColorOnDark,
      primary: seedColor,
    );

    return MaterialApp(
      title: 'WC Geld Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkColorScheme.background,
        primaryColor: darkColorScheme.primary,

        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: darkColorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: IconThemeData(color: darkColorScheme.primary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: darkColorScheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          )
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surface.withAlpha((0.7 * 255).round()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
          ),
          labelStyle: TextStyle(color: darkColorScheme.onSurface.withAlpha((0.7 * 255).round())),
          hintStyle: TextStyle(color: darkColorScheme.onSurface.withAlpha((0.5 * 255).round())),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          color: darkColorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: darkColorScheme.onSurface.withAlpha((0.9 * 255).round())),
          bodyMedium: TextStyle(color: darkColorScheme.onSurface.withAlpha((0.8 * 255).round())),
          bodySmall: TextStyle(color: darkColorScheme.onSurface.withAlpha((0.7 * 255).round())),
          labelLarge: TextStyle(color: darkColorScheme.primary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(
          color: darkColorScheme.onSurface.withAlpha((0.8 * 255).round()),
        ),
        dividerTheme: DividerThemeData(
          color: darkColorScheme.onSurface.withAlpha((0.2 * 255).round()),
          thickness: 1,
        ),
        extensions: const <ThemeExtension<dynamic>>[
          MyThemeColors(moneyColor: moneyGreen),
        ],
      ),
      home: hasNickname ? const MainNavigationScreen() : const NicknameSetupScreen(), // AANGEPAST
    );
  }
}