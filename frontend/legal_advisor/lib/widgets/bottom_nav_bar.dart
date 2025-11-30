import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../pages/language_page.dart';

typedef OnTabSelected = void Function(int index);

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final OnTabSelected onTabSelected;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: lang.getString('home') ?? 'Home',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.language,
            label: lang.getString('language') ?? 'Language',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.chat_bubble_outline,
            label: lang.getString('chatbot') ?? 'Chatbot',
            index: 2,
          ),
          _buildNavItem(
            icon: Icons.settings,
            label: lang.getString('settings') ?? 'Settings',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected ? Colors.orange : Colors.white;

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          if (index == 1) {
            // Show language selection modal bottom sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const LanguagePage(),
            );
          } else {
            onTabSelected(index);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
