import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/warranty_item.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/date_helpers.dart';
import '../utils/text_sizes.dart';

class WarrantyCard extends StatelessWidget {
  final WarrantyItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool isShareLoading;

  const WarrantyCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
    this.onShare,
    this.isShareLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final remainingDays = item.remainingDays;
    final isExpired = item.isExpired;
    final isExpiringSoon = item.isExpiringSoon;

    Color cardColor;
    Color accentColor;

    if (isExpired) {
      cardColor = AppColors.danger.withValues(alpha: 0.1);
      accentColor = AppColors.danger;
    } else if (isExpiringSoon) {
      cardColor = AppColors.warning.withValues(alpha: 0.1);
      accentColor = AppColors.warning;
    } else {
      cardColor = AppColors.success.withValues(alpha: 0.1);
      accentColor = AppColors.success;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray.withValues(alpha: 0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(accentColor, cardColor),
            _buildContent(
              accentColor,
              remainingDays,
              isExpired,
              isExpiringSoon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accentColor, Color cardColor) {
    return Container(
      height: 140.h,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: item.productPhotoUrl != null && item.productPhotoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
              child: Image.network(
                item.productPhotoUrl!,
                width: double.infinity,
                height: 140.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(accentColor);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder(accentColor);
                },
              ),
            )
          : _buildPlaceholder(accentColor),
    );
  }

  Widget _buildContent(
    Color accentColor,
    int remainingDays,
    bool isExpired,
    bool isExpiringSoon,
  ) {
    final statusText = DateHelpers.formatRemainingTime(remainingDays);
    final shareButtonText = item.isSharedSocial
        ? 'Paylaşımı Güncelle'
        : 'Sosyalde Paylaş';

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.box.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          if (item.brandName.isNotEmpty) ...[
            _buildInfoRow(CupertinoIcons.tag, item.brandName, AppColors.gray),
            SizedBox(height: 4.h),
          ],
          if (item.categoryName.isNotEmpty) ...[
            _buildInfoRow(
              CupertinoIcons.square_list,
              item.categoryName,
              AppColors.gray,
            ),
            SizedBox(height: 4.h),
          ],
          _buildInfoRow(
            CupertinoIcons.building_2_fill,
            item.supplier,
            AppColors.gray,
          ),
          SizedBox(height: 4.h),
          _buildInfoRow(
            CupertinoIcons.calendar,
            DateHelpers.formatDate(item.purchaseDate),
            AppColors.gray,
          ),
          if (item.isSharedSocial) ...[
            SizedBox(height: 4.h),
            _buildInfoRow(
              CupertinoIcons.share_up,
              item.moderationStatus == 'pending'
                  ? 'Beklemede'
                  : 'Sosyalde paylaşıldı',
              item.moderationStatus == 'pending'
                  ? AppColors.warning
                  : AppColors.info,
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpired
                          ? CupertinoIcons.exclamationmark_circle_fill
                          : isExpiringSoon
                          ? CupertinoIcons.clock_fill
                          : CupertinoIcons.checkmark_shield_fill,
                      size: 18.r,
                      color: accentColor,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: TextSizes.small.sp,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (onShare != null)
                SizedBox(
                  height: 40.h,
                  child: CupertinoButton(
                    onPressed: isShareLoading ? null : onShare,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    color: item.isSharedSocial
                        ? AppColors.info.withValues(alpha: 0.15)
                        : AppColors.black,
                    borderRadius: BorderRadius.circular(12.r),
                    child: isShareLoading
                        ? CupertinoActivityIndicator(
                            color: item.isSharedSocial
                                ? AppColors.info
                                : AppColors.white,
                          )
                        : Text(
                            shareButtonText,
                            style: TextStyle(
                              fontFamily: AppFonts.family,
                              fontSize: TextSizes.small.sp,
                              fontWeight: FontWeight.bold,
                              color: item.isSharedSocial
                                  ? AppColors.info
                                  : AppColors.white,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: color),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.small.sp,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Color accentColor) {
    return Center(
      child: Icon(
        CupertinoIcons.cube_box_fill,
        size: 48.r,
        color: accentColor.withValues(alpha: 0.3),
      ),
    );
  }
}
