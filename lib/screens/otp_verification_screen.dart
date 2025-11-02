import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/otp_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/responsive_dialog.dart';
import 'user_info_input_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final OtpService _otpService = OtpService();
  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _getOtpCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyOtp() async {
    final code = _getOtpCode();

    if (code.length != 6) {
      ResponsiveDialog.show(
        context: context,
        title: 'Hata',
        description: 'Lütfen 6 haneli kodu girin',
        titleColor: AppColors.danger,
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await _otpService.verifyOtp(widget.phoneNumber, code);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) =>
                UserInfoInputScreen(phoneNumber: widget.phoneNumber),
          ),
        );
      }
    } else {
      if (mounted) {
        ResponsiveDialog.show(
          context: context,
          title: 'Hata',
          description: 'Geçersiz kod. Lütfen tekrar deneyin.',
          titleColor: AppColors.danger,
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    final success = await _otpService.sendOtp(widget.phoneNumber);

    setState(() => _isLoading = false);

    if (success) {
      _startResendTimer();
      if (mounted) {
        ResponsiveDialog.show(
          context: context,
          title: 'Başarılı',
          description: 'Yeni doğrulama kodu gönderildi',
          titleColor: AppColors.success,
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
                  CupertinoIcons.chat_bubble_text_fill,
                  size: 80.sp,
                  color: AppColors.primary,
                ),
                SizedBox(height: 24.h),

                Text(
                  'Doğrulama Kodu',
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
                  '${widget.phoneNumber} numarasına gönderilen 6 haneli kodu girin',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.body.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),

                // OTP input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 50.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gray.withValues(alpha: 0.1),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: CupertinoTextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: TextSizes.big.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }

                          // Auto-verify when all 6 digits are entered
                          if (index == 5 && value.isNotEmpty) {
                            _verifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),

                SizedBox(height: 32.h),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    borderRadius: BorderRadius.circular(16.r),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    color: AppColors.black,
                    child: _isLoading
                        ? CupertinoActivityIndicator(color: AppColors.white)
                        : Text(
                            'Doğrula',
                            style: TextStyle(
                              fontFamily: AppFonts.family,
                              fontSize: TextSizes.box.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Resend button
                CupertinoButton(
                  onPressed:
                      _isLoading || _resendCountdown > 0 ? null : _resendOtp,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Kodu Tekrar Gönder ($_resendCountdown)'
                        : 'Kodu Tekrar Gönder',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: TextSizes.normal.sp,
                      color: _resendCountdown > 0
                          ? AppColors.gray
                          : AppColors.primary,
                      decoration: _resendCountdown > 0
                          ? TextDecoration.none
                          : TextDecoration.underline,
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
