import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/custom_app_bar.dart';

class PolicyViewerScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(top: 100.h),
              child: FutureBuilder<String>(
                future: rootBundle.loadString(assetPath),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CupertinoActivityIndicator(color: AppColors.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'İçerik yüklenemedi',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: TextSizes.body.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(20.w),
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Text(
                        snapshot.data ?? '',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: TextSizes.normal.sp,
                          color: AppColors.text,
                          height: 1.6,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: title,
              leading: RoundIconButton(
                icon: CupertinoIcons.back,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
              actions: const [],
            ),
          ),
        ],
      ),
    );
  }
}
