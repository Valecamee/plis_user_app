import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/payment_constants.dart';

/// Servicio para integración con la API de Wompi
class WompiService {
  // Credenciales de Wompi (se cargan desde .env)
  static String get publicKey {
    final key = PaymentConstants.isSandbox
        ? dotenv.env['WOMPI_PUBLIC_KEY_TEST']
        : dotenv.env['WOMPI_PUBLIC_KEY_PROD'];
    return key ?? '';
  }

  static String get privateKey {
    final key = PaymentConstants.isSandbox
        ? dotenv.env['WOMPI_PRIVATE_KEY_TEST']
        : dotenv.env['WOMPI_PRIVATE_KEY_PROD'];
    return key ?? '';
  }

  /// Tokeniza una tarjeta de crédito
  /// Retorna el token de la tarjeta para uso en transacciones
  static Future<Map<String, dynamic>> tokenizeCard({
    required String cardNumber,
    required String cvc,
    required String expMonth,
    required String expYear,
    required String cardHolder,
  }) async {
    try {
      print('🔐 [WOMPI] Tokenizando tarjeta...');

      final url = Uri.parse(
        '${PaymentConstants.baseUrl}${PaymentConstants.tokenizationEndpoint}',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $publicKey',
            },
            body: jsonEncode({
              'number': cardNumber.replaceAll(' ', ''),
              'cvc': cvc,
              'exp_month': expMonth,
              'exp_year': expYear.length == 2 ? '20$expYear' : expYear,
              'card_holder': cardHolder,
            }),
          )
          .timeout(PaymentConstants.httpTimeout);

      print('📡 [WOMPI] Response status: ${response.statusCode}');
      print('📡 [WOMPI] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ [WOMPI] Tarjeta tokenizada exitosamente');
        return {
          'success': true,
          'token': data['data']['id'],
          'data': data['data'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('❌ [WOMPI] Error tokenizando tarjeta: $error');
        return {
          'success': false,
          'error': error['error']?['reason'] ?? 'Error tokenizando tarjeta',
        };
      }
    } catch (e) {
      print('❌ [WOMPI] Exception tokenizando tarjeta: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Crea una transacción de pago
  static Future<Map<String, dynamic>> createTransaction({
    required double amountInCents,
    required String currency,
    required String paymentSourceId,
    required String customerEmail,
    required String reference,
    Map<String, dynamic>? customerData,
    Map<String, dynamic>? shippingAddress,
  }) async {
    try {
      print('💳 [WOMPI] Creando transacción...');
      print('💳 [WOMPI] Monto: $amountInCents centavos');
      print('💳 [WOMPI] Referencia: $reference');

      final url = Uri.parse(
        '${PaymentConstants.baseUrl}${PaymentConstants.transactionsEndpoint}',
      );

      final body = {
        'amount_in_cents': amountInCents.toInt(),
        'currency': currency,
        'customer_email': customerEmail,
        'payment_method': {
          'installments': 1,
        },
        'reference': reference,
        'payment_source_id': paymentSourceId,
      };

      if (customerData != null) {
        body['customer_data'] = customerData;
      }

      if (shippingAddress != null) {
        body['shipping_address'] = shippingAddress;
      }

      print('📤 [WOMPI] Request body: ${jsonEncode(body)}');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $privateKey',
            },
            body: jsonEncode(body),
          )
          .timeout(PaymentConstants.httpTimeout);

      print('📡 [WOMPI] Response status: ${response.statusCode}');
      print('📡 [WOMPI] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ [WOMPI] Transacción creada exitosamente');
        return {
          'success': true,
          'transaction': data['data'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('❌ [WOMPI] Error creando transacción: $error');
        return {
          'success': false,
          'error': error['error']?['reason'] ?? 'Error creando transacción',
        };
      }
    } catch (e) {
      print('❌ [WOMPI] Exception creando transacción: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Crea un payment source (fuente de pago) a partir de un token
  static Future<Map<String, dynamic>> createPaymentSource({
    required String token,
    required String customerEmail,
    required String acceptanceToken,
  }) async {
    try {
      print('🔗 [WOMPI] Creando payment source...');

      final url = Uri.parse(
        '${PaymentConstants.baseUrl}${PaymentConstants.paymentSourcesEndpoint}',
      );

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $privateKey',
            },
            body: jsonEncode({
              'type': 'CARD',
              'token': token,
              'customer_email': customerEmail,
              'acceptance_token': acceptanceToken,
            }),
          )
          .timeout(PaymentConstants.httpTimeout);

      print('📡 [WOMPI] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ [WOMPI] Payment source creado exitosamente');
        return {
          'success': true,
          'payment_source': data['data'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('❌ [WOMPI] Error creando payment source: $error');
        return {
          'success': false,
          'error': error['error']?['reason'] ?? 'Error creando payment source',
        };
      }
    } catch (e) {
      print('❌ [WOMPI] Exception creando payment source: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Obtiene el acceptance token del comercio
  static Future<Map<String, dynamic>> getAcceptanceToken() async {
    try {
      print('📋 [WOMPI] Obteniendo acceptance token...');

      final url = Uri.parse(
        '${PaymentConstants.baseUrl}${PaymentConstants.acceptanceTokenEndpoint}/$publicKey',
      );

      final response = await http.get(url).timeout(PaymentConstants.httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [WOMPI] Acceptance token obtenido');
        return {
          'success': true,
          'acceptance_token':
              data['data']['presigned_acceptance']['acceptance_token'],
          'permalink': data['data']['presigned_acceptance']['permalink'],
        };
      } else {
        print('❌ [WOMPI] Error obteniendo acceptance token');
        return {
          'success': false,
          'error': 'No se pudo obtener el acceptance token',
        };
      }
    } catch (e) {
      print('❌ [WOMPI] Exception obteniendo acceptance token: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Consulta el estado de una transacción
  static Future<Map<String, dynamic>> getTransactionStatus(
      String transactionId) async {
    try {
      print('🔍 [WOMPI] Consultando estado de transacción: $transactionId');

      final url = Uri.parse(
        '${PaymentConstants.baseUrl}${PaymentConstants.transactionsEndpoint}/$transactionId',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $publicKey',
            },
          )
          .timeout(PaymentConstants.httpTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [WOMPI] Estado obtenido: ${data['data']['status']}');
        return {
          'success': true,
          'transaction': data['data'],
        };
      } else {
        print('❌ [WOMPI] Error consultando transacción');
        return {
          'success': false,
          'error': 'No se pudo consultar la transacción',
        };
      }
    } catch (e) {
      print('❌ [WOMPI] Exception consultando transacción: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  /// Realiza un pago completo (tokeniza + crea payment source + crea transacción)
  static Future<Map<String, dynamic>> processCardPayment({
    required String cardNumber,
    required String cvc,
    required String expMonth,
    required String expYear,
    required String cardHolder,
    required double amount,
    required String customerEmail,
    required String reference,
    Map<String, dynamic>? customerData,
  }) async {
    try {
      print('💰 [WOMPI] Iniciando proceso de pago completo...');

      // 1. Obtener acceptance token
      final acceptanceResult = await getAcceptanceToken();
      if (!acceptanceResult['success']) {
        return acceptanceResult;
      }

      final acceptanceToken = acceptanceResult['acceptance_token'];

      // 2. Tokenizar tarjeta
      final tokenResult = await tokenizeCard(
        cardNumber: cardNumber,
        cvc: cvc,
        expMonth: expMonth,
        expYear: expYear,
        cardHolder: cardHolder,
      );

      if (!tokenResult['success']) {
        return tokenResult;
      }

      final cardToken = tokenResult['token'];

      // 3. Crear payment source
      final paymentSourceResult = await createPaymentSource(
        token: cardToken,
        customerEmail: customerEmail,
        acceptanceToken: acceptanceToken,
      );

      if (!paymentSourceResult['success']) {
        return paymentSourceResult;
      }

      final paymentSourceId = paymentSourceResult['payment_source']['id'];

      // 4. Crear transacción
      final transactionResult = await createTransaction(
        amountInCents: amount * 100, // Convertir a centavos
        currency: PaymentConstants.currency,
        paymentSourceId: paymentSourceId,
        customerEmail: customerEmail,
        reference: reference,
        customerData: customerData,
      );

      return transactionResult;
    } catch (e) {
      print('❌ [WOMPI] Exception en proceso de pago: $e');
      return {
        'success': false,
        'error': 'Error procesando el pago: $e',
      };
    }
  }

  /// Verifica si las credenciales están configuradas
  static bool areCredentialsConfigured() {
    return publicKey.isNotEmpty && privateKey.isNotEmpty;
  }

  /// Obtiene mensaje de error amigable
  static String getFriendlyErrorMessage(String error) {
    return PaymentConstants.errorMessages[error] ?? error;
  }
}
