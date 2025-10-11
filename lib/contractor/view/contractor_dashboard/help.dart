import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  Future<void> _callSupport() async {
    final Uri uri = Uri(scheme: 'tel', path: "+919876543210");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      throw Exception('Could not launch $uri');
    }
  }

  Future<void> _emailSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@yourcompany.com',
      queryParameters: {
        'subject': 'App Support',
        'body': 'Hello, I need help with...',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch email app.');
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
      "https://wa.me/919876543210?text=Hello, I need help with...",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      debugPrint('Could not launch WhatsApp.');
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Send Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Your feedback here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle feedback submission
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Feedback submitted successfully!'),
                          ),
                        );
                      },
                      child: Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Help & Support',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 22,
              ),
            ),
          ],
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4a63c0),
                  Color(0xFF3a53b0),
                  Color(0xFF2a43a0),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: HelpSearchDelegate());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Help Cards
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quick Help",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHelpCard(
                        icon: Icons.video_library,
                        title: "Video Guides",
                        color: Colors.blue,
                        onTap: () {
                          // Navigate to video guides
                        },
                      ),
                      SizedBox(width: 12),
                      _buildHelpCard(
                        icon: Icons.article,
                        title: "User Manual",
                        color: Colors.green,
                        onTap: () {
                          // Open user manual
                        },
                      ),
                      SizedBox(width: 12),
                      _buildHelpCard(
                        icon: Icons.bug_report,
                        title: "Report Issue",
                        color: Colors.red,
                        onTap: () => _showFeedbackDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // FAQ Section
                Row(
                  children: [
                    Text(
                      "Frequently Asked Questions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                const SizedBox(height: 12),

                ExpansionTile(
                  title: const Text("How do I mark attendance?"),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Go to the Attendance tab, select the site, and tap on the worker's name to mark present or absent.",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text("How can I download reports?"),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Navigate to the Attendance screen, tap the download icon on top-right, and choose your export format.",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text("Can I use the app offline?"),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        "Yes, you can mark attendance offline. Data will sync automatically when internet is available.",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Contact Support Section
                Text(
                  "Contact Support",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        title: const Text("Call Us"),
                        subtitle: const Text("+91 98765 43210"),
                        trailing: Icon(Icons.chevron_right),
                        onTap: _callSupport,
                      ),
                      Divider(height: 1, indent: 72),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFFF97316),
                          ),
                        ),
                        title: const Text("Email Us"),
                        subtitle: const Text("support@yourcompany.com"),
                        trailing: Icon(Icons.chevron_right),
                        onTap: _emailSupport,
                      ),
                      Divider(height: 1, indent: 72),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Color(0xFF25D366), // WhatsApp green
                            size: 30,
                          ),
                        ),
                        title: const Text("WhatsApp"),
                        subtitle: const Text("+91 98765 43210"),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openWhatsApp,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // App Information
                Text(
                  "App Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 12),
                            Text(
                              "Version",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Spacer(),
                            Text("1.2.3", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.update, color: Colors.grey),
                            SizedBox(width: 12),
                            Text(
                              "Last Updated",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Spacer(),
                            Text(
                              "May 15, 2023",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.security, color: Colors.grey),
                            SizedBox(width: 12),
                            Text(
                              "Privacy Policy",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Spacer(),
                            Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class HelpSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implement search results
    return Center(child: Text('Search results for: $query'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Implement search suggestions
    return Center(child: Text('Search for help articles'));
  }
}
