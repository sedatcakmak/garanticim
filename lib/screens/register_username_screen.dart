import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/main.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/custom_text_field.dart';

class RegisterUsernameScreen extends StatefulWidget {
  final String phone;

  const RegisterUsernameScreen({super.key, required this.phone});

  @override
  State<RegisterUsernameScreen> createState() => _RegisterUsernameScreenState();
}

class _RegisterUsernameScreenState extends State<RegisterUsernameScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      _showError('Lütfen kullanıcı adınızı girin');
      return;
    }

    if (username.length < 3) {
      _showError('Kullanıcı adı en az 3 karakter olmalıdır');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user
      final user = await _authService.createUser(widget.phone, username);

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showError('Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.');
        }
        return;
      }

      // Navigate to home
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
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
      title: 'Hata',
      titleColor: AppColors.danger,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 137.h),
              // Icon
              Icon(
                CupertinoIcons.person_circle,
                size: 80.sp,
                color: AppColors.primary,
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Hoş Geldiniz!',
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
                'Devam etmek için bir kullanıcı adı seçin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.body.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 48.h),

              // Username input
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Kullanıcı Adı',
                      placeholder: 'Kullanıcı adınızı girin',
                      icon: CupertinoIcons.person,
                      controller: _usernameController,
                    ),
                    SizedBox(height: 24.h),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: _isLoading ? null : _register,
                        borderRadius: BorderRadius.circular(16.r),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: _isLoading
                            ? CupertinoActivityIndicator(color: AppColors.white)
                            : Text(
                                'Başla',
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
              SizedBox(height: 137.h),
            ],
          ),
        ),
      ),
    );
  }
}
