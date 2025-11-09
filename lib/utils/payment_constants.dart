/// Constantes y configuración para el sistema de pagos con Wompi
class PaymentConstants {
  // URLs de la API de Wompi
  static const String wompiBaseUrlProduction = 'https://production.wompi.co/v1';
  static const String wompiBaseUrlSandbox = 'https://sandbox.wompi.co/v1';

  // Determinar si estamos en modo sandbox o producción
  static const bool isSandbox = true; // Cambiar a false en producción

  // URL base según el entorno
  static String get baseUrl => isSandbox ? wompiBaseUrlSandbox : wompiBaseUrlProduction;

  // Endpoints de Wompi
  static const String transactionsEndpoint = '/transactions';
  static const String tokenizationEndpoint = '/tokens/cards';
  static const String acceptanceTokenEndpoint = '/merchants';
  static const String paymentSourcesEndpoint = '/payment_sources';

  // Configuración de comisiones (heredado de la app de conductores)
  static const double comisionPlataformaPorcentaje = 10.0; // 10%
  static const double comisionMinima = 500.0; // $500 COP
  static const double montoMinimoRetiro = 10000.0; // $10,000 COP

  // Moneda
  static const String currency = 'COP';

  // Timeout para requests HTTP
  static const Duration httpTimeout = Duration(seconds: 30);

  // Métodos de pago habilitados
  static const List<String> enabledPaymentMethods = [
    'CARD',
    'PSE',
    'NEQUI',
    'BANCOLOMBIA_TRANSFER',
  ];

  // Tarjetas de prueba para Sandbox
  static const Map<String, dynamic> testCards = {
    'visa_approved': {
      'number': '4242424242424242',
      'cvc': '123',
      'exp_month': '12',
      'exp_year': '29',
      'card_holder': 'APPROVED',
    },
    'visa_declined': {
      'number': '4111111111111111',
      'cvc': '123',
      'exp_month': '12',
      'exp_year': '29',
      'card_holder': 'DECLINED',
    },
    'mastercard_approved': {
      'number': '5555555555554444',
      'cvc': '123',
      'exp_month': '12',
      'exp_year': '29',
      'card_holder': 'APPROVED',
    },
  };

  // Mensajes de error comunes
  static const Map<String, String> errorMessages = {
    'DECLINED': 'Transacción rechazada por el banco',
    'VOIDED': 'Transacción anulada',
    'ERROR': 'Error en la transacción',
    'PENDING': 'Transacción pendiente de confirmación',
    'insufficient_funds': 'Fondos insuficientes',
    'invalid_card': 'Tarjeta inválida',
    'expired_card': 'Tarjeta vencida',
    'invalid_cvc': 'Código de seguridad inválido',
    'processing_error': 'Error procesando el pago',
    'network_error': 'Error de conexión. Verifica tu internet.',
  };

  // Estados de transacción de Wompi
  static const String statusApproved = 'APPROVED';
  static const String statusDeclined = 'DECLINED';
  static const String statusVoided = 'VOIDED';
  static const String statusError = 'ERROR';
  static const String statusPending = 'PENDING';

  // Tipos de documentos válidos
  static const List<String> validDocumentTypes = [
    'CC', // Cédula de ciudadanía
    'CE', // Cédula de extranjería
    'NIT', // Número de identificación tributaria
    'PP', // Pasaporte
  ];

  // Información para redirección
  static const String redirectUrlPlaceholder = 'https://tu-app.com/payment-result';

  /// Calcula la comisión de la plataforma
  static double calcularComision(double montoTotal) {
    final comision = montoTotal * (comisionPlataformaPorcentaje / 100);
    return comision < comisionMinima ? comisionMinima : comision;
  }

  /// Calcula el monto que recibe el conductor después de comisión
  static double calcularMontoParaConductor(double montoTotal) {
    return montoTotal - calcularComision(montoTotal);
  }

  /// Formatea un monto como moneda colombiana
  static String formatearMonto(double monto) {
    final montoInt = monto.toInt();
    final montoStr = montoInt.toString();
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return '\$${montoStr.replaceAllMapped(regex, (Match m) => '${m[1]},')}';
  }

  /// Convierte centavos a pesos (Wompi usa centavos en algunos casos)
  static double centavosToPesos(int centavos) {
    return centavos / 100;
  }

  /// Convierte pesos a centavos
  static int pesosToCentavos(double pesos) {
    return (pesos * 100).round();
  }
}
