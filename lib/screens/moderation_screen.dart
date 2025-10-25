import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/warranty_item.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  final SocialService _socialService = SocialService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  Future<void> _approvePost(WarrantyItem post) async {
    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Get admin ID
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        _showErrorDialog('Kullanıcı oturumu bulunamadı.');
        return;
      }

      // Call approvePost
      await _socialService.approvePost(post.id, currentUserId);

      // Send notification to post owner
      await _notificationService.sendPostApprovedNotification(post.productName);

      // Show success message
      _showSuccessDialog('Paylaşım onaylandı ve sosyal akışta görünüyor.');
    } catch (e) {
      _showErrorDialog('Paylaşım onaylanırken bir hata oluştu: $e');
    }
  }

  Future<void> _rejectPost(WarrantyItem post) async {
    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Get admin ID
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        _showErrorDialog('Kullanıcı oturumu bulunamadı.');
        return;
      }

      // Call rejectPost
      await _socialService.rejectPost(post.id, currentUserId);

      // Send notification to post owner
      await _notificationService.sendPostRejectedNotification(post.productName);

      // Show success message
      _showSuccessDialog('Paylaşım reddedildi.');
    } catch (e) {
      _showErrorDialog('Paylaşım reddedilirken bir hata oluştu: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Başarılı',
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: TextSizes.normal.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: TextSizes.small.sp,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tamam',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Hata',
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: TextSizes.normal.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: TextSizes.small.sp,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tamam',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(top: 100.h, bottom: 20.h),
              child: StreamBuilder<List<WarrantyItem>>(
                stream: _socialService.getPendingPosts(),
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CupertinoActivityIndicator(
                        color: AppColors.primary,
                        radius: 20.r,
                      ),
                    );
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return EmptyStateWidget(
                      icon: CupertinoIcons.exclamationmark_triangle,
                      title: 'Bir Hata Oluştu',
                      description:
                          'Bekleyen paylaşımlar yüklenemedi. Lütfen daha sonra tekrar deneyin.',
                    );
                  }

                  final posts = snapshot.data ?? [];

                  // Empty state
                  if (posts.isEmpty) {
                    return EmptyStateWidget(
                      icon: CupertinoIcons.checkmark_shield,
                      title: 'Bekleyen Paylaşım Yok',
                      description:
                          'Moderasyon bekleyen herhangi bir paylaşım bulunmuyor.',
                    );
                  }

                  // List of pending posts
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _PendingPostCard(
                        post: post,
                        onApprove: () => _approvePost(post),
                        onReject: () => _rejectPost(post),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: 'Moderasyon',
              leading: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Icon(
                  CupertinoIcons.back,
                  color: AppColors.black,
                  size: 28.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPostCard extends StatelessWidget {
  final WarrantyItem post;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingPostCard({
    required this.post,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final reactionColor = post.isLiked ? AppColors.success : AppColors.danger;
    final reactionLabel = post.isLiked
        ? 'Beğendiğini söylüyor!'
        : 'Beğenmediğini söylüyor!';
    final reactionIcon = post.isLiked
        ? CupertinoIcons.hand_thumbsup_fill
        : CupertinoIcons.hand_thumbsdown_fill;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User header
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_crop_circle_fill,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    // Get username from userId
                    FutureBuilder<String>(
                      future: _getUserName(post.userId),
                      builder: (context, snapshot) {
                        final username = snapshot.data ?? 'Kullanıcı';
                        return Text(
                          username,
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: TextSizes.normal.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Icon(reactionIcon, color: reactionColor, size: 20.sp),
                  ],
                ),
                SizedBox(height: 8.h),

                // Product name
                Text(
                  post.productName,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.box.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),

                // Category and Brand
                _buildInfoRow(
                  CupertinoIcons.square_list,
                  'Kategori',
                  post.categoryName,
                ),
                _buildInfoRow(CupertinoIcons.tag, 'Marka', post.brandName),
                _buildInfoRow(
                  CupertinoIcons.building_2_fill,
                  'Tedarikçi',
                  post.supplier,
                ),

                SizedBox(height: 8.h),

                // Reaction label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: reactionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(reactionIcon, size: 16.sp, color: reactionColor),
                          SizedBox(width: 6.w),
                          Text(
                            reactionLabel,
                            style: TextStyle(
                              fontFamily: AppFonts.family,
                              fontSize: TextSizes.small.sp,
                              fontWeight: FontWeight.w600,
                              color: reactionColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(post.sharedAt),
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: TextSizes.small.sp,
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product photo
          if (post.productPhotoUrl != null && post.productPhotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(0.r),
                topRight: Radius.circular(0.r),
              ),
              child: Image.network(
                post.productPhotoUrl!,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200.h,
                    color: AppColors.gray.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.photo,
                        color: AppColors.gray,
                        size: 40.sp,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200.h,
                    child: Center(
                      child: CupertinoActivityIndicator(color: AppColors.gray),
                    ),
                  );
                },
              ),
            ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Reject button
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(12.r),
                    onPressed: onReject,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Reddet',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: TextSizes.normal.sp,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Approve button
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12.r),
                    onPressed: onApprove,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: CupertinoColors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Onayla',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: TextSizes.normal.sp,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColors.gray),
          SizedBox(width: 6.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.small.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.gray,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.small.sp,
                color: AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? 'Kullanıcı';
      }
      return 'Kullanıcı';
    } catch (e) {
      return 'Kullanıcı';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Az önce';
        }
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
