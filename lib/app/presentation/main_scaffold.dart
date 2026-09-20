import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.gray800 : AppColors.gray200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary500,
          unselectedItemColor: isDark ? AppColors.gray500 : AppColors.gray400,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: loc.tr('nav_home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long_rounded),
              label: loc.tr('nav_transactions'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pie_chart_outline_rounded),
              activeIcon: const Icon(Icons.pie_chart_rounded),
              label: loc.tr('nav_report'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: const Icon(Icons.person_rounded),
              label: loc.tr('nav_account'),
            ),
          ],
        ),
      ),
    );
  }
}
