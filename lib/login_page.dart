import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'pages/otp_page.dart';
import 'worker_pages/worker_login_page.dart';
import 'l10n/app_localizations.dart';
// LocaleProvider

import 'locale_provider.dart'; // CORRECTED: Import from its own file

class LoginPage extends StatefulWidget {
  // ... rest of your LoginPage code is perfect and does not need changes.
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    String phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enter_phone_number_message)));
      return;
    } else if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enter_valid_phone)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedPhone = "+91$phone";

      if (kIsWeb) {
        final verifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha',
          size: RecaptchaVerifierSize.compact,
          theme: RecaptchaVerifierTheme.light,
        );

        await _auth.signInWithPhoneNumber(formattedPhone, verifier).then((
          confirmationResult,
        ) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpPage(
                phoneNumber: formattedPhone,
                verificationId: confirmationResult.verificationId,
              ),
            ),
          );
        });
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${l10n.verification_failed}: ${e.message}"),
              ),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpPage(
                  phoneNumber: formattedPhone,
                  verificationId: verificationId,
                ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${l10n.error_message}: $e")));
    }
  }

  void _showLanguageDialog() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.select_language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                // Always show "English" in English
                title: const Text('English'),
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                // Always show "हिन्दी" in Hindi
                title: const Text('हिन्दी'),
                onTap: () {
                  localeProvider.setLocale(const Locale('hi'));
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('ᱥᱟᱱᱛᱟᱲᱤ'),
                onTap: () {
                  localeProvider.setLocale(const Locale('sat'));
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const mainBlue = Color(0xFF1746D1);
    final l10n = AppLocalizations.of(context)!;

    final currentLocale =
        Provider.of<LocaleProvider>(context).locale?.languageCode ?? 'en';

    // Adjust font sizes for Santali (to avoid overflow)
    double titleFontSize = currentLocale == 'sat' ? 20.sp : 24.sp;
    double subtitleFontSize = currentLocale == 'sat' ? 14.sp : 15.sp;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // <-- Important for keyboard scroll
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight -
                              120.h, // leave space for bottom
                        ),
                        child: IntrinsicHeight(
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.all(8.w),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.language,
                                      size: 40.sp,
                                      color: mainBlue,
                                    ),
                                    onPressed: _showLanguageDialog,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: 50.h),
                                  CircleAvatar(
                                    radius: 48.r,
                                    backgroundColor: mainBlue,
                                    child: Icon(
                                      Icons.account_balance,
                                      size: 44.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 28.h),
                                  Text(
                                    l10n.app_title,
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    l10n.login_subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 18.h),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      l10n.phone_number,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 8.w),
                                        Icon(
                                          Icons.phone,
                                          color: Colors.grey.shade500,
                                          size: 22.sp,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "+91",
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Container(
                                          height: 36.h,
                                          width: 1.w,
                                          color: Colors.grey.shade300,
                                        ),
                                        SizedBox(width: 6.w),
                                        Expanded(
                                          child: TextField(
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            maxLength: 10,
                                            decoration: InputDecoration(
                                              counterText: "",
                                              hintText: l10n.enter_phone_number,
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    vertical: 10.h,
                                                  ),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                10,
                                              ),
                                            ],
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _phoneController.text.length == 10
                                            ? mainBlue
                                            : Colors.grey.shade300,
                                        padding: EdgeInsets.symmetric(
                                          vertical: 15.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                      ),
                                      onPressed:
                                          (_phoneController.text.length == 10 &&
                                              !_isLoading)
                                          ? _sendOtp
                                          : null,
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 20.h,
                                              width: 20.w,
                                              child:
                                                  const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                            )
                                          : Text(
                                              l10n.send_otp,
                                              style: TextStyle(
                                                fontSize: 17.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  if (kIsWeb) ...[
                                    SizedBox(height: 20.h),
                                    SizedBox(
                                      height: 60.h,
                                      child: const HtmlElementView(
                                        viewType: 'recaptcha',
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 32.h),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const WorkerLoginPage(),
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.engineering,
                                      size: 20.sp,
                                      color: mainBlue,
                                    ),
                                    label: Text(
                                      l10n.login_as_worker,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: mainBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // --- Government of Jharkhand text and divider at the bottom, always visible ---
                  Divider(height: 1, color: Colors.grey.shade200),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.government_initiative,
                    style: TextStyle(color: Colors.black54, fontSize: 14.sp),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 16.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        l10n.secure_and_verified,
                        style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
