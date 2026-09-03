import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Verifies that a purchase is genuine before an entitlement is granted.
///
/// The default [LocalReceiptValidator] trusts the platform store, which is the
/// same behaviour the app shipped with. It is adequate for development and for
/// low-risk entitlements, but it can be spoofed on a rooted or jailbroken
/// device because nothing checks the signed receipt.
///
/// For a production launch, replace it with a [ServerReceiptValidator] that
/// forwards the receipt to a backend you control. The backend re-checks the
/// receipt against the store:
///  - Google Play: `purchases.products.get` via the Play Developer API using a
///    service account.
///  - App Store: the App Store Server API (or the legacy `verifyReceipt`).
/// Only the backend's verdict should be trusted. Swap the implementation in
/// one place ([PurchaseService]) — no other code needs to change.
abstract class ReceiptValidator {
  /// Returns true when the purchase should grant its entitlement.
  Future<bool> isValid(PurchaseDetails purchase);
}

/// Trusts the store-reported purchase status without an independent check.
///
/// Only [PurchaseStatus.purchased] and [PurchaseStatus.restored] are honoured.
class LocalReceiptValidator implements ReceiptValidator {
  const LocalReceiptValidator();

  @override
  Future<bool> isValid(PurchaseDetails purchase) async {
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }
}

/// Skeleton for backend-backed validation. Wire this up before shipping paid
/// entitlements to real users.
///
/// Example wiring in [PurchaseService]:
/// ```dart
/// PurchaseService._()
///     : _validator = ServerReceiptValidator(
///         endpoint: Uri.parse('https://api.example.com/iap/verify'),
///       );
/// ```
class ServerReceiptValidator implements ReceiptValidator {
  const ServerReceiptValidator({required this.endpoint});

  final Uri endpoint;

  @override
  Future<bool> isValid(PurchaseDetails purchase) async {
    // TODO(backend): POST the fields below to [endpoint] over HTTPS and return
    // the server's verdict. Do NOT trust the local status here.
    //   - purchase.productID
    //   - purchase.verificationData.serverVerificationData (the signed receipt)
    //   - purchase.verificationData.source ('google_play' or 'app_store')
    // The server verifies the receipt with the store and responds with a
    // simple allow/deny. Fail closed (return false) on network or parse errors.
    debugPrint(
      'ServerReceiptValidator is not implemented; refusing to grant '
      'entitlement for ${purchase.productID}. Wire up a backend before launch.',
    );
    return false;
  }
}
