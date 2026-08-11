import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import 'home_screen.dart';
import 'stok_screen.dart';
import 'ai_screen.dart';
import 'profil_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const StokScreen(),
    const AIScreen(),
    const ProfilScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) return; // FAB Mic spot
    ref.read(tabIndexProvider.notifier).state = index > 2 ? index - 1 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabIndexProvider);
    final displayIndex = currentIndex >= 2 ? currentIndex + 1 : currentIndex;

    return Scaffold(
      body: _screens[currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/mic');
        },
        backgroundColor: AppTheme.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        color: Colors.white,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: const Color(0xFF9E9E9E),
          backgroundColor: Colors.white,
          elevation: 0, // Set to 0 since BottomAppBar handles elevation
          currentIndex: displayIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: 'Stok',
            ),
            BottomNavigationBarItem(
              icon: SizedBox(height: 24),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_rounded),
              label: 'AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
