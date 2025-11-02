import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/otp_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/responsive_dialog.dart';
import 'otp_verification_screen.dart';

class PhoneRegistrationScreen extends StatefulWidget {
  const PhoneRegistrationScreen({super.key});

  @override
  State<PhoneRegistrationScreen> createState() =>
      _PhoneRegistrationScreenState();
}

class _PhoneRegistrationScreenState extends State<PhoneRegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final OtpService _otpService = OtpService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-numeric characters
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Add +90 if not present
    if (!phone.startsWith('90')) {
      if (phone.startsWith('0')) {
        phone = '90${phone.substring(1)}';
      } else {
        phone = '90$phone';
      }
    }

    return '+$phone';
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ResponsiveDialog.show(
        context: context,
        title: 'Hata',
        description: 'Lütfen telefon numaranızı girin',
        titleColor: AppColors.danger,
      );
      return;
    }

    if (phone.length < 10) {
      ResponsiveDialog.show(
        context: context,
        title: 'Hata',
        description: 'Geçerli bir telefon numarası girin',
        titleColor: AppColors.danger,
      );
      return;
    }

    setState(() => _isLoading = true);

    final formattedPhone = _formatPhoneNumber(phone);
    final success = await _otpService.sendOtp(formattedPhone);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) =>
                OtpVerificationScreen(phoneNumber: formattedPhone),
          ),
        );
      }
    } else {
      if (mounted) {
        ResponsiveDialog.show(
          context: context,
          title: 'Hata',
          description: 'SMS gönderilemedi. Lütfen tekrar deneyin.',
          titleColor: AppColors.danger,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.back,
                          color: AppColors.black,
                          size: 24.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Geri',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: TextSizes.normal.sp,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                Icon(
                  CupertinoIcons.phone_circle_fill,
                  size: 80.sp,
                  color: AppColors.primary,
                ),
                SizedBox(height: 24.h),

                Text(
                  'Telefon Numaranızı Girin',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.big.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),

                Text(
                  'Size SMS ile doğrulama kodu göndereceğiz',
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
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gray.withValues(alpha: 0.1),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: CupertinoTextField(
                    controller: _phoneController,
                    placeholder: '5XX XXX XX XX',
                    prefix: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Text(
                        '+90',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: TextSizes.normal.sp,
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: TextSizes.normal.sp,
                      color: AppColors.text,
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Send button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    borderRadius: BorderRadius.circular(16.r),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    color: AppColors.black,
                    child: _isLoading
                        ? CupertinoActivityIndicator(color: AppColors.white)
                        : Text(
                            'Doğrulama Kodu Gönder',
                            style: TextStyle(
                              fontFamily: AppFonts.family,
                              fontSize: TextSizes.box.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
