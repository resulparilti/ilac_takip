import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ilac_takip/core/config/env_config.dart';
import 'package:ilac_takip/services/database/settings_repository.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play Billing — aylık Premium (29 TL ürün kimliği .env’den).
class SubscriptionService {
  SubscriptionService({required this.settings});

  final SettingsRepository settings;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  List<ProductDetails> products = [];
  bool available = false;

  InAppPurchase get _iap => InAppPurchase.instance;

  Future<void> init({
    required void Function(bool isPremium) onPremiumChanged,
  }) async {
    if (kIsWeb) {
      available = false;
      return;
    }

    try {
      available = await _iap.isAvailable();
    } catch (e) {
      if (kDebugMode) debugPrint('IAP unavailable: $e');
      available = false;
      return;
    }
    if (!available) return;

    _sub = _iap.purchaseStream.listen(
      (purchases) => _onPurchases(purchases, onPremiumChanged),
      onError: (Object e) {
        if (kDebugMode) debugPrint('IAP stream error: $e');
      },
    );

    await loadProducts();
    await restorePurchases(onPremiumChanged: onPremiumChanged);
  }

  Future<void> loadProducts() async {
    if (!available) return;
    final ids = <String>{EnvConfig.premiumSubscriptionId};
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null && kDebugMode) {
      debugPrint('IAP query error: ${response.error}');
    }
    products = response.productDetails;
  }

  Future<bool> buyPremium() async {
    if (!available) return false;
    if (products.isEmpty) await loadProducts();
    if (products.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'Ürün bulunamadı. Play Console’da '
          '${EnvConfig.premiumSubscriptionId} tanımlı olmalı.',
        );
      }
      return false;
    }
    final product = products.first;
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases({
    required void Function(bool isPremium) onPremiumChanged,
  }) async {
    if (!available) return;
    await _iap.restorePurchases();
    final local = await settings.isPremium();
    onPremiumChanged(local);
  }

  Future<void> _onPurchases(
    List<PurchaseDetails> purchases,
    void Function(bool isPremium) onPremiumChanged,
  ) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        if (kDebugMode) {
          debugPrint('Purchase error: ${purchase.error}');
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final isTarget =
            purchase.productID == EnvConfig.premiumSubscriptionId;
        if (isTarget) {
          await settings.setPremium(
            isPremium: true,
            productId: purchase.productID,
          );
          onPremiumChanged(true);
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
