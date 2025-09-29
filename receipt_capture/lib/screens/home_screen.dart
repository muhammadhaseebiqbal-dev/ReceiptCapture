import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/receipt/bloc/receipt_bloc.dart';
import '../features/receipt/bloc/receipt_event.dart';
import '../features/receipt/bloc/receipt_state.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/floating_navigation.dart';
import 'receipt_list_screen.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    ReceiptListScreen(
      onNavigateToCamera: () => _onItemTapped(1),
    ),
    const CameraScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: IndexedStack(index: _selectedIndex, children: _screens),
      ),
      bottomNavigationBar: FloatingNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          FloatingNavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Receipts',
          ),
          FloatingNavItem(
            icon: Icons.camera_alt_outlined,
            label: 'Capture',
          ),
          FloatingNavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
