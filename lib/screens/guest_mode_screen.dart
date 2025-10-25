import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/warranty_item.dart';
import '../services/social_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/empty_state_widget.dart';
import 'phone_login_screen.dart';
import 'warranty_detail_screen.dart';

class GuestModeScreen extends StatefulWidget {
  const GuestModeScreen({super.key});

  @override
  State<GuestModeScreen> createState() => _GuestModeScreenState();
}

class _GuestModeScreenState extends State<GuestModeScreen> {
  final SocialService _socialService = SocialService();

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
              child: StreamBuilder<List<WarrantyItem>>(
                stream: _socialService.getAllPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CupertinoActivityIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return EmptyStateWidget(
                      icon: CupertinoIcons.exclamationmark_triangle,
                      title: 'Bir Hata Oluştu',
                      description:
                          'Sosyal akış yüklenemedi. Lütfen daha sonra tekrar deneyin.',
                    );
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return EmptyStateWidget(
                      icon: CupertinoIcons.person_2_square_stack,
                      title: 'Henüz Paylaşım Yok',
                      description:
                          'Topluluk henüz herhangi bir ürün paylaşmamış.',
                      actionLabel: 'Giriş Yap',
                      onAction: _navigateToLogin,
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _GuestPostCard(
                        post: post,
                        onTap: () => _navigateToDetail(post),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _buildCustomAppBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      height: 115.h,
      padding: EdgeInsets.only(top: 50.h, left: 16.w, right: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sosyal',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: (TextSizes.title - 4).sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
              decoration: TextDecoration.none,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            minimumSize: Size.zero,
            borderRadius: BorderRadius.circular(12.r),
            color: AppColors.primary,
            onPressed: _navigateToLogin,
            child: Text(
              'Giriş Yap',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.small.sp,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => const PhoneLoginScreen(),
      ),
    );
  }

  void _navigateToDetail(WarrantyItem post) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => WarrantyDetailScreen(warranty: post),
      ),
    );
  }
}

class _GuestPostCard extends StatelessWidget {
  final WarrantyItem post;
  final VoidCallback onTap;

  const _GuestPostCard({
    required this.post,
    required this.onTap,
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                        _formatDate(post.createdAt),
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
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
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
          ],
        ),
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
