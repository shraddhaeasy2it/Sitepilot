import 'dart:math';

import 'package:ecoteam_app/services/otp_service.dart';
import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String apiResponse = "";
  bool isLoading = false;
  bool otpSent = false;
  String? generatedOtp; // Stores the OTP that was sent
  final _formKey = GlobalKey<FormState>();

  Future<void> sendOtpAndRenewalMessage() async {
    if (!_formKey.currentState!.validate()) return;

    String mobile = mobileController.text.trim();
    setState(() {
      isLoading = true;
      apiResponse = "";
    });

    try {
      // Generate OTP first
      generatedOtp = (100000 + Random().nextInt(900000)).toString();
      
      // Send the OTP via SMS
      String result = await OtpService.sendOtpWithRenewalMessage(
        mobileNumber: mobile,
        renewalDate: "15-Aug-2025",
        hostingCharge: "₹1500",
        hostingGst: "₹270",
        domainCharge: "₹800",
        total: "₹2570",
      );
      
      setState(() {
        apiResponse = "OTP sent successfully!";
        otpSent = true;
      });
    } catch (e) {
      setState(() {
        apiResponse = "Error: Failed to send OTP. Please try again.";
        generatedOtp = null;
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

    // Simple verification - compare with generated OTP
    if (otpController.text == generatedOtp) {
      setState(() {
        apiResponse = "OTP verified successfully!";
        isLoading = false;
      });
      // Here you would typically navigate to the next screen
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      setState(() {
        apiResponse = "Invalid OTP. Please try again.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Text(
              otpSent ? "Verify OTP" : "Enter your mobile number",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtitle based on current step
            Text(
              otpSent 
                ? "Enter the 6-digit code sent to ${mobileController.text}"
                : "We'll send you a verification code",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
      
            if (!otpSent) ...[
              // Phone number input (first step)
              TextFormField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  hintText: "91 9876543210",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (!RegExp(r'^[+0-9]{10,15}$').hasMatch(value)) {
                    return 'Enter valid mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
            ] else ...[
              // OTP input (second step)
              Text(
                "Enter OTP",
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: "123456",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              
              // Options to change number or resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () {
                      setState(() {
                        otpSent = false;
                        apiResponse = "";
                        otpController.clear();
                      });
                    },
                    child: Text(
                      "Change Number",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : sendOtpAndRenewalMessage,
                    child: Text(
                      "Resend OTP",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
      
            // Submit button (changes function based on step)
            ElevatedButton(
              onPressed: isLoading 
                  ? null 
                  : otpSent ? verifyOtp : sendOtpAndRenewalMessage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                backgroundColor: Color(0xFF6F88E2),
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      otpSent ? "Verify OTP" : "Send OTP",
                      style: const TextStyle(fontSize: 17,fontWeight: FontWeight.w700),
                      selectionColor: const Color(0xFF6F88E2),
                    
                      
                    ),
            ),
            const SizedBox(height: 24),
      
            // Response message area
            if (apiResponse.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: apiResponse.contains("Invalid") || 
                         apiResponse.contains("Error")
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  apiResponse,
                  style: TextStyle(
                    color: apiResponse.contains("Invalid") || 
                           apiResponse.contains("Error")
                        ? theme.colorScheme.error
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
      
            // Terms and conditions notice
            const SizedBox(height: 15),
            Text(
              "By continuing, you agree to our Terms of Service and Privacy Policy",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}