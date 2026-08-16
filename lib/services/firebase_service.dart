import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase telemetry without preventing the game from launching
/// when platform configuration files have not yet been supplied.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  FirebaseAnalyticsObserver? _analyticsObserver;

  FirebaseAnalyticsObserver? get analyticsObserver => _analyticsObserver;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _analyticsObserver = FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
        return true;
      };
    } on FirebaseException catch (error) {
      debugPrint(
        'Firebase telemetry is disabled until platform configuration is added: '
        '${error.code}',
      );
    }
  }
}
