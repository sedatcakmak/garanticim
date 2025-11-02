import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/image_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class ImageSourcePicker {
  static Future<File?> pickImage(BuildContext context) async {
    final imageService = ImageService();

    return await showCupertinoModalPopup<File?>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Fotoğraf Seç',
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: TextSizes.normal.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: Text(
          'Fotoğrafı nereden eklemek istersiniz?',
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: TextSizes.small.sp,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              final file = await imageService.pickImageFromCamera();
              if (context.mounted) {
                Navigator.pop(context, file);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera_fill,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Kamera',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.normal.sp,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              final file = await imageService.pickImageFromGallery();
              if (context.mounted) {
                Navigator.pop(context, file);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.photo_fill,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Galeri',
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.normal.sp,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
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
      ),
    );
  }
}
