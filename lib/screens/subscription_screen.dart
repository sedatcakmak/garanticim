import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/subscription_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../widgets/responsive_dialog.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  bool _isLoadingProducts = true;
  String _price = '₺30/ay';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final success = await _subscriptionService.loadProducts();
      if (success && mounted) {
        final product = _subscriptionService.monthlyProduct;
        if (product != null) {
          setState(() {
            _price = product.price;
          });
        }
      }
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  Future<void> _purchaseSubscription() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final success = await _subscriptionService.purchaseSubscription();

      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('Satın alma işlemi başlatılamadı. Lütfen tekrar deneyin.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Bir hata oluştu: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      final success = await _subscriptionService.restorePurchases();

      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('Geri yüklenecek satın alma bulunamadı.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Bir hata oluştu: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    ResponsiveDialog.show(
      context: context,
      title: 'Başarılı!',
      description: 'Premium üyeliğiniz aktif edildi. Tüm özelliklerin keyfini çıkarabilirsiniz!',
      titleColor: AppColors.success,
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Close subscription screen
          },
          child: Text(
            'Harika!',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.normal.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 20.sp,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Hero icon
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.info,
                          AppColors.info.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withValues(alpha: 0.3),
                          blurRadius: 20.r,
                          offset: Offset(0, 10.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.star_fill,
                      size: 60.sp,
                      color: CupertinoColors.white,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Title
                  Text(
                    'Premium Üyelik',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: TextSizes.big.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12.h),

                  // Subtitle
                  Text(
                    'Tüm özelliklerin kilidini aç',
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: TextSizes.normal.sp,
                      color: AppColors.gray,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 48.h),

                  // Benefits list
                  _buildBenefitItem(
                    icon: CupertinoIcons.infinite,
                    title: 'Sınırsız fatura oluşturma',
                    description: 'İstediğiniz kadar ürün ekleyin',
                  ),

                  SizedBox(height: 20.h),

                  _buildBenefitItem(
                    icon: CupertinoIcons.eye_slash_fill,
                    title: 'Reklamsız deneyim',
                    description: 'Hiç reklam görmeden kullanın',
                  ),

                  SizedBox(height: 20.h),

                  _buildBenefitItem(
                    icon: CupertinoIcons.chat_bubble_2_fill,
                    title: 'Öncelikli destek',
                    description: 'Sorularınıza hızlı yanıt alın',
                  ),

                  SizedBox(height: 48.h),

                  // Price display
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                        width: 2.w,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isLoadingProducts ? 'Yükleniyor...' : _price,
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: 36.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Aylık abonelik',
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: TextSizes.small.sp,
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Purchase button
                  GestureDetector(
                    onTap: _isLoading || _isLoadingProducts ? null : _purchaseSubscription,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLoading || _isLoadingProducts
                              ? [AppColors.gray, AppColors.gray]
                              : [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: _isLoading || _isLoadingProducts
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.info.withValues(alpha: 0.4),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 10.h),
                                ),
                              ],
                      ),
                      child: _isLoading
                          ? Center(
                              child: CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                                radius: 12.r,
                              ),
                            )
                          : Text(
                              'Abone Ol',
                              style: TextStyle(
                                fontFamily: AppFonts.family,
                                fontSize: TextSizes.box.sp,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Restore button
                  GestureDetector(
                    onTap: _isLoading || _isLoadingProducts ? null : _restorePurchases,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.gray.withValues(alpha: 0.3),
                          width: 1.5.w,
                        ),
                      ),
                      child: Text(
                        'Satın Alımları Geri Yükle',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: TextSizes.normal.sp,
                          fontWeight: FontWeight.w600,
                          color: _isLoading || _isLoadingProducts
                              ? AppColors.gray
                              : AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Later button
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      child: Text(
                        'Daha Sonra',
                        style: TextStyle(
                          fontFamily: AppFonts.family,
                          fontSize: TextSizes.normal.sp,
                          fontWeight: FontWeight.w600,
                          color: _isLoading ? AppColors.gray : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Terms text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'Abonelik otomatik olarak yenilenir. İptal etmek için hesap ayarlarınızdan aboneliği iptal edebilirsiniz. İptal sonrası mevcut dönem sonuna kadar premium özellikler kullanılabilir.',
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: 12.sp,
                        color: AppColors.gray.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          // Check icon
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              CupertinoIcons.checkmark_alt,
              size: 28.sp,
              color: AppColors.success,
            ),
          ),

          SizedBox(width: 16.w),

          // Feature icon and text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 20.sp,
                      color: AppColors.black,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
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
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.small.sp,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
