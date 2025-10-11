import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    this.selectedItemColor = const Color.fromARGB(255, 66, 98, 214),
    this.unselectedItemColor = const Color.fromARGB(255, 109, 109, 109),
    this.backgroundColor = Colors.white,
    this.labelFontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
         border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
       
      ),
      child: ClipRRect(
        
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
                (Set<WidgetState> states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? selectedItemColor : unselectedItemColor,
                    letterSpacing: 0.5,
                  );
                },
              ),
              indicatorShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: NavigationBar(
            height: 70,
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            backgroundColor: backgroundColor,
            elevation: 0,
            indicatorColor: Colors.white.withOpacity(0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 300),
            
            destinations: [
              _buildNavigationDestination(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
              _buildNavigationDestination(1, FontAwesomeIcons.screwdriverWrench, FontAwesomeIcons.screwdriverWrench, 'Material'),
              // _buildNavigationDestination(2, Icons.task_alt_outlined, Icons.task, 'Task'),
              _buildNavigationDestination(3, FontAwesomeIcons.tractor, FontAwesomeIcons.tractor, 'Machinary'),
              _buildNavigationDestination(4, FontAwesomeIcons.ellipsis, FontAwesomeIcons.ellipsis, 'More'),
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
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          
          // color: isSelected ? Colors.transparent : const Color.fromARGB(255, 146, 146, 146).withOpacity(0.1),
        ),
        child: Icon(
          icon, 
          color: unselectedItemColor, 
          size: 21,
        ),
      ),
      selectedIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: Icon(
          selectedIcon, 
          color: selectedItemColor, 
          size: 22,
        ),
      ),
      label: label,
    );
  }
}