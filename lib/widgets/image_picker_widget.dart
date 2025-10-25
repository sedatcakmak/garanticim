import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class ImagePickerWidget extends StatelessWidget {
  final String label;
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const ImagePickerWidget({
    super.key,
    required this.label,
    this.imageFile,
    this.imageUrl,
    required this.onPickImage,
    this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

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
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray, width: 1.2.w),
              color: AppColors.white,
              borderRadius: BorderRadius.all(Radius.circular(16.r)),
            ),
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(16.r)),
                        child: _buildImage(),
                      ),
                      if (onRemoveImage != null)
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: GestureDetector(
                            onTap: onRemoveImage,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                color: AppColors.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo,
                        size: 48.sp,
                        color: AppColors.gray,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Fotoğraf Seç',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: TextSizes.normal.sp,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CupertinoActivityIndicator(
              color: AppColors.gray,
              radius: 14.r,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppColors.danger,
              size: 48.sp,
            ),
          );
        },
      );
    }
    return const SizedBox();
  }
}
