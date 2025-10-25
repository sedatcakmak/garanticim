import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => Size.fromHeight(115.h); // 🔹 responsive yükseklik

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20.r),
        bottomRight: Radius.circular(20.r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: preferredSize.height,
          padding: EdgeInsets.only(top: 20.h, left: 16.w, right: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (leading != null) leading!,
                  if (leading != null) SizedBox(width: 10.w),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: (TextSizes.title - 4).sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              if (actions != null) Row(children: actions!),
            ],
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const RoundIconButton({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40.w, // 🔹 kare buton, width/height aynı oranda ölçeklenir
        width: 40.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray.withValues(alpha: 0.25),
              blurRadius: 12.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 22.w, color: AppColors.black),
      ),
    );
  }
}
