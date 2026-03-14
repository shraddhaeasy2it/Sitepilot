
import 'package:ecoteam_app/contractor/view/auth/login_selector.dart';
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