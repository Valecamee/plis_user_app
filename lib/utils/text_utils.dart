// lib/utils/text_utils.dart

/// Utilidades para manipulación y normalización de texto
class TextUtils {
  /// Normaliza un texto para búsquedas flexibles:
  /// - Convierte a minúsculas
  /// - Elimina tildes y acentos
  /// - Elimina espacios al inicio y final
  /// 
  /// Ejemplo:
  /// ```dart
  /// normalizeText("  Bogotá ")  // "bogota"
  /// normalizeText("MEDELLÍN")   // "medellin"
  /// normalizeText("Cali")       // "cali"
  /// ```
  static String normalizeText(String text) {
    // Eliminar espacios al inicio y final
    String normalized = text.trim();
    
    // Convertir a minúsculas
    normalized = normalized.toLowerCase();
    
    // Mapeo de caracteres con tildes a sin tildes
    const Map<String, String> accentMap = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    
    // Reemplazar cada carácter con tilde por su equivalente sin tilde
    accentMap.forEach((accented, plain) {
      normalized = normalized.replaceAll(accented, plain);
    });
    
    return normalized;
  }

  /// Verifica si un texto contiene otro de forma flexible (sin tildes, case-insensitive)
  /// 
  /// Ejemplo:
  /// ```dart
  /// containsIgnoreCaseAndAccents("Bogotá, Colombia", "bogota")  // true
  /// containsIgnoreCaseAndAccents("Medellín", "MEDE")            // true
  /// ```
  static bool containsIgnoreCaseAndAccents(String text, String search) {
    if (search.isEmpty) return true;
    return normalizeText(text).contains(normalizeText(search));
  }

  /// Verifica si dos textos son iguales de forma flexible (sin tildes, case-insensitive)
  /// 
  /// Ejemplo:
  /// ```dart
  /// equalsIgnoreCaseAndAccents("Bogotá", "bogota")  // true
  /// equalsIgnoreCaseAndAccents("CALI", "cali")      // true
  /// ```
  static bool equalsIgnoreCaseAndAccents(String text1, String text2) {
    return normalizeText(text1) == normalizeText(text2);
  }
}
