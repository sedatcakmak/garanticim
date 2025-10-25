import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class ResponsiveDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String description,
    Color? titleColor, // 🔹 başlık rengi eklendi
    List<Widget>? actions, // 🔹 dışarıdan butonlar verilebilir
  }) {
    showCupertinoDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 0.85.sw, minWidth: 0.6.sw),
          child: CupertinoAlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontWeight: FontWeight.bold,
                fontSize: TextSizes.normal.sp,
                color: titleColor ?? AppColors.black, // 🔹 varsayılan siyah
              ),
            ),
            content: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                description,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.description.sp,
                  color: AppColors.black,
                ),
              ),
            ),
            actions:
                actions ??
                [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Tamam',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: TextSizes.small.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
          ),
        ),
      ),
    );
  }
}
