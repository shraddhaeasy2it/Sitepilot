import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final Color backgroundColor;
  final double labelFontSize;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.selectedItemColor = const Color.fromARGB(255, 26, 17, 151),
    this.unselectedItemColor =const Color.fromARGB(255, 49, 49, 49),
    this.backgroundColor = const Color.fromARGB(255, 196, 197, 196),
    this.labelFontSize = 14.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 94, 92, 92).withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (Set<WidgetState> states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w900,
                    color: isSelected ? selectedItemColor : unselectedItemColor,
                  );
                },
              ),
              indicatorShape: const CircleBorder(),
            ),
          ),
          child: NavigationBar(
            height: 72,
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: backgroundColor,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 300),
            indicatorColor: selectedItemColor.withValues(alpha: 0.2),
            surfaceTintColor: Colors.transparent,
            destinations: [
              _buildNavigationDestination(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
              _buildNavigationDestination(1, Icons.people_outline, Icons.people, 'Worker'),
              _buildNavigationDestination(2, Icons.task_alt_outlined, Icons.task, 'Task'),
              _buildNavigationDestination(4, Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance'),
              _buildNavigationDestination(5, Icons.more_horiz_outlined, Icons.more_horiz, 'More'),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavigationDestination(
    int index, 
    IconData icon, 
    IconData selectedIcon, 
    String label,
  ) {
    final isSelected = currentIndex == index;
    return NavigationDestination(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? selectedItemColor.withValues(alpha: 0.1) : const Color.fromARGB(235, 236, 236, 236),
        ),
        child: Icon(icon, color: unselectedItemColor, size: 26),
      ),
      selectedIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color.fromARGB(255, 150, 150, 252),
        ),
        child: Icon(selectedIcon, color: selectedItemColor, size: 28),
      ),
      label: label,
    );
  }
}