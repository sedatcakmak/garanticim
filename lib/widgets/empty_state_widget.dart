import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.gray.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64.sp, color: AppColors.gray),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.title.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                color: AppColors.gray,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  color: AppColors.black,
                  focusColor: AppColors.gray,
                  onPressed: onAction,
                  borderRadius: BorderRadius.circular(16.r),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: AppFonts.family,
                      fontSize: TextSizes.normal.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
