import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/models/warranty_item.dart';
import 'package:garanticim/services/auth_service.dart';
import '../services/social_service.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/responsive_dialog.dart';
import 'moderation_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final SocialService _socialService = SocialService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();

  bool _isAdmin = false;

  // Search, Sort, Filter states
  String _searchQuery = '';
  String _sortBy = 'date_new'; // 'date_new', 'date_old', 'liked', 'disliked'
  String? _selectedCategory;
  String? _selectedBrand;

  List<String> _allCategories = [];
  List<String> _allBrands = [];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _showAdOnce();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _showAdOnce() async {
    final adService = AdService();
    final shouldShow = await adService.shouldShowSocialFeedAd();

    if (!shouldShow) return;

    await adService.showSocialFeedAd();
  }

  Future<void> _approvePost(WarrantyItem post) async {
    try {
      final adminId = await _authService.getCurrentUserId();
      if (adminId == null) return;

      await _socialService.approvePost(post.id, adminId);
      await _notificationService.sendPostApprovedNotification(post.productName);

      _showSuccessDialog('Paylaşım onaylandı');
    } catch (e) {
      _showErrorDialog('Hata oluştu: $e');
    }
  }

  Future<void> _rejectPost(WarrantyItem post) async {
    try {
      final adminId = await _authService.getCurrentUserId();
      if (adminId == null) return;

      await _socialService.rejectPost(post.id, adminId);
      await _notificationService.sendPostRejectedNotification(post.productName);

      _showSuccessDialog('Paylaşım reddedildi');
    } catch (e) {
      _showErrorDialog('Hata oluştu: $e');
    }
  }

  void _showSuccessDialog(String message) {
    ResponsiveDialog.show(
      context: context,
      title: 'Başarılı',
      description: message,
      titleColor: AppColors.success,
    );
  }

  void _showErrorDialog(String message) {
    ResponsiveDialog.show(
      context: context,
      title: 'Hata',
      description: message,
      titleColor: AppColors.danger,
    );
  }

  // Extract unique categories and brands from posts
  void _extractCategoriesAndBrands(List<WarrantyItem> posts) {
    final categories = posts.map((p) => p.categoryName).toSet().toList();
    final brands = posts.map((p) => p.brandName).toSet().toList();

    categories.sort();
    brands.sort();

    // Only update if changed to avoid unnecessary rebuilds
    if (_allCategories.length != categories.length ||
        _allBrands.length != brands.length) {
      // Schedule setState for after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _allCategories = categories;
            _allBrands = brands;
          });
        }
      });
    }
  }

  // Apply search, filter, and sort to posts
  List<WarrantyItem> _applyFiltersAndSort(List<WarrantyItem> posts) {
    var filtered = posts;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((post) {
        return post.productName.toLowerCase().contains(query) ||
            post.supplier.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where((post) => post.categoryName == _selectedCategory)
          .toList();
    }

    // Apply brand filter
    if (_selectedBrand != null) {
      filtered = filtered
          .where((post) => post.brandName == _selectedBrand)
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'liked':
        filtered.sort(
          (a, b) => (b.isLiked ? 1 : 0).compareTo(a.isLiked ? 1 : 0),
        );
        break;
      case 'disliked':
        filtered.sort(
          (a, b) => (a.isLiked ? 1 : 0).compareTo(b.isLiked ? 1 : 0),
        );
        break;
      case 'date_old':
        filtered.sort((a, b) => a.sharedAt.compareTo(b.sharedAt));
        break;
      case 'date_new':
      default:
        filtered.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
        break;
    }

    return filtered;
  }

  void _showSortOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Sırala', style: TextStyle(fontFamily: AppFonts.family)),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _sortBy = 'date_new');
              Navigator.pop(context);
            },
            child: Text(
              'Tarihe göre (En Yeni)',
              style: TextStyle(fontFamily: AppFonts.family),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _sortBy = 'date_old');
              Navigator.pop(context);
            },
            child: Text(
              'Tarihe göre (En Eski)',
              style: TextStyle(fontFamily: AppFonts.family),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _sortBy = 'liked');
              Navigator.pop(context);
            },
            child: Text(
              'Önce Beğenilenler',
              style: TextStyle(fontFamily: AppFonts.family),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _sortBy = 'disliked');
              Navigator.pop(context);
            },
            child: Text(
              'Önce Beğenilmeyenler',
              style: TextStyle(fontFamily: AppFonts.family),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal', style: TextStyle(fontFamily: AppFonts.family)),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Kategori Filtrele',
          style: TextStyle(fontFamily: AppFonts.family),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedCategory = null);
              Navigator.pop(context);
            },
            child: Text('Tümü', style: TextStyle(fontFamily: AppFonts.family)),
          ),
          ..._allCategories.map(
            (category) => CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _selectedCategory = category);
                Navigator.pop(context);
              },
              child: Text(
                category,
                style: TextStyle(fontFamily: AppFonts.family),
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal', style: TextStyle(fontFamily: AppFonts.family)),
        ),
      ),
    );
  }

  void _showBrandFilter() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Marka Filtrele',
          style: TextStyle(fontFamily: AppFonts.family),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedBrand = null);
              Navigator.pop(context);
            },
            child: Text('Tümü', style: TextStyle(fontFamily: AppFonts.family)),
          ),
          ..._allBrands.map(
            (brand) => CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _selectedBrand = brand);
                Navigator.pop(context);
              },
              child: Text(brand, style: TextStyle(fontFamily: AppFonts.family)),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal', style: TextStyle(fontFamily: AppFonts.family)),
        ),
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
            child: Column(
              children: [
                SizedBox(height: 100.h),
                _buildSearchBar(),

                // Filter and sort buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          onPressed: _showSortOptions,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.sort_down, size: 18.sp),
                              SizedBox(width: 4.w),
                              Text('Sırala', style: TextStyle(fontSize: 14.sp)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          onPressed: _showCategoryFilter,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.square_grid_2x2, size: 18.sp),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  _selectedCategory ?? 'Kategori',
                                  style: TextStyle(fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          onPressed: _showBrandFilter,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.tag, size: 18.sp),
                              SizedBox(width: 4.w),
                              Text(
                                _selectedBrand ?? 'Marka',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
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
                              'Topluluk henüz herhangi bir ürün paylaşmamış. İlk paylaşımı sen yap!',
                        );
                      }

                      // Extract categories and brands when data arrives
                      _extractCategoriesAndBrands(posts);

                      // Apply filters and sorting
                      final filteredPosts = _applyFiltersAndSort(posts);

                      if (filteredPosts.isEmpty) {
                        return EmptyStateWidget(
                          icon: CupertinoIcons.search,
                          title: 'Sonuç Bulunamadı',
                          description:
                              'Arama ve filtrelerinizle eşleşen paylaşım bulunamadı.',
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        itemCount: filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = filteredPosts[index];
                          return _SocialPostCard(
                            post: post,
                            isAdmin: false,
                            onApprove: () => _approvePost(post),
                            onReject: () => _rejectPost(post),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: 'Sosyal',
              actions: [
                if (_isAdmin)
                  RoundIconButton(
                    icon: CupertinoIcons.checkmark_shield,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const ModerationScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Ürün veya tedarikçi ismi ara...',
        itemSize: 24.w,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        style: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: TextSizes.normal.sp,
          color: AppColors.black,
        ),
        placeholderStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: TextSizes.normal.sp,
          color: AppColors.gray,
        ),
        prefixIcon: Icon(
          CupertinoIcons.search,
          size: 22.w,
          color: AppColors.gray,
        ),
        suffixIcon: Icon(
          CupertinoIcons.clear_circled_solid,
          size: 22.w,
          color: AppColors.gray,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  final WarrantyItem post;
  final bool isAdmin;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SocialPostCard({
    required this.post,
    required this.isAdmin,
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
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_crop_circle_fill,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
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

                    SizedBox(height: 8.h),
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

                if (isAdmin) ...[
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12.r),
                          onPressed: onApprove,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 18.sp,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Onayla',
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: TextSizes.small.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(12.r),
                          onPressed: onReject,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.xmark_circle_fill,
                                size: 18.sp,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Reddet',
                                style: TextStyle(
                                  fontFamily: AppFonts.family,
                                  fontSize: TextSizes.small.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

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
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
    }
  }
}
