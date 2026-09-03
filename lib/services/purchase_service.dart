import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/save_manager.dart';
import 'receipt_validator.dart';

/// Handles the non-consumable purchase that disables interstitial ads.
class PurchaseService extends ChangeNotifier {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const removeAdsProductId = 'remove_ads';

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Verifies purchases before granting the entitlement. Swap this for a
  /// [ServerReceiptValidator] before a production launch — see
  /// receipt_validator.dart.
  final ReceiptValidator _validator = const LocalReceiptValidator();

  ProductDetails? removeAdsProduct;
  bool isAvailable = false;
  bool isBusy = false;
  String? message;

  bool get adsRemoved => SaveManager.instance.save.adsRemoved;

  Future<void> initialize() async {
    _subscription ??= _store.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (_) {
        isBusy = false;
        message = 'Purchases are temporarily unavailable.';
        notifyListeners();
      },
    );

    isAvailable = await _store.isAvailable();
    if (!isAvailable) {
      message = 'Purchases are not available on this device.';
      notifyListeners();
      return;
    }

    final response = await _store.queryProductDetails({removeAdsProductId});
    if (response.productDetails.isNotEmpty) {
      removeAdsProduct = response.productDetails.first;
      message = null;
    } else {
      message = 'Remove Ads will be available after store setup is complete.';
    }
    notifyListeners();
  }

  Future<void> buyRemoveAds() async {
    if (adsRemoved || isBusy) return;
    final product = removeAdsProduct;
    if (product == null) {
      message = 'Remove Ads is not available yet.';
      notifyListeners();
      return;
    }

    isBusy = true;
    message = null;
    notifyListeners();
    final started = await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!started) {
      isBusy = false;
      message = 'Unable to start the purchase. Please try again.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (isBusy) return;
    isBusy = true;
    message = null;
    notifyListeners();
    await _store.restorePurchases();
    isBusy = false;
    notifyListeners();
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) continue;

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // The entitlement is only granted after the validator confirms the
          // receipt. LocalReceiptValidator trusts the store; replace it with a
          // ServerReceiptValidator to verify against a backend before launch.
          if (await _validator.isValid(purchase)) {
            await SaveManager.instance.setAdsRemoved(true);
            message = 'Ads have been removed. Thank you for your support!';
          } else {
            message = 'We could not verify this purchase. Please try again.';
          }
        case PurchaseStatus.error:
          message = 'The purchase could not be completed. Please try again.';
        case PurchaseStatus.canceled:
          message = null;
        case PurchaseStatus.pending:
          isBusy = true;
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
    isBusy = false;
    notifyListeners();
  }
}
