// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    required this.rankCardGradientStart,
    required this.rankCardGradientEnd,
  });

  final Color? moneyColor;
  final Color? rankCardGradientStart;
  final Color? rankCardGradientEnd;


  @override
  MyThemeColors copyWith({Color? moneyColor, Color? rankCardGradientStart, Color? rankCardGradientEnd})
  {
    return MyThemeColors(
      moneyColor: moneyColor ?? this.moneyColor,
      rankCardGradientStart: rankCardGradientStart ?? this.rankCardGradientStart,
      rankCardGradientEnd: rankCardGradientEnd ?? this.rankCardGradientEnd,
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
      rankCardGradientStart: Color.lerp(rankCardGradientStart, other.rankCardGradientStart, t),
      rankCardGradientEnd: Color.lerp(rankCardGradientEnd, other.rankCardGradientEnd, t),
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
    const Color primaryAccentColor = Color(0xFF4A90E2);
    const Color scaffoldBackgroundColor = Color(0xFF212121); 
    const Color cardBackgroundColor = Color(0xFF2C2C2C); 
    const Color mainTextColor = Colors.white;
    const Color secondaryTextColor = Color(0xFFE0E0E0); 
    const Color rankGradientStart = Color(0xFF34C759); 
    const Color rankGradientEnd = Color(0xFF28A745); 
    const Color moneyDisplayColor = Color(0xFF34C759); 

    ColorScheme appColorScheme = ColorScheme.fromSeed(
      seedColor: primaryAccentColor,
      brightness: Brightness.dark,
      background: scaffoldBackgroundColor,
      surface: cardBackgroundColor,
      onBackground: mainTextColor,
      onSurface: mainTextColor,
      primary: primaryAccentColor,
      onPrimary: Colors.white,
      secondary: rankGradientStart, 
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WC Geld Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', 
        colorScheme: appColorScheme,
        scaffoldBackgroundColor: appColorScheme.background,

        appBarTheme: AppBarTheme(
          backgroundColor: appColorScheme.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: appColorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold, 
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: appColorScheme.primary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColorScheme.primary,
            foregroundColor: appColorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), 
            ),
            elevation: 3, 
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                foregroundColor: appColorScheme.primary,
                side: BorderSide(color: appColorScheme.primary.withAlpha(150)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                ),
            ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: appColorScheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14),
          )
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: appColorScheme.surface.withAlpha(180), 
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0), 
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: appColorScheme.primary, width: 1.5),
          ),
          labelStyle: TextStyle(color: secondaryTextColor.withAlpha(200), fontFamily: 'Inter'),
          hintStyle: TextStyle(color: secondaryTextColor.withAlpha(150), fontFamily: 'Inter'),
          prefixIconColor: appColorScheme.primary.withAlpha(200),
        ),
        cardTheme: CardTheme(
          elevation: 1, 
          color: cardBackgroundColor, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), 
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0), 
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 32),
          displayMedium: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 28),
          displaySmall: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 24),
          headlineLarge: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 22),
          headlineMedium: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.bold, fontSize: 20),
          headlineSmall: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.w600, fontSize: 18),
          titleLarge: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.w600, fontSize: 16),
          titleMedium: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontWeight: FontWeight.w500, fontSize: 14),
          titleSmall: TextStyle(fontFamily: 'Inter', color: secondaryTextColor, fontWeight: FontWeight.w500, fontSize: 12),
          bodyLarge: TextStyle(fontFamily: 'Inter', color: mainTextColor, fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(fontFamily: 'Inter', color: secondaryTextColor, fontSize: 14, height: 1.4),
          bodySmall: TextStyle(fontFamily: 'Inter', color: secondaryTextColor.withAlpha(200), fontSize: 12, height: 1.3),
          labelLarge: TextStyle(fontFamily: 'Inter', color: appColorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: IconThemeData(
          color: secondaryTextColor.withAlpha(220),
        ),
        dividerTheme: DividerThemeData(
          color: mainTextColor.withAlpha(50),
          thickness: 0.5,
        ),
        extensions: <ThemeExtension<dynamic>>[
          MyThemeColors(
            moneyColor: moneyDisplayColor,
            rankCardGradientStart: rankGradientStart,
            rankCardGradientEnd: rankGradientEnd,
          ),
        ],
      ),
      home: const SplashScreen(),
    );
  }
}