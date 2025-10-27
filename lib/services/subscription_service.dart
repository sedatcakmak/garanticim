import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'auth_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final AuthService _authService = AuthService();

  static const String monthlySubscriptionId = 'premium_membership';

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  Future<void> initialize() async {
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('In-app purchase not available');
      return;
    }

    if (_subscription != null) return;

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    if (Platform.isIOS) {
      await restorePurchases();
    }
  }

  Future<bool> loadProducts() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('In-app purchase not available');
        return false;
      }

      const Set<String> productIds = {monthlySubscriptionId};
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
        return false;
      }

      _products = response.productDetails;
      return true;
    } catch (e) {
      debugPrint('Error loading products: $e');
      return false;
    }
  }

  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere(
        (product) => product.id == monthlySubscriptionId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> purchaseSubscription() async {
    try {
      final product = monthlyProduct;
      if (product == null) {
        debugPrint('Product not available');
        return false;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _verifyAndUpdatePremium(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyAndUpdatePremium(PurchaseDetails purchase) async {
    try {
      final expiryDate = DateTime.now().add(const Duration(days: 30));

      await _authService.updatePremiumStatus(
        isPremium: true,
        expiryDate: expiryDate,
        subscriptionId: purchase.productID,
      );
    } catch (e) {
      debugPrint('Error verifying purchase: $e');
    }
  }

  Future<void> checkSubscriptionStatus() async {
    try {
      final expiryDate = await _authService.getPremiumExpiryDate();
      if (expiryDate == null) return;

      if (expiryDate.isBefore(DateTime.now())) {
        await _authService.updatePremiumStatus(
          isPremium: false,
          expiryDate: null,
          subscriptionId: null,
        );
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
