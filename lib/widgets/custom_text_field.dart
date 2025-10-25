import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final Widget? suffix;
  final bool enabled;
  final int? length;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    this.length,
    required this.label,
    required this.placeholder,
    this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffix,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontWeight: FontWeight.bold,
            fontSize: TextSizes.normal.sp,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              maxLength: length,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLines: maxLines,
              enabled: enabled,
              prefix: icon != null
                  ? Padding(
                      padding: EdgeInsets.only(left: 12.w, right: 8.w),
                      child: Icon(icon, color: AppColors.gray, size: 20.w),
                    )
                  : null,
              suffix: suffix != null
                  ? Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: suffix,
                    )
                  : null,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gray, width: 1.2.w),
                color: enabled
                    ? AppColors.white
                    : AppColors.gray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.all(Radius.circular(16.r)),
              ),
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                color: AppColors.black,
              ),
              placeholderStyle: TextStyle(
                color: AppColors.gray,
                fontSize: TextSizes.normal.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
