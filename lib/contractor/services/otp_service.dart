import 'dart:math';
import 'package:http/http.dart' as http;

class OtpService {
  static const String templateId = "1707166808193932352";
  static const String routeName = "TRANS";

  // Generate random OTP
  static String generateOtp() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  // Send OTP with message
  static Future<String> sendOtpWithRenewalMessage({
    required String mobileNumber,
    required String otp,
    required String renewalDate,
    required String hostingCharge,
    required String hostingGst,
    required String domainCharge,
    required String total,
  }) async {
    String message = Uri.encodeComponent(
      "Hi, Good Afternoon, $otp renewal is on $renewalDate. "
      "Charges are as follows: Website hosting renewal for 1 year $hostingCharge "
      "+ GST = $hostingGst, Domain name for 1 year $domainCharge, "
      "Total - $total "
      "- Team Easy2IT"
    );

    String url =
        "https://sms.webtextsolution.com/sms-panel/api/http/index.php"
        "?username=EASY2IT"
        "&apikey=7B4AD-96606"
        "&apirequest=Text"
        "&sender=EASYTT"
        "&mobile=$mobileNumber"
        "&message=$message"
        "&route=$routeName"
        "&TemplateID=$templateId"
        "&format=JSON";

    final response = await http.get(Uri.parse(url));
    return response.body;
  }
}
