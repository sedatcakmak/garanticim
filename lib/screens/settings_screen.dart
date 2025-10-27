import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/screens/phone_login_screen.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  final NotificationService _notificationService = NotificationService();
  String _version = '';

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();

    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
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
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const PhoneLoginScreen()),
      (route) => false,
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

  Widget _buildVersionInfo() {
    return Center(
      child: Column(
        children: [
          Image.asset(
            'assets/logo.png',
            width: 64.w,
            height: 64.w,
            fit: BoxFit.contain,
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
            _version.isNotEmpty ? 'Sürüm $_version' : 'Sürüm yükleniyor...',
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
