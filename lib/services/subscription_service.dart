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

  /// Bu callback, UI tarafından atanacak.
  /// Başarılı veya hatalı satın alma durumlarını bildirmek için kullanılır.
  void Function(bool success, [String? message])? onPurchaseResult;

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
      if (!available) return false;

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

  /// Satın alma sürecini başlatır ama sonucu burada dönmez.
  /// Sonuç, [onPurchaseResult] callback'i ile bildirilir.
  Future<void> purchaseSubscription() async {
    try {
      final product = monthlyProduct;
      if (product == null) {
        onPurchaseResult?.call(false, 'Ürün bulunamadı.');
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      onPurchaseResult?.call(false, 'Satın alma hatası: $e');
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      onPurchaseResult?.call(false, 'Satın almalar geri yüklenemedi.');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        await _verifyAndUpdatePremium(purchaseDetails);
        onPurchaseResult?.call(true);
        debugPrint("SATIN ALMA TAMAMLANDI!");
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint("SATIN ALMA HATASI: ${purchaseDetails.error}");
        onPurchaseResult?.call(false, purchaseDetails.error?.message);
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

  void dispose() {
    _subscription?.cancel();
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
        debugPrint('Abonelik süresi dolmuş, premium iptal edildi.');
      } else {
        debugPrint('Abonelik hala aktif, geçerlilik: $expiryDate');
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }
}
