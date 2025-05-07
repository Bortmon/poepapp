// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('nl_NL', null);

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    const Color primaryColor = Color(0xFF8A3FFC);
    const Color cardBackgroundColor = Color(0xFF1E1E1E);
    const Color textColor = Color(0xFFE0E0E0);
    const Color moneyGreen = Color(0xFF00C853);
    const Color scaffoldBgColor = Color(0xFF121212);

    return MaterialApp(
      title: 'WC Geld Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: scaffoldBgColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: primaryColor,
          surface: cardBackgroundColor,
          background: scaffoldBgColor,
          error: Colors.redAccent,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textColor,
          onBackground: textColor,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cardBackgroundColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          iconTheme: IconThemeData(color: primaryColor),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          )
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBackgroundColor.withAlpha((0.5 * 255).round()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          labelStyle: TextStyle(color: textColor.withAlpha((0.7 * 255).round())),
          hintStyle: TextStyle(color: textColor.withAlpha((0.5 * 255).round())),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          color: cardBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xE6E0E0E0)),
          bodyMedium: TextStyle(color: Color(0xCCE0E0E0)),
          labelLarge: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(
          color: textColor.withAlpha((0.8 * 255).round()),
        ),
        dividerTheme: DividerThemeData(
          color: textColor.withAlpha((0.2 * 255).round()),
          thickness: 1,
        ),
        extensions: const <ThemeExtension<dynamic>>[
          MyThemeColors(moneyColor: moneyGreen),
        ],
      ),
      home: const HomeScreen(),
    );
  }
}