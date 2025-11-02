import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../utils/cities.dart';
import '../widgets/responsive_dialog.dart';
import '../main.dart';

class UserInfoInputScreen extends StatefulWidget {
  final String phoneNumber;

  const UserInfoInputScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<UserInfoInputScreen> createState() => _UserInfoInputScreenState();
}

class _UserInfoInputScreenState extends State<UserInfoInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _selectedCity = TurkishCities.cities[0];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeRegistration() async {
    final name = _nameController.text.trim();
    final city = _selectedCity;

    if (name.isEmpty) {
      ResponsiveDialog.show(
        context: context,
        title: 'Hata',
        description: 'Lütfen kullanıcı adınızı girin',
        titleColor: AppColors.danger,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.completeRegistration(
        phoneNumber: widget.phoneNumber,
        name: name,
        city: city,
      );

      if (mounted) {
        // Navigate to main screen
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );

        // Show success message
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ResponsiveDialog.show(
              context: context,
              title: 'Başarılı',
              description:
                  'Kayıt işleminiz tamamlandı! Artık sosyal paylaşım yapabilirsiniz.',
              titleColor: AppColors.success,
            );
          }
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ResponsiveDialog.show(
          context: context,
          title: 'Hata',
          description: 'Kayıt işlemi başarısız. Lütfen tekrar deneyin.',
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
                Icon(
                  CupertinoIcons.person_circle_fill,
                  size: 80.sp,
                  color: AppColors.primary,
                ),
                SizedBox(height: 24.h),

                Text(
                  'Bilgilerinizi Tamamlayın',
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
                  'Son adım! Bilgilerinizi girerek kaydınızı tamamlayın',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.body.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 48.h),

                // Name input
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
                    controller: _nameController,
                    placeholder: 'Kullanıcı Adı',
                    prefix: Padding(
                      padding: EdgeInsets.only(left: 16.w),
                      child: Icon(
                        CupertinoIcons.person,
                        color: AppColors.gray,
                        size: 20.sp,
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
                  ),
                ),

                SizedBox(height: 16.h),

                // City picker
                GestureDetector(
                  onTap: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext context) => Container(
                        height: 250.h,
                        color: AppColors.white,
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'İptal',
                                      style: TextStyle(
                                        fontFamily: AppFonts.family,
                                        fontSize: TextSizes.normal.sp,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Tamam',
                                      style: TextStyle(
                                        fontFamily: AppFonts.family,
                                        fontSize: TextSizes.normal.sp,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Picker
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 32.h,
                                scrollController: FixedExtentScrollController(
                                  initialItem: TurkishCities.cities
                                      .indexOf(_selectedCity),
                                ),
                                onSelectedItemChanged: (int index) {
                                  setState(() {
                                    _selectedCity = TurkishCities.cities[index];
                                  });
                                },
                                children: TurkishCities.cities
                                    .map((city) => Center(
                                          child: Text(
                                            city,
                                            style: TextStyle(
                                              fontFamily: AppFonts.family,
                                              fontSize: TextSizes.normal.sp,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          color: AppColors.gray,
                          size: 20.sp,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            _selectedCity,
                            style: TextStyle(
                              fontFamily: AppFonts.family,
                              fontSize: TextSizes.normal.sp,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          color: AppColors.gray,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Complete button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    borderRadius: BorderRadius.circular(16.r),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    color: AppColors.black,
                    child: _isLoading
                        ? CupertinoActivityIndicator(color: AppColors.white)
                        : Text(
                            'Kaydı Tamamla',
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
