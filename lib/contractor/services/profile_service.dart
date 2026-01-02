import 'package:share_plus/share_plus.dart';

class ProfileService {
  static Future<void> shareProfile({
    required String name,
    required String email,
   
  }) async {
    try {
      // Create shareable text
      final shareText = '''
🌟 Profile Share 🌟

Name: $name
Email: $email

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