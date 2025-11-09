/// Validadores para datos de pago
class PaymentValidators {
  /// Valida un número de tarjeta de crédito usando el algoritmo de Luhn
  static bool validateCardNumber(String cardNumber) {
    if (cardNumber.isEmpty) return false;

    // Remover espacios y guiones
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    // Verificar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;

    // Verificar longitud (13-19 dígitos)
    if (cleaned.length < 13 || cleaned.length > 19) return false;

    // Algoritmo de Luhn
    int sum = 0;
    bool alternate = false;

    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Valida el código CVV/CVC
  static bool validateCVV(String cvv, {int length = 3}) {
    if (cvv.isEmpty) return false;

    // Verificar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(cvv)) return false;

    // Verificar longitud (3 o 4 dígitos)
    return cvv.length == length;
  }

  /// Valida el mes de expiración
  static bool validateExpiryMonth(String month) {
    if (month.isEmpty) return false;

    final monthInt = int.tryParse(month);
    if (monthInt == null) return false;

    return monthInt >= 1 && monthInt <= 12;
  }

  /// Valida el año de expiración
  static bool validateExpiryYear(String year) {
    if (year.isEmpty) return false;

    final yearInt = int.tryParse(year);
    if (yearInt == null) return false;

    final currentYear = DateTime.now().year;

    // Aceptar formato de 2 o 4 dígitos
    if (year.length == 2) {
      final fullYear = 2000 + yearInt;
      return fullYear >= currentYear && fullYear <= currentYear + 20;
    } else if (year.length == 4) {
      return yearInt >= currentYear && yearInt <= currentYear + 20;
    }

    return false;
  }

  /// Valida la fecha de expiración completa
  static bool validateExpiryDate(String month, String year) {
    if (!validateExpiryMonth(month) || !validateExpiryYear(year)) {
      return false;
    }

    final monthInt = int.parse(month);
    var yearInt = int.parse(year);

    // Convertir año de 2 dígitos a 4
    if (year.length == 2) {
      yearInt = 2000 + yearInt;
    }

    final now = DateTime.now();
    final expiryDate = DateTime(yearInt, monthInt + 1, 0); // Último día del mes

    return expiryDate.isAfter(now);
  }

  /// Valida el nombre del titular de la tarjeta
  static bool validateCardHolder(String name) {
    if (name.isEmpty) return false;

    // Mínimo 3 caracteres
    if (name.trim().length < 3) return false;

    // Solo letras y espacios
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name)) return false;

    return true;
  }

  /// Valida un email
  static bool validateEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email);
  }

  /// Valida un número de teléfono colombiano
  static bool validatePhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    // Remover espacios y caracteres especiales
    final cleaned = phone.replaceAll(RegExp(r'[\s()-]'), '');

    // Verificar que solo contenga dígitos y símbolo +
    if (!RegExp(r'^[\d+]+$').hasMatch(cleaned)) return false;

    // Validar formatos colombianos
    // Celular: 10 dígitos (3XX XXXXXXX)
    // Con código país: +57 3XX XXXXXXX
    if (cleaned.length == 10 && cleaned.startsWith('3')) {
      return true;
    }

    if (cleaned.startsWith('+57') && cleaned.length == 13) {
      return cleaned.substring(3).startsWith('3');
    }

    return false;
  }

  /// Valida un número de documento
  static bool validateDocument(String document) {
    if (document.isEmpty) return false;

    // Remover espacios y puntos
    final cleaned = document.replaceAll(RegExp(r'[\s.]'), '');

    // Verificar que solo contenga dígitos
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;

    // Longitud mínima y máxima
    return cleaned.length >= 6 && cleaned.length <= 15;
  }

  /// Obtiene el tipo de tarjeta basado en el número
  static String getCardType(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.isEmpty) return 'unknown';

    // Visa
    if (cleaned.startsWith('4')) {
      return 'visa';
    }

    // Mastercard
    if (RegExp(r'^5[1-5]').hasMatch(cleaned) ||
        RegExp(r'^2[2-7]').hasMatch(cleaned)) {
      return 'mastercard';
    }

    // American Express
    if (cleaned.startsWith('34') || cleaned.startsWith('37')) {
      return 'amex';
    }

    // Diners Club
    if (cleaned.startsWith('36') || cleaned.startsWith('38')) {
      return 'diners';
    }

    // Discover
    if (cleaned.startsWith('6011') || cleaned.startsWith('65')) {
      return 'discover';
    }

    return 'unknown';
  }

  /// Formatea un número de tarjeta con espacios
  static String formatCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }

    return buffer.toString();
  }

  /// Formatea una fecha de expiración (MM/YY)
  static String formatExpiryDate(String month, String year) {
    final m = month.padLeft(2, '0');
    final y = year.length > 2 ? year.substring(2) : year;
    return '$m/$y';
  }

  /// Enmascara un número de tarjeta mostrando solo los últimos 4 dígitos
  static String maskCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.length < 4) return cardNumber;

    final last4 = cleaned.substring(cleaned.length - 4);
    return '**** **** **** $last4';
  }

  /// Valida un monto de pago
  static bool validateAmount(double amount, {double minAmount = 1000}) {
    return amount >= minAmount;
  }

  /// Mensaje de error personalizado para validación de tarjeta
  static String? getCardNumberError(String cardNumber) {
    if (cardNumber.isEmpty) {
      return 'Ingresa el número de tarjeta';
    }

    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.length < 13) {
      return 'Número de tarjeta incompleto';
    }

    if (!validateCardNumber(cardNumber)) {
      return 'Número de tarjeta inválido';
    }

    return null;
  }

  /// Mensaje de error para CVV
  static String? getCVVError(String cvv) {
    if (cvv.isEmpty) {
      return 'Ingresa el CVV';
    }

    if (!validateCVV(cvv)) {
      return 'CVV inválido';
    }

    return null;
  }

  /// Mensaje de error para fecha de expiración
  static String? getExpiryDateError(String month, String year) {
    if (month.isEmpty || year.isEmpty) {
      return 'Ingresa la fecha de vencimiento';
    }

    if (!validateExpiryDate(month, year)) {
      return 'Fecha de vencimiento inválida o expirada';
    }

    return null;
  }

  /// Mensaje de error para titular
  static String? getCardHolderError(String name) {
    if (name.isEmpty) {
      return 'Ingresa el nombre del titular';
    }

    if (!validateCardHolder(name)) {
      return 'Nombre inválido';
    }

    return null;
  }
}
