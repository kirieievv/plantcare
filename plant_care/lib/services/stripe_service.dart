import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles Stripe web payment integration.
/// Only used on web — never imported on iOS/Android.
class StripeService {
  /// Calls the `createStripeCheckout` Cloud Function and returns the
  /// Stripe Checkout session URL to redirect the user to.
  static Future<String> createCheckoutUrl({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final callable = FirebaseFunctions.instance.httpsCallable(
      'createStripeCheckout',
    );

    final result = await callable.call<Map<dynamic, dynamic>>({
      'priceId': priceId,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
      if (uid != null) 'uid': uid,
    });

    final url = result.data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('No checkout URL returned from server');
    }
    return url;
  }
}
