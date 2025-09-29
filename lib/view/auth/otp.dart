import 'package:ecoteam_app/services/otp_service.dart';
import 'package:ecoteam_app/view/contractor_dashboard/home_page.dart';
import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool otpSent = false;
  bool isLoading = false;
  String apiResponse = "";
  String? generatedOtp;

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    String mobile = mobileController.text.trim();
    setState(() {
      isLoading = true;
      apiResponse = "";
    });

    try {
      generatedOtp = OtpService.generateOtp();

      await OtpService.sendOtpWithRenewalMessage(
        mobileNumber: mobile,
        otp: generatedOtp!,
        renewalDate: "15-Aug-2025",
        hostingCharge: "₹1500",
        hostingGst: "₹270",
        domainCharge: "₹800",
        total: "₹2570",
      );

      setState(() {
        otpSent = true;
        apiResponse = "OTP sent successfully!";
      });
    } catch (e) {
      setState(() {
        apiResponse = "Error: Failed to send OTP";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

 void verifyOtp() async {
  if (otpController.text.isEmpty || otpController.text.length != 6) {
    setState(() {
      apiResponse = "Please enter a valid 6-digit OTP";
    });
    return;
  }

  setState(() {
    isLoading = true;
  });

  if (otpController.text == generatedOtp) {
    setState(() {
      apiResponse = "OTP verified successfully!";
      isLoading = false;
    });

    // ✅ Navigate to Home Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePagescreen()),
    );
  } else {
    setState(() {
      apiResponse = "Invalid OTP. Please try again.";
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (!otpSent) ...[
                TextFormField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter mobile number";
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return "Enter valid 10-digit number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : sendOtp,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Send OTP"),
                ),
              ] else ...[
                TextFormField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : verifyOtp,
                  child: const Text("Verify OTP"),
                ),
              ],
              const SizedBox(height: 20),
              Text(apiResponse),
            ],
          ),
        ),
      ),
    );
  }
}
