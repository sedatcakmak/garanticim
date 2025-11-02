import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/main.dart';
import 'package:garanticim/screens/policy_viewer_screen.dart';
import 'package:garanticim/services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    HapticFeedback.mediumImpact();

    await _authService.initUser();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const MainScreen()),
      );
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
                Image.asset('assets/logo.png', width: 120.w, height: 120.w),
                SizedBox(height: 32.h),

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

                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _continueAsGuest,
                    borderRadius: BorderRadius.circular(16.r),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    color: AppColors.black,
                    child: Text(
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

                SizedBox(height: 24.h),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
