import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'screens/phone_login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/social_feed_screen.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';
import 'utils/app_colors.dart';
import 'utils/app_fonts.dart';
import 'utils/text_sizes.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized (hot reload case)
  }

  // Initialize services in parallel for faster startup
  await Future.wait([
    FirebaseService().initialize(),
    NotificationService().initialize(),
    AdService.initialize(),
    SubscriptionService().initialize(),
  ]);

  // Request notification permissions (non-blocking)
  NotificationService().requestPermissions();

  // Load ads
  AdService().loadSocialFeedAd();
  AdService().loadAddWarrantyAd();

  // Check subscription status
  await SubscriptionService().checkSubscriptionStatus();

  runApp(const GaranticimApp());
}

class GaranticimApp extends StatelessWidget {
  const GaranticimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(411.42857142857144, 914.2857142857143),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          title: 'Garanticim',
          theme: CupertinoThemeData(
            primaryColor: AppColors.black,
            scaffoldBackgroundColor: AppColors.background,
            barBackgroundColor: AppColors.white,
            textTheme: CupertinoTextThemeData(
              textStyle: TextStyle(
                fontFamily: AppFonts.family,
                color: AppColors.black,
              ),
            ),
          ),
          home: child,
        );
      },
      child: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, bool>>(
      future: _checkAuthState(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CupertinoPageScaffold(
            backgroundColor: AppColors.background,
            child: Center(
              child: CupertinoActivityIndicator(
                radius: 20.r,
                color: AppColors.primary,
              ),
            ),
          );
        }

        final authState = snapshot.data ?? {'isLoggedIn': false};
        final isLoggedIn = authState['isLoggedIn'] ?? false;

        // Guest mode is NOT persisted, so always show login screen
        // unless user is actually logged in
        if (isLoggedIn) {
          return const MainScreen();
        } else {
          return const PhoneLoginScreen();
        }
      },
    );
  }

  Future<Map<String, bool>> _checkAuthState() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    return {'isLoggedIn': isLoggedIn};
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    SocialFeedScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          _screens[_currentIndex],
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.gray.withValues(alpha: 0.2),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 20.r,
              offset: Offset(0, -5.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomBarItem(
              icon: CupertinoIcons.house_fill,
              label: 'Ana Sayfa',
              index: 0,
            ),
            _buildBottomBarItem(
              icon: CupertinoIcons.person_2_square_stack,
              label: 'Sosyal',
              index: 1,
            ),
            _buildBottomBarItem(
              icon: CupertinoIcons.settings,
              label: 'Ayarlar',
              index: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.black.withValues(alpha: 0.05)
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isActive ? AppColors.black : AppColors.gray,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: TextSizes.small.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.black : AppColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
