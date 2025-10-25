import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/screens/phone_login_screen.dart';
import 'package:garanticim/services/auth_service.dart';
import 'package:garanticim/services/firebase_service.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import '../services/notification_service.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import 'policy_viewer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  String? _userName = '';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userName = await _authService.getCurrentUserName();
    setState(() {
      _userName = userName;
    });
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
              padding: EdgeInsets.only(top: 100.h),
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _buildSection(
                    title: 'Bildirimler',
                    children: [
                      _buildSwitchTile(
                        icon: CupertinoIcons.bell_fill,
                        title: 'Bildirimler',
                        subtitle: 'Garanti hatırlatıcıları',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          if (!value) {
                            _notificationService.cancelAllNotifications();
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildSection(
                    title: 'Hesap',
                    children: [
                      _buildInfoTile(
                        icon: CupertinoIcons.person_circle,
                        title: 'Kullanıcı İsmi',
                        value: _userName == null || _userName!.isEmpty
                            ? 'Yükleniyor...'
                            : _userName!,
                      ),
                      _buildDangerActionTile(
                        icon: CupertinoIcons.trash,
                        title: 'Hesabı Sil',
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildSection(
                    title: 'Uygulama',
                    children: [
                      _buildActionTile(
                        icon: CupertinoIcons.info_circle,
                        title: 'Hakkında',
                        onTap: _showAboutDialog,
                      ),
                      _buildActionTile(
                        icon: CupertinoIcons.doc_text,
                        title: 'Kullanım Koşulları',
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const PolicyViewerScreen(
                                title: 'Kullanım Koşulları',
                                assetPath: 'assets/data/terms_of_service.txt',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildActionTile(
                        icon: CupertinoIcons.shield,
                        title: 'Gizlilik Politikası',
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const PolicyViewerScreen(
                                title: 'Gizlilik Politikası',
                                assetPath: 'assets/data/privacy_policy.txt',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  _buildVersionInfo(),
                  SizedBox(height: 200.h),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: 'Ayarlar',
              actions: [
                SizedBox(width: 8.w),
                RoundIconButton(icon: Icons.logout, onPressed: _logout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    AuthService().logout();

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const PhoneLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    HapticFeedback.lightImpact();

    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz silinecektir.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get current user ID
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        _showErrorDialog('Kullanıcı bulunamadı');
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );

      // Delete all user warranties
      await FirebaseService().deleteAllUserWarranties(userId);

      // Delete user account
      final success = await _authService.deleteAccount();

      // Dismiss loading indicator
      if (!mounted) return;
      Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (!mounted) return;
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Başarılı'),
            content: const Text('Hesabınız başarıyla silindi.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Tamam'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );

        // Navigate to login screen
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const PhoneLoginScreen()),
          (route) => false,
        );
      } else {
        _showErrorDialog('Hesap silinirken bir hata oluştu');
      }
    } catch (e) {
      // Dismiss loading indicator if still showing
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Hesap silinirken bir hata oluştu: $e');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
                fontSize: TextSizes.small.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.gray,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.gray.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24.sp, color: AppColors.black),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.normal.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: TextSizes.small.sp,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.only(right: 8.w),
            child: Transform.scale(
              scale: 0.8.w,
              child: CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.black,
                inactiveTrackColor: AppColors.gray.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.gray.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: AppColors.black),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.normal.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.normal.sp,
                color: AppColors.gray,
              ),
            ),
            SizedBox(width: 8.w),
            if (onTap != null)
              Icon(
                CupertinoIcons.chevron_forward,
                size: 18.sp,
                color: AppColors.gray,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.gray.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: AppColors.black),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.normal.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18.sp,
              color: AppColors.gray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerActionTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.gray.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: AppColors.danger),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.normal.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18.sp,
              color: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Icon(
            CupertinoIcons.shield_fill,
            size: 48.sp,
            color: AppColors.gray.withValues(alpha: 0.3),
          ),
          SizedBox(height: 12.h),
          Text(
            'Garanticim',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.box.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Sürüm 1.0.0',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: TextSizes.small.sp,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    ResponsiveDialog.show(
      context: context,
      title: 'Garanticim Hakkında',
      description:
          '\nGaranticim, satın aldığınız ürünlerin garanti sürelerini takip etmenizi sağlayan modern bir uygulamadır.\n\nÜrün fotoğraflarınızı, fatura bilgilerinizi güvenle saklayın ve garanti süreniz dolmadan hatırlatmalar alın.',
    );
  }
}
