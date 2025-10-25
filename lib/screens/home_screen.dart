import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/services/auth_service.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import '../models/warranty_item.dart';
import '../services/firebase_service.dart';
import '../services/social_service.dart';
import '../services/ad_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/warranty_card.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import 'add_warranty_screen.dart';
import 'warranty_detail_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final SocialService _socialService = SocialService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String? _userId = '';
  String _searchQuery = '';
  String _filterType = 'all'; // all, expiring, expired
  bool _isProcessingShare = false;
  String? _sharingWarrantyId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final userId = await _authService.getCurrentUserId();
    setState(() {
      _userId = userId;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                _buildFilterButtons(),
                Expanded(child: _buildWarrantiesList()),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: 'Garantilerim',
              actions: [
                RoundIconButton(
                  icon: CupertinoIcons.add,
                  onPressed: _navigateToAddWarranty,
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
        placeholder: 'Ürün adı, tedarikçi veya fatura ara...',
        itemSize: 24.w, // 🔹 ikon ve yükseklik ölçeği
        padding: EdgeInsets.symmetric(
          vertical: 16.h,
          horizontal: 8.w,
        ), // 🔹 responsive iç boşluk
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

  Widget _buildFilterButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildFilterButton('Tümü', 'all'),
          SizedBox(width: 8.w),
          _buildFilterButton('Yaklaşan', 'expiring'),
          SizedBox(width: 8.w),
          _buildFilterButton('Dolan', 'expired'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String type) {
    final isSelected = _filterType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _filterType = type;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.black : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.black
                  : AppColors.gray.withValues(alpha: 0.3),
              width: 1.2.w,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.small.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.white : AppColors.gray,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarrantiesList() {
    if (_userId == null || _userId!.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return StreamBuilder<List<WarrantyItem>>(
      stream: _firebaseService.getWarrantiesSortedByExpiry(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CupertinoActivityIndicator(color: AppColors.black),
          );
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: 'Bir Hata Oluştu',
            description: 'Garanti verileri yüklenemedi. Lütfen tekrar deneyin.',
            actionLabel: 'Yenile',
            onAction: () {
              setState(() {});
            },
          );
        }

        var warranties = snapshot.data ?? [];

        warranties = _applyFilters(warranties);

        if (warranties.isEmpty) {
          return SingleChildScrollView(
            child: EmptyStateWidget(
              icon: CupertinoIcons.cube_box,
              title: _getEmptyStateTitle(),
              description: _getEmptyStateDescription(),
              actionLabel: _filterType == 'all' ? 'Garanti Ekle' : null,
              onAction: _filterType == 'all' ? _navigateToAddWarranty : null,
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 500));
              },
            ),
            SliverPadding(
              padding: EdgeInsets.only(
                top: 16.h,
                left: 16.w,
                right: 16.w,
                bottom: 100.h,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final warranty = warranties[index];

                  return WarrantyCard(
                    item: warranty,
                    onTap: () => _navigateToDetail(warranty),
                    onShare: () => _showShareOptions(warranty),
                    isShareLoading:
                        _isProcessingShare && _sharingWarrantyId == warranty.id,
                  );
                }, childCount: warranties.length),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showShareOptions(WarrantyItem warranty) {
    if (_isProcessingShare) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Text(
            "Sosyalde Paylaş",
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontWeight: FontWeight.bold,
              fontSize: TextSizes.box.sp,
              color: AppColors.black,
            ),
          ),
        ),
        message: Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            "Bu ürünü nasıl değerlendiriyorsun?",
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.normal.sp,
              color: AppColors.gray,
            ),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _handleShare(warranty, true);
            },
            child: Text(
              "Öneriyorum",
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _handleShare(warranty, false);
            },
            child: Text(
              "Önermiyorum",
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
          if (warranty.isSharedSocial)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteShare(warranty);
              },
              child: Text(
                "Sosyalden Kaldır",
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.normal.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
        ],
        cancelButton: Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "İptal",
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.gray,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteShare(WarrantyItem warranty) async {
    setState(() {
      _isProcessingShare = true;
      _sharingWarrantyId = warranty.id;
    });

    try {
      await _socialService.deleteSocialPost(warranty.id);

      if (!mounted) return;

      setState(() {
        _isProcessingShare = false;
        _sharingWarrantyId = null;
      });

      HapticFeedback.mediumImpact();
      _showInfoDialog(
        title: "Kaldırıldı",
        message: "Ürünü sosyalden kaldırdın!",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessingShare = false;
        _sharingWarrantyId = null;
      });

      _showInfoDialog(
        title: "Hata",
        message: "Kaldırma sırasında bir sorun oluştu!",
      );
    }
  }

  Future<void> _handleShare(WarrantyItem warranty, bool reaction) async {
    setState(() {
      _isProcessingShare = true;
      _sharingWarrantyId = warranty.id;
    });

    try {
      await _socialService.updateSocialPost(warranty.id, reaction);

      if (!mounted) return;

      setState(() {
        _isProcessingShare = false;
        _sharingWarrantyId = null;
      });

      HapticFeedback.mediumImpact();
      _showInfoDialog(
        title: "Paylaşıldı",
        message: reaction == true
            ? "Ürünü önerdiğin paylaşıldı!"
            : "Ürünü önermediğin paylaşıldı!",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessingShare = false;
        _sharingWarrantyId = null;
      });

      _showInfoDialog(
        title: "Hata",
        message: "Paylaşım sırasında bir sorun oluştu!",
      );
    }
  }

  void _showInfoDialog({required String title, required String message}) {
    ResponsiveDialog.show(context: context, title: title, description: message);
  }

  List<WarrantyItem> _applyFilters(List<WarrantyItem> warranties) {
    var filtered = warranties;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((w) {
        return w.productName.toLowerCase().contains(_searchQuery) ||
            w.supplier.toLowerCase().contains(_searchQuery) ||
            w.invoiceNumber.toLowerCase().contains(_searchQuery) ||
            w.categoryName.toLowerCase().contains(_searchQuery) ||
            w.brandName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply type filter
    if (_filterType == 'expiring') {
      filtered = filtered
          .where((w) => w.isExpiringSoon && !w.isExpired)
          .toList();
    } else if (_filterType == 'expired') {
      filtered = filtered.where((w) => w.isExpired).toList();
    }

    return filtered;
  }

  String _getEmptyStateTitle() {
    if (_searchQuery.isNotEmpty) {
      return 'Sonuç Bulunamadı';
    }
    if (_filterType == 'expiring') {
      return 'Yaklaşan Garanti Yok';
    }
    if (_filterType == 'expired') {
      return 'Dolmuş Garanti Yok';
    }
    return 'Henüz Garanti Eklenmemiş';
  }

  String _getEmptyStateDescription() {
    if (_searchQuery.isNotEmpty) {
      return 'Aramanızla eşleşen garanti bulunamadı. Farklı bir arama terimi deneyin.';
    }
    if (_filterType == 'expiring') {
      return '30 gün içinde dolacak garanti bulunmuyor.';
    }
    if (_filterType == 'expired') {
      return 'Süresi dolmuş garanti bulunmuyor.';
    }
    return 'İlk garantinizi ekleyerek başlayın!';
  }

  Future<void> _navigateToAddWarranty() async {
    HapticFeedback.mediumImpact();

    if (_userId == null) return;

    // Check if user is premium
    final isPremium = await _authService.isPremiumUser();

    // If not premium, check warranty limit
    if (!isPremium) {
      final canCreate = await _firebaseService.canCreateWarranty(_userId!, false);

      if (!canCreate) {
        // Show subscription screen
        if (mounted) {
          await Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => const SubscriptionScreen(),
            ),
          );
        }
        return;
      }

      // Show rewarded ad before allowing warranty creation
      await AdService().showAddWarrantyAd();
    }

    // Navigate to add warranty screen
    if (mounted) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const AddWarrantyScreen(),
        ),
      );
    }
  }

  void _navigateToDetail(WarrantyItem warranty) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => WarrantyDetailScreen(warranty: warranty),
      ),
    );
  }
}
