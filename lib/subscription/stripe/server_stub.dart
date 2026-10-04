import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import '../../utils/constant.dart';
import '../../utils/utils.dart';

/// Only for demo purposes!
/// Don't you dare do it in real apps!
class Server {
  Future<String> createCheckout() async {
    final auth = 'Basic ${base64Encode(utf8.encode('${Constant.secretKey}:'))}';
    final body = {
      'payment_method_types': ['card'],
      'line_items': [
        {
          'price': Constant.packagePriceId ?? '',
          'quantity': 1,
        }
      ],
      'mode': Constant.paymentMode ?? '',
      'success_url': Constant.successURL ?? '',
      'cancel_url': Constant.cancelURL ?? '',
    };

    try {
      final result = await Dio().post(
        "https://api.stripe.com/v1/checkout/sessions",
        data: body,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: auth},
          contentType: "application/x-www-form-urlencoded",
        ),
      );
      printLog("sessionsId =====> ${result.data['id']}");
      return result.data['id'];
      // ignore: deprecated_member_use
    } on DioError catch (e) {
      printLog("e.response =====> ${e.response}");
      rethrow;
    }
  }
}
