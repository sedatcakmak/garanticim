import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import '../models/warranty_item.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/social_service.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../utils/date_helpers.dart';
import 'add_warranty_screen.dart';

class WarrantyDetailScreen extends StatefulWidget {
  final WarrantyItem warranty;

  const WarrantyDetailScreen({super.key, required this.warranty});

  @override
  State<WarrantyDetailScreen> createState() => _WarrantyDetailScreenState();
}

class _WarrantyDetailScreenState extends State<WarrantyDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  final SocialService _socialService = SocialService();

  late WarrantyItem _warranty;

  @override
  void initState() {
    super.initState();
    _warranty = widget.warranty;
  }

  @override
  Widget build(BuildContext context) {
    final remainingDays = _warranty.remainingDays;
    final isExpired = _warranty.isExpired;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(top: 100.h),
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _buildStatusCard(remainingDays, isExpired),
                  SizedBox(height: 16.h),
                  _buildImageSection(),
                  SizedBox(height: 16.h),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: 'Garanti Detayları',
              leading: RoundIconButton(
                icon: CupertinoIcons.back,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
              actions: [
                RoundIconButton(
                  icon: CupertinoIcons.ellipsis_circle,
                  onPressed: _showActionSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(int remainingDays, bool isExpired) {
    Color accentColor;
    IconData icon;
    String statusText;

    if (isExpired) {
      accentColor = AppColors.danger;
      icon = CupertinoIcons.exclamationmark_circle_fill;
      statusText = 'Garanti Süresi Doldu';
    } else if (_warranty.isExpiringSoon) {
      accentColor = AppColors.warning;
      icon = CupertinoIcons.clock_fill;
      statusText = 'Garanti Dolmak Üzere';
    } else {
      accentColor = AppColors.success;
      icon = CupertinoIcons.checkmark_shield_fill;
      statusText = 'Garanti Aktif';
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.8), accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48.sp, color: AppColors.white),
          SizedBox(height: 12.h),
          Text(
            statusText,
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.title.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            DateHelpers.formatRemainingTime(remainingDays),
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.box.sp,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if (_warranty.productPhotoUrl != null)
          _buildImageCard('Ürün Fotoğrafı', _warranty.productPhotoUrl!),
        if (_warranty.productPhotoUrl != null &&
            _warranty.invoicePhotoUrl != null)
          SizedBox(height: 16.h),
        if (_warranty.invoicePhotoUrl != null)
          _buildImageCard('Fatura Fotoğrafı', _warranty.invoicePhotoUrl!),
      ],
    );
  }

  Widget _buildImageCard(String title, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageUrl),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.normal.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200.h,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200.h,
                    child: Center(
                      child: CupertinoActivityIndicator(color: AppColors.gray),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200.h,
                    color: AppColors.gray.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: AppColors.danger,
                        size: 48.sp,
                      ),
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

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ürün Bilgileri',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.box.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 20.h),
          _buildInfoRow(
            CupertinoIcons.cube_box,
            'Ürün Adı',
            _warranty.productName,
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.square_list,
            'Kategori',
            _warranty.categoryName.isNotEmpty ? _warranty.categoryName : '-',
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.tag,
            'Marka',
            _warranty.brandName.isNotEmpty ? _warranty.brandName : '-',
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.building_2_fill,
            'Tedarikçi',
            _warranty.supplier,
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.calendar,
            'Satın Alma Tarihi',
            DateHelpers.formatDate(_warranty.purchaseDate),
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.doc_text,
            'Fatura Numarası',
            _warranty.invoiceNumber,
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.clock,
            'Garanti Süresi',
            '${_warranty.warrantyMonths} ay',
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.calendar_badge_plus,
            'Son Kullanım',
            DateHelpers.formatDate(_warranty.expiryDate),
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.money_dollar_circle,
            'Toplam Maliyet',
            '${_warranty.totalCost.toStringAsFixed(2)} TL',
          ),
          _buildDivider(),
          _buildInfoRow(
            CupertinoIcons.share_up,
            'Sosyal Paylaşım',
            _warranty.isSharedSocial
                ? 'Paylaşıldı (${_warranty.isLiked ? "Öneriliyor" : "Önerilmiyor"})'
                : 'Paylaşılmadı',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.gray),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.small.sp,
                    color: AppColors.gray,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.normal.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1.h, color: AppColors.gray.withValues(alpha: 0.2));
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => _FullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  void _showActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToEdit();
            },
            child: Text(
              'Düzenle',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                color: AppColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete();
            },
            isDestructiveAction: true,
            child: Text(
              'Sil',
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        cancelButton: Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            isDefaultAction: true,
            child: Text(
              'İptal',
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

  void _navigateToEdit() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddWarrantyScreen(warranty: _warranty),
      ),
    );
  }

  void _confirmDelete() {
    ResponsiveDialog.show(
      context: context,
      title: 'Emin misiniz?',
      titleColor: AppColors.warning,
      description: 'Bu garantiyi silmek istediğinize emin misiniz?',
      actions: [
        CupertinoDialogAction(
          child: const Text('İptal'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Sil'),
          onPressed: () async {
            Navigator.of(context).pop();
            await _deleteWarranty();
          },
        ),
      ],
    );
  }

  Future<void> _deleteWarranty() async {
    try {
      await _socialService.deleteSocialPost(_warranty.id);
      await _firebaseService.deleteWarranty(_warranty.id);
      await _notificationService.cancelWarrantyNotifications(_warranty.id);

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ResponsiveDialog.show(
          context: context,
          title: 'Hata',
          titleColor: AppColors.danger,
          description: 'Garanti silinirken bir hata oluştu.',
        );
      }
    }
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.black,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.xmark, color: AppColors.white),
        ),
      ),
      child: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return CupertinoActivityIndicator(color: AppColors.white);
            },
          ),
        ),
      ),
    );
  }
}
