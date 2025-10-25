import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'auth_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final AuthService _authService = AuthService();

  // Subscription product IDs (Play Store ve App Store'da tanımlanmalı)
  static const String monthlySubscriptionId = 'garanticim_premium_monthly';

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  /// Initialize subscription service
  Future<void> initialize() async {
    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        print('Purchase stream error: $error');
      },
    );
  }

  /// Load available products
  Future<bool> loadProducts() async {
    try {
      const Set<String> productIds = {monthlySubscriptionId};
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
        return false;
      }

      _products = response.productDetails;
      return true;
    } catch (e) {
      print('Error loading products: $e');
      return false;
    }
  }

  /// Get monthly subscription product
  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere(
        (product) => product.id == monthlySubscriptionId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Purchase subscription
  Future<bool> purchaseSubscription() async {
    try {
      final product = monthlyProduct;
      if (product == null) {
        print('Product not available');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase and update user premium status
        await _verifyAndUpdatePremium(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verify purchase and update premium status
  Future<void> _verifyAndUpdatePremium(PurchaseDetails purchase) async {
    try {
      // Calculate expiry date (30 days from now for monthly subscription)
      final expiryDate = DateTime.now().add(const Duration(days: 30));

      // Update user premium status in Firestore
      await _authService.updatePremiumStatus(
        isPremium: true,
        expiryDate: expiryDate,
        subscriptionId: purchase.productID,
      );
    } catch (e) {
      print('Error verifying purchase: $e');
    }
  }

  /// Check and update subscription status
  /// Should be called on app startup and periodically
  Future<void> checkSubscriptionStatus() async {
    try {
      final expiryDate = await _authService.getPremiumExpiryDate();
      if (expiryDate == null) return;

      // If subscription expired, update status
      if (expiryDate.isBefore(DateTime.now())) {
        await _authService.updatePremiumStatus(
          isPremium: false,
          expiryDate: null,
          subscriptionId: null,
        );
      }
    } catch (e) {
      print('Error checking subscription status: $e');
    }
  }

  /// Dispose subscription listener
  void dispose() {
    _subscription?.cancel();
  }
}
