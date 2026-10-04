import 'dart:js_interop';
import 'package:flutter/material.dart';
import '../../utils/constant.dart';

@JS('Stripe')
extension type Stripe._(JSObject _) implements JSObject {
  external Stripe(String key);

  external JSPromise redirectToCheckout(CheckoutOptions options);
}

@JS()
extension type CheckoutOptions._(JSObject _) implements JSObject {
  external factory CheckoutOptions({
    JSArray<LineItem> lineItems,
    String mode,
    String successUrl,
    String cancelUrl,
  });
}

@JS()
extension type LineItem._(JSObject _) implements JSObject {
  external factory LineItem({
    String price,
    int quantity,
  });
}

void redirectToCheckout(BuildContext context) async {
  final stripe = Stripe(Constant.publishableKey ?? "");

  final lineItems = [
    LineItem(
      price: Constant.packagePriceId ?? '',
      quantity: 1,
    )
  ].toJS;

  final options = CheckoutOptions(
    lineItems: lineItems,
    mode: Constant.paymentMode ?? 'payment',
    successUrl: Constant.successURL ?? '',
    cancelUrl: Constant.cancelURL ?? '',
  );

  try {
    await stripe.redirectToCheckout(options).toDart;
  } catch (e) {
    debugPrint("Stripe Redirect Error: $e");
  }
}
