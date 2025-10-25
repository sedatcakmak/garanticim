import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/main.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import 'register_username_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;

  const OTPVerificationScreen({super.key, required this.phone});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 60; // 60 saniye
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _resendCountdown--;
      });

      if (_resendCountdown == 0) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();

    if (code.isEmpty) {
      _showError('Lütfen doğrulama kodunu girin');
      return;
    }

    if (code.length != 6) {
      _showError('Doğrulama kodu 6 haneli olmalıdır');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify OTP
      final isValid = await _authService.verifyOTP(widget.phone, code);

      if (!isValid) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showError('Geçersiz kod. Lütfen tekrar deneyin.');
        }
        return;
      }

      // Check if user exists
      final existingUser = await _authService.getUserByPhone(widget.phone);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (existingUser != null) {
          // User exists, login
          await _authService.loginUser(existingUser);

          // Navigate to home
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              CupertinoPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          }
        } else {
          // New user, go to registration
          if (mounted) {
            Navigator.of(context).pushReplacement(
              CupertinoPageRoute(
                builder: (context) =>
                    RegisterUsernameScreen(phone: widget.phone),
              ),
            );
          }
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

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.sendOTP(widget.phone);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _showSuccess('Kod tekrar gönderildi');
          _startCountdown(); // Countdown'u yeniden başlat
        } else {
          _showError('Kod gönderilemedi. Lütfen tekrar deneyin.');
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

  void _showError(String message) {
    ResponsiveDialog.show(
      context: context,
      title: "Hata",
      description: message,
      titleColor: AppColors.danger,
    );
  }

  void _showSuccess(String message) {
    ResponsiveDialog.show(
      context: context,
      title: "Başarılı",
      description: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 46.h),
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    CupertinoIcons.back,
                    color: AppColors.text,
                    size: 40.sp,
                  ),
                ),
              ),

              SizedBox(height: 91.h),

              // Icon
              Icon(
                CupertinoIcons.lock_shield,
                size: 80.sp,
                color: AppColors.primary,
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Doğrulama Kodu',
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.title.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 8.h),

              // Subtitle
              Text(
                '+${widget.phone} numarasına gönderilen\n6 haneli kodu girin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.body.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 48.h),

              // OTP input
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _otpController,
                      placeholder: '000000',
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8.w,
                        color: AppColors.text,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      padding: EdgeInsets.all(20.w),
                    ),
                    SizedBox(height: 24.h),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: _isLoading ? null : _verifyOTP,
                        borderRadius: BorderRadius.circular(16.r),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: _isLoading
                            ? CupertinoActivityIndicator(color: AppColors.white)
                            : Text(
                                'Doğrula',
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: TextSizes.box.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Resend button with countdown
              CupertinoButton(
                onPressed: (_isLoading || !_canResend) ? null : _resendOTP,
                child: Text(
                  _canResend
                      ? 'Kodu Tekrar Gönder'
                      : 'Kodu Tekrar Gönder ($_resendCountdown)',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.body.sp,
                    color: _canResend ? AppColors.primary : AppColors.gray,
                  ),
                ),
              ),

              SizedBox(height: 91.h),
            ],
          ),
        ),
      ),
    );
  }
}
