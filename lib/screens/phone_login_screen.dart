import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/screens/policy_viewer_screen.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';
import 'guest_mode_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError('Lütfen telefon numaranızı girin');
      return;
    }

    // Validate phone number (Turkish format)
    if (!_isValidPhone(phone)) {
      _showError('Geçerli bir telefon numarası girin (örn: 5551234567)');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add country code if not present
      final fullPhone = phone.startsWith('90') ? phone : '90$phone';

      final success = await _authService.sendOTP(fullPhone);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Navigate to OTP verification screen
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => OTPVerificationScreen(phone: fullPhone),
            ),
          );
        } else {
          _showError('OTP gönderilemedi. Lütfen tekrar deneyin.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Bir hata oluştu. Lütfen tekrar deneyin.');
      }
    }
  }

  bool _isValidPhone(String phone) {
    // Turkish phone number validation (without country code)
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if starts with 90 (country code) or 5 (mobile)
    if (cleaned.startsWith('90')) {
      return cleaned.length == 12; // 90 + 10 digits
    } else if (cleaned.startsWith('5')) {
      return cleaned.length == 10; // 10 digits
    }

    return false;
  }

  void _showError(String message) {
    ResponsiveDialog.show(
      context: context,
      title: "Hata",
      description: message,
      titleColor: AppColors.danger,
    );
  }

  Future<void> _continueAsGuest() async {
    HapticFeedback.mediumImpact();

    // Set guest mode flag
    await _authService.setGuestMode(true);

    if (mounted) {
      // Navigate to guest mode screen
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (context) => const GuestModeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 90.h),
              // Logo
              Image.asset('assets/logo.png', width: 120.w, height: 120.w),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Garanticim',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.big.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 16.h),

              // Subtitle
              Text(
                'Satın aldığın ürünlerin garanti sürelerini, fatura belgelerini ve tedarikçi bilgilerini tek yerden takip et.',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.body.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              // Subtitle
              Text(
                'Her ürün için fatura fotoğrafını yükle, kalan garanti süresini anında gör.',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.body.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),

              // Phone input
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Telefon Numarası (+90)',
                      placeholder: '5555555555',
                      length: 10,
                      icon: CupertinoIcons.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 24.h),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: _isLoading ? null : _sendOTP,
                        borderRadius: BorderRadius.circular(16.r),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: _isLoading
                            ? CupertinoActivityIndicator(color: AppColors.white)
                            : Text(
                                'Devam Et',
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: TextSizes.box.sp,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Guest mode button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        onPressed: _isLoading ? null : _continueAsGuest,
                        borderRadius: BorderRadius.circular(16.r),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        color: AppColors.background,
                        child: Text(
                          'Misafir Olarak Devam Et',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: TextSizes.box.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Info text
              Text(
                'Size SMS ile doğrulama kodu göndereceğiz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.small.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),

              // Terms and Privacy links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const PolicyViewerScreen(
                            title: 'Kullanım Koşulları',
                            assetPath: 'assets/data/terms_of_service.txt',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Kullanım Koşulları',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: TextSizes.small.sp,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    ' ve ',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: TextSizes.small.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const PolicyViewerScreen(
                            title: 'Gizlilik Politikası',
                            assetPath: 'assets/data/privacy_policy.txt',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Gizlilik Politikası',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: TextSizes.small.sp,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Devam ederek kabul etmiş olursunuz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.small.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 90.h),
            ],
          ),
        ),
      ),
    );
  }
}
