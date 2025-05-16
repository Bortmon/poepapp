// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import 'leaderboard_screen.dart';
import 'achievements_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<AnimationController> _iconAnimationControllers;
  late List<Animation<double>> _iconAnimations;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    StatisticsScreen(),
    LeaderboardScreen(),
    AchievementsScreen(),
  ];

  static const List<IconData> _outlineIcons = [
    Icons.home_outlined,
    Icons.insights_outlined,
    Icons.leaderboard_outlined,
    Icons.military_tech_outlined,
  ];

  static const List<IconData> _filledIcons = [
    Icons.home_rounded,
    Icons.insights_rounded,
    Icons.leaderboard_rounded,
    Icons.military_tech_rounded,
  ];

  static const List<String> _labels = [
    'Home',
    'Statistieken',
    'Leaderboard',
    'Prestaties',
  ];


  @override
  void initState() {
    super.initState();
    _iconAnimationControllers = List.generate(
      _screens.length,
      (index) => AnimationController(duration: const Duration(milliseconds: 200), vsync: this),
    );
    _iconAnimations = _iconAnimationControllers
        .map((controller) => Tween<double>(begin: 1.0, end: 1.25).animate(
              CurvedAnimation(parent: controller, curve: Curves.elasticOut),
            ))
        .toList();
    _iconAnimationControllers[_selectedIndex].forward();
  }

  @override
  void dispose() {
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; 
    _iconAnimationControllers[_selectedIndex].reverse();
    setState(() {
      _selectedIndex = index;
    });
    _iconAnimationControllers[_selectedIndex].forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(_screens.length, (index) {
          return BottomNavigationBarItem(
            icon: ScaleTransition(
              scale: _iconAnimations[index],
              child: Icon(_selectedIndex == index ? _filledIcons[index] : _outlineIcons[index]),
            ),
            label: _labels[index],
          );
        }),
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withAlpha(180),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 8.0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        iconSize: 26,
      ),
    );
  }
}