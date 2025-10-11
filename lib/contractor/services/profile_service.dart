import 'package:share_plus/share_plus.dart';

class ProfileService {
  static Future<void> shareProfile({
    required String name,
    required String position,
    required String email,
    required String phone,
    required String department,
    required String projects,
    required String skills,
    required String experience,
  }) async {
    try {
      // Create shareable text
      final shareText = '''
🌟 Profile Share 🌟

Name: $name
Position: $position
Email: $email
Phone: $phone
Department: $department
Projects: $projects
Skills: $skills
Experience: $experience

Connect with me for professional opportunities!
''';

      // Share the profile
      await Share.share(
        shareText,
        subject: 'Check out $name\'s profile',
      );

    } catch (e) {
      throw Exception('Failed to share profile: $e');
    }
  }
}