// import 'package:ecoteam_app/view/auth/login_selector.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lottie/lottie.dart'; // <-- Added for JSON animations

// class LandingPages extends StatefulWidget {
//   @override
//   _LandingPagesState createState() => _LandingPagesState();
// }

// class _LandingPagesState extends State<LandingPages>
//     with TickerProviderStateMixin {
//   final PageController _controller = PageController();
//   int _currentPage = 0;
//   int _previousPage = 0;
//   // late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late AnimationController _scaleController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _scaleAnimation;

//   final List<Map<String, String>> pages = [
//     {
//       "title": "Manage Materials",
//       "subtitle":
//           "Track your construction materials easily and reduce wastage with smart inventory management.",
//       "image": "assets/landing1animation.json",
//     },
//     {
//       "title": "Track Machinery",
//       "subtitle":
//           "Keep an eye on your machinery expenses and rental status in real-time.",
//       "image": "assets/constrct2.jpg",
//     },
//     {
//       "title": "Manage Manpower",
//       "subtitle":
//           "Monitor manpower attendance and allocate workers efficiently across projects.",
//       "image": "assets/constrct3.jpg",
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     // _initializeAnimations();
//   }

//   // void _initializeAnimations() {
//   //   _fadeController = AnimationController(
//   //     duration: const Duration(milliseconds: 1400),
//   //     vsync: this,
//   //   );

//   //   _slideController = AnimationController(
//   //     duration: const Duration(milliseconds: 1400),
//   //     vsync: this,
//   //   );

//   //   _scaleController = AnimationController(
//   //     duration: const Duration(milliseconds: 1400),
//   //     vsync: this,
//   //   );

//   //   _fadeAnimation = CurvedAnimation(
//   //     parent: _fadeController,
//   //     curve: Curves.easeInOutSine,
//   //   );

//   //   _slideAnimation = Tween<Offset>(
//   //     begin: const Offset(0, 0.01),
//   //     end: Offset.zero,
//   //   ).animate(
//   //     CurvedAnimation(parent: _slideController, curve: Curves.easeOutSine),
//   //   );

//   //   _scaleAnimation = Tween<double>(
//   //     begin: 0.97,
//   //     end: 1.0,
//   //   ).animate(
//   //     CurvedAnimation(parent: _scaleController, curve: Curves.easeOutSine),
//   //   );

//   //   _fadeController.forward();
//   //   _slideController.forward();
//   //   _scaleController.forward();
//   // }

//   void _onSkip() {
//     HapticFeedback.lightImpact();
//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) =>
//             LoginSelectorPage(),
//         transitionsBuilder: (context, animation, secondaryAnimation, child) {
//           return FadeTransition(opacity: animation, child: child);
//         },
//         transitionDuration: const Duration(milliseconds: 600),
//       ),
//     );
//   }

//   void _onNext() {
//     HapticFeedback.selectionClick();
//     if (_currentPage < pages.length - 1) {
//       _controller.nextPage(
//         duration: const Duration(milliseconds: 800),
//         curve: Curves.easeInOutCubic,
//       );
//     } else {
//       _onSkip();
//     }
//   }

//   Widget _buildDots() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(
//         pages.length,
//         (index) => AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           margin: const EdgeInsets.symmetric(horizontal: 4),
//           height: 8,
//           width: _currentPage == index ? 24 : 8,
//           decoration: BoxDecoration(
//             color: _currentPage == index
//                 ? Colors.white
//                 : Colors.white.withOpacity(0.3),
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildResponsiveImage(String imageUrl, BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;

//     double imageHeight;
//     if (screenHeight < 600) {
//       imageHeight = screenHeight * 0.25;
//     } else if (screenHeight < 800) {
//       imageHeight = screenHeight * 0.35;
//     } else {
//       imageHeight = screenHeight * 0.4;
//     }

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 800),
//       curve: Curves.easeInOutCubic,
//       height: imageHeight,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 15,
//             spreadRadius: 1,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(20),
//         child: imageUrl.endsWith(".json")
//             ? Lottie.asset(
//                 imageUrl,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return _buildErrorWidget();
//                 },
//               )
//             : Image.asset(
//                 imageUrl,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return _buildErrorWidget();
//                 },
//               ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() {
//     return Container(
//       color: Colors.white.withOpacity(0.1),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             Icon(Icons.image_not_supported, color: Colors.white70, size: 48),
//             SizedBox(height: 8),
//             Text('Image not available',
//                 style: TextStyle(color: Colors.white70)),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     // _fadeController.dispose();
//     _slideController.dispose();
//     _scaleController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isSmallScreen = screenHeight < 600;

//     return Scaffold(
//       backgroundColor: const Color(0xFF6f88e2),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: AnimatedOpacity(
//           opacity: 1.0,
//           duration: const Duration(milliseconds: 800),
//           child: Text(
//             "Welcome",
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: isSmallScreen ? 20 : 24,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: _onSkip,
//             child: Text(
//               "Skip",
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.9),
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF6f88e2), Color(0xFF5a73d1), Color(0xFF4a63c0)],
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: PageView.builder(
//                 controller: _controller,
//                 itemCount: pages.length,
//                 onPageChanged: (int page) {
//                   setState(() {
//                     _previousPage = _currentPage;
//                     _currentPage = page;
//                   });

//                   if (_currentPage > _previousPage) {
//                     // _fadeController.reset();
//                     _slideController.reset();
//                     _scaleController.reset();

//                     Future.delayed(const Duration(milliseconds: 10), () {
//                       // _fadeController.forward();
//                     });
//                     Future.delayed(const Duration(milliseconds: 100), () {
//                       _slideController.forward();
//                     });
//                     _scaleController.forward();
//                   } else {
//                     // _fadeController.value = 1.0;
//                     _slideController.value = 1.0;
//                     _scaleController.value = 1.0;
//                   }
//                 },
//                 itemBuilder: (_, index) {
//                   final page = pages[index];
//                   return Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: screenWidth * 0.06,
//                       vertical: isSmallScreen ? 16 : 24,
//                     ),
//                     child: Column(
//                       children: [
//                         const Spacer(flex: 1),
//                         AnimatedBuilder(
//                           animation: Listenable.merge([
//                             // _fadeController,
//                             _slideController,
//                             _scaleController
//                           ]),
//                           builder: (context, child) {
//                             return Opacity(
//                               opacity: _fadeAnimation.value,
//                               child: Transform.translate(
//                                 offset: _slideAnimation.value * 30,
//                                 child: Transform.scale(
//                                   scale: _scaleAnimation.value,
//                                   child: child,
//                                 ),
//                               ),
//                             );
//                           },
//                           child: _buildResponsiveImage(
//                             page["image"]!,
//                             context,
//                           ),
//                         ),
//                         SizedBox(height: isSmallScreen ? 20 : 32),
//                         AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 900),
//                           child: Text(
//                             page["title"]!,
//                             key: ValueKey<int>(index),
//                             style: TextStyle(
//                               fontSize: isSmallScreen ? 24 : 28,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                               letterSpacing: 0.5,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                         SizedBox(height: isSmallScreen ? 12 : 16),
//                         AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 600),
//                           child: Text(
//                             page["subtitle"]!,
//                             key: ValueKey<int>(index),
//                             style: TextStyle(
//                               fontSize: isSmallScreen ? 14 : 16,
//                               color: Colors.white.withOpacity(0.8),
//                               height: 1.5,
//                               letterSpacing: 0.2,
//                             ),
//                             textAlign: TextAlign.center,
//                             maxLines: 3,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         const Spacer(flex: 2),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
//               child: _buildDots(),
//             ),
//             Padding(
//               padding: EdgeInsets.symmetric(
//                 horizontal: screenWidth * 0.08,
//                 vertical: isSmallScreen ? 8 : 16,
//               ),
//               child: ElevatedButton(
//                 onPressed: _onNext,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   foregroundColor: const Color(0xFF6f88e2),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 child: Text(
//                   _currentPage == pages.length - 1
//                       ? "Get Started"
//                       : "Next",
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 16 : 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:ecoteam_app/view/auth/login_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class LandingPages extends StatefulWidget {
  const LandingPages({super.key});

  @override
  _LandingPagesState createState() => _LandingPagesState();
}

class _LandingPagesState extends State<LandingPages> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Manage ManPower",
      "subtitle":
           "Monitor manpower attendance and allocate workers efficiently across projects.",
      "image": "assets/landing1.json",
    },
    {
      "title": "Manage Materials",
      "subtitle":
          "Track your construction materials easily and reduce wastage with smart inventory management.",
      "image": "assets/landing2.json",
    },
    {
      "title": "Track Machinery",
      "subtitle":
          "Keep an eye on your machinery expenses and rental status in real-time.",
      "image": "assets/landing3.json",
    },
  ];

  void _onSkip() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LoginSelectorPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _onNext() {
    HapticFeedback.selectionClick();
    if (_currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _onSkip();
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10,
          width: _currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveImage(String imageUrl, BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Dynamic sizes based on screen height
    double imgHeight = screenHeight * 0.42; // default ~42% of screen height
    double imgWidth = screenWidth * 0.85;

    if (screenHeight < 600) {
      imgHeight = screenHeight * 0.30; // smaller screens
    } else if (screenHeight < 800) {
      imgHeight = screenHeight * 0.38;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: imageUrl.endsWith(".json")
          ? Center(
              child: Lottie.asset(
                imageUrl,
                height: imgHeight,
                width: imgWidth,
                fit: BoxFit.contain,
              ),
            )
          : Lottie.asset(
              imageUrl,
              height: imgHeight,
              width: imgWidth,
              fit: BoxFit.contain,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF6f88e2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Welcome",
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: Text(
              "Skip",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6f88e2), Color(0xFF5a73d1), Color(0xFF4a63c0)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (_, index) {
                  final page = pages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: isSmallScreen ? 16 : 24,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 1),
                        _buildResponsiveImage(page["image"]!, context),
                        SizedBox(height: isSmallScreen ? 12 : 20), // reduced gap
                        Text(
                          page["title"]!,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 14),
                        Text(
                          page["subtitle"]!,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
              child: _buildDots(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: isSmallScreen ? 8 : 16,
              ),
              child: ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6f88e2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _currentPage == pages.length - 1 ? "Get Started" : "Next",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}