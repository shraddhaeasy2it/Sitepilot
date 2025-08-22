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
    this.selectedItemColor = const Color.fromARGB(255, 66, 98, 214),
    this.unselectedItemColor = const Color.fromARGB(255, 109, 109, 109),
    this.backgroundColor = Colors.white,
    this.labelFontSize = 12.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
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
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 300),
            indicatorColor: selectedItemColor.withOpacity(0.15),
            surfaceTintColor: Colors.transparent,
            destinations: [
              _buildNavigationDestination(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
              _buildNavigationDestination(1, Icons.people_outline, Icons.people, 'Worker'),
              _buildNavigationDestination(2, Icons.task_alt_outlined, Icons.task, 'Task'),
              _buildNavigationDestination(3, Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance'),
              _buildNavigationDestination(4, Icons.more_horiz_outlined, Icons.more_horiz, 'More'),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.transparent : const Color.fromARGB(255, 146, 146, 146).withOpacity(0.1),
        ),
        child: Icon(
          icon, 
          color: unselectedItemColor, 
          size: 24,
        ),
      ),
      selectedIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // decoration: BoxDecoration(
        //   borderRadius: BorderRadius.circular(20), // Pill shape
        //   color: selectedItemColor.withOpacity(0.15),
        // ),
        child: Icon(
          selectedIcon, 
          color: selectedItemColor, 
          size: 24,
        ),
      ),
      label: label,
    );
  }
}
// import 'package:flutter/material.dart';

// class CustomBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//   final Color selectedItemColor;
//   final Color unselectedItemColor;
//   final Color backgroundColor;
//   final double labelFontSize;

//   const CustomBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     this.selectedItemColor = const Color(0xFF4a63c0),
//     this.unselectedItemColor = const Color(0xFF9E9E9E),
//     this.backgroundColor = Colors.white,
//     this.labelFontSize = 12.0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 20,
//             spreadRadius: 2,
//             offset: const Offset(0, -5),
//           ),
//         ],
//         border: Border(
//           top: BorderSide(
//             color: Colors.grey.withOpacity(0.2),
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: NavigationBar(
//         height: 70,
//         selectedIndex: currentIndex,
//         onDestinationSelected: onTap,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
//         animationDuration: const Duration(milliseconds: 400),
//         indicatorShape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
//         ),
//         indicatorColor: selectedItemColor.withOpacity(0.15),
//         //surfaceTintColor: Colors.transparent,
//         destinations: [
//           _buildNavigationDestination(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
//           _buildNavigationDestination(1, Icons.people_outline, Icons.people, 'Worker'),
//           _buildNavigationDestination(2, Icons.task_outlined, Icons.task, 'Task'),
//           _buildNavigationDestination(3, Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance'),
//           _buildNavigationDestination(4, Icons.more_horiz_outlined, Icons.more_horiz, 'More'),
//         ],
//       ),
//     );
//   }

//   NavigationDestination _buildNavigationDestination(
//     int index, 
//     IconData icon, 
//     IconData selectedIcon, 
//     String label,
//   ) {
//     final isSelected = currentIndex == index;
//     return NavigationDestination(
//       icon: Container(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon, 
//               color: unselectedItemColor, 
//               size: 24,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: labelFontSize,
//                 fontWeight: FontWeight.w500,
//                 color: unselectedItemColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//       selectedIcon: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         // decoration: BoxDecoration(
//         //   borderRadius: BorderRadius.circular(12),
//         //   color: selectedItemColor.withOpacity(0.1),
//         // ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               selectedIcon, 
//               color: selectedItemColor, 
//               size: 26,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: labelFontSize,
//                 fontWeight: FontWeight.w600,
//                 color: selectedItemColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//       label: '',
//     );
//   }
// }