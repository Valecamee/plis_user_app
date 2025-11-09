// lib/utils/keyboard_utils.dart
import 'package:flutter/material.dart';

/// Utilidad para manejar el teclado y prevenir overflow
class KeyboardUtils {
  /// Tiempo estándar de espera para transiciones del teclado (en milisegundos)
  static const int defaultDelay = 150;

  /// Oculta el teclado de forma segura con un delay opcional
  /// 
  /// [context] - BuildContext actual
  /// [delayMs] - Milisegundos de espera antes de ocultar (por defecto 150ms)
  static void hideKeyboard(BuildContext context, {int delayMs = defaultDelay}) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// Oculta el teclado y ejecuta una acción después del delay
  /// Útil para cambiar de estado mientras se oculta el teclado
  /// 
  /// [context] - BuildContext actual
  /// [onComplete] - Callback a ejecutar después del delay
  /// [delayMs] - Milisegundos de espera (por defecto 150ms)
  static Future<void> hideKeyboardAndThen(
    BuildContext context,
    VoidCallback onComplete, {
    int delayMs = defaultDelay,
  }) async {
    hideKeyboard(context);
    await Future.delayed(Duration(milliseconds: delayMs));
    onComplete();
  }

  /// Alterna el estado de un widget (por ejemplo, mostrar/ocultar filtros)
  /// mientras oculta el teclado de forma segura
  /// 
  /// [context] - BuildContext actual
  /// [currentState] - Estado actual del toggle
  /// [onToggle] - Callback para cambiar el estado
  /// [delayMs] - Milisegundos de espera (por defecto 150ms)
  static Future<void> toggleWithKeyboard(
    BuildContext context,
    bool currentState,
    Function(bool) onToggle, {
    int delayMs = defaultDelay,
  }) async {
    // Si se va a mostrar, primero ocultar el teclado
    if (!currentState) {
      hideKeyboard(context);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    onToggle(!currentState);
  }

  /// Verifica si el teclado está visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Obtiene la altura del teclado
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Desenfoca cualquier campo de texto activo
  static void unfocusAll(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Enfoca un campo específico con delay opcional
  /// 
  /// [focusNode] - FocusNode del campo a enfocar
  /// [delayMs] - Milisegundos de espera antes de enfocar
  static Future<void> focusWithDelay(
    FocusNode focusNode, {
    int delayMs = defaultDelay,
  }) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    focusNode.requestFocus();
  }

  /// Cambia el foco de un campo a otro de forma segura
  /// 
  /// [context] - BuildContext actual
  /// [currentFocus] - FocusNode actual
  /// [nextFocus] - FocusNode destino
  /// [delayMs] - Milisegundos de espera entre desenfocar y enfocar
  static Future<void> changeFocus(
    BuildContext context,
    FocusNode? currentFocus,
    FocusNode nextFocus, {
    int delayMs = defaultDelay,
  }) async {
    currentFocus?.unfocus();
    await Future.delayed(Duration(milliseconds: delayMs));
    nextFocus.requestFocus();
  }
}
