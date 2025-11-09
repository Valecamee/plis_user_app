import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/payment_constants.dart';

/// Servicio para integración con la billetera digital de conductores
/// Este servicio replica la funcionalidad del WalletService de la app de conductores
class WalletIntegrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registra un ingreso en la billetera del conductor cuando un viaje es pagado
  static Future<void> registrarIngresoViaje({
    required String conductorId,
    required String viajeId,
    required double montoTotal,
    required String pasajeroId,
    required String transaccionId,
  }) async {
    try {
      // Calcular comisión de la plataforma
      final comision = PaymentConstants.calcularComision(montoTotal);
      final montoNeto = montoTotal - comision;

      // Crear documento de transacción en la colección del conductor
      final transaccion = {
        'conductorId': conductorId,
        'viajeId': viajeId,
        'pasajeroId': pasajeroId,
        'tipo': 'ingreso_viaje',
        'monto': montoNeto,
        'montoTotal': montoTotal,
        'comision': comision,
        'estado': 'completado',
        'descripcion': 'Pago de viaje - Pasajero',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'wompiTransactionId': transaccionId,
        'metadata': {
          'payment_source': 'user_app',
          'seats_reserved': 1, // TODO: Obtener cantidad real de asientos
        },
      };

      // Ejecutar en transacción para asegurar atomicidad
      await _firestore.runTransaction((transaction) async {
        // 1. Obtener referencia del conductor
        final conductorRef = _firestore.collection('drivers').doc(conductorId);
        final conductorSnap = await transaction.get(conductorRef);

        if (!conductorSnap.exists) {
          throw Exception('Conductor no encontrado');
        }

        final conductorData = conductorSnap.data()!;

        // 2. Obtener saldos actuales
        final saldoDisponibleActual =
            (conductorData['saldoDisponible'] ?? 0.0).toDouble();
        final gananciasTotal =
            (conductorData['ganancias_totales'] ?? 0.0).toDouble();

        // 3. Calcular nuevos saldos
        final nuevoSaldoDisponible = saldoDisponibleActual + montoNeto;
        final nuevasGanancias = gananciasTotal + montoNeto;

        // 4. Actualizar saldos del conductor
        transaction.update(conductorRef, {
          'saldoDisponible': nuevoSaldoDisponible,
          'ganancias_totales': nuevasGanancias,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });

        // 5. Crear registro de transacción
        final transaccionRef = _firestore.collection('transactions').doc();
        transaccion['saldoResultante'] = nuevoSaldoDisponible;
        transaction.set(transaccionRef, transaccion);

        // 6. Actualizar estadísticas del viaje
        final viajeRef = _firestore.collection('travels').doc(viajeId);
        transaction.update(viajeRef, {
          'pagosRecibidos': FieldValue.increment(1),
          'montoTotalRecaudado': FieldValue.increment(montoTotal),
        });
      });

      debugPrint(
          '✅ [WALLET] Ingreso registrado: \$${montoNeto.toStringAsFixed(0)} para conductor $conductorId');
      debugPrint(
          '💰 [WALLET] Comisión plataforma: \$${comision.toStringAsFixed(0)}');
    } catch (e) {
      debugPrint('❌ [WALLET] Error registrando ingreso: $e');
      rethrow;
    }
  }

  /// Obtiene el saldo disponible de un conductor
  static Future<double> obtenerSaldoDisponible(String conductorId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(conductorId).get();

      if (!doc.exists) return 0.0;

      return (doc.data()?['saldoDisponible'] ?? 0.0).toDouble();
    } catch (e) {
      debugPrint('❌ [WALLET] Error obteniendo saldo: $e');
      return 0.0;
    }
  }

  /// Obtiene las ganancias totales de un conductor
  static Future<double> obtenerGananciasTotales(String conductorId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(conductorId).get();

      if (!doc.exists) return 0.0;

      return (doc.data()?['ganancias_totales'] ?? 0.0).toDouble();
    } catch (e) {
      debugPrint('❌ [WALLET] Error obteniendo ganancias: $e');
      return 0.0;
    }
  }

  /// Obtiene el historial de transacciones de un conductor
  static Stream<List<Map<String, dynamic>>> obtenerHistorialTransacciones(
    String conductorId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('transactions')
        .where('conductorId', isEqualTo: conductorId)
        .orderBy('fechaCreacion', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Verifica si un conductor tiene suficiente saldo para un retiro
  static Future<bool> tieneSaldoSuficiente(
    String conductorId,
    double monto,
  ) async {
    final saldo = await obtenerSaldoDisponible(conductorId);
    return saldo >= monto && monto >= PaymentConstants.montoMinimoRetiro;
  }

  /// Obtiene estadísticas de ingresos de un viaje específico
  static Future<Map<String, dynamic>> obtenerEstadisticasViaje(
    String viajeId,
  ) async {
    try {
      // Obtener todas las transacciones de este viaje
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('viajeId', isEqualTo: viajeId)
          .where('tipo', isEqualTo: 'ingreso_viaje')
          .get();

      double totalRecaudado = 0.0;
      double totalComisiones = 0.0;
      int totalPasajeros = querySnapshot.docs.length;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        totalRecaudado += (data['montoTotal'] ?? 0.0).toDouble();
        totalComisiones += (data['comision'] ?? 0.0).toDouble();
      }

      return {
        'totalPasajeros': totalPasajeros,
        'totalRecaudado': totalRecaudado,
        'totalComisiones': totalComisiones,
        'totalNeto': totalRecaudado - totalComisiones,
      };
    } catch (e) {
      debugPrint('❌ [WALLET] Error obteniendo estadísticas: $e');
      return {
        'totalPasajeros': 0,
        'totalRecaudado': 0.0,
        'totalComisiones': 0.0,
        'totalNeto': 0.0,
      };
    }
  }

  /// Verifica si existe la billetera del conductor (documento en drivers)
  static Future<bool> existeBilleteraConductor(String conductorId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(conductorId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Crea la estructura de billetera para un conductor si no existe
  static Future<void> inicializarBilletera(String conductorId) async {
    try {
      final conductorRef = _firestore.collection('drivers').doc(conductorId);
      final doc = await conductorRef.get();

      if (!doc.exists) {
        // Crear documento básico de conductor
        await conductorRef.set({
          'saldoDisponible': 0.0,
          'saldoBloqueado': 0.0,
          'saldoRetirado': 0.0,
          'ganancias_totales': 0.0,
          'fechaCreacion': FieldValue.serverTimestamp(),
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [WALLET] Billetera inicializada para $conductorId');
      } else {
        // Asegurar que tiene los campos necesarios
        final data = doc.data()!;
        final updates = <String, dynamic>{};

        if (!data.containsKey('saldoDisponible')) {
          updates['saldoDisponible'] = 0.0;
        }
        if (!data.containsKey('ganancias_totales')) {
          updates['ganancias_totales'] = 0.0;
        }

        if (updates.isNotEmpty) {
          await conductorRef.update(updates);
        }
      }
    } catch (e) {
      debugPrint('❌ [WALLET] Error inicializando billetera: $e');
      rethrow;
    }
  }

  /// Bloquea un monto del saldo disponible (para retiros pendientes)
  static Future<void> bloquearSaldo(
    String conductorId,
    double monto,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final conductorRef = _firestore.collection('drivers').doc(conductorId);
        final conductorSnap = await transaction.get(conductorRef);

        if (!conductorSnap.exists) {
          throw Exception('Conductor no encontrado');
        }

        final data = conductorSnap.data()!;
        final saldoDisponible = (data['saldoDisponible'] ?? 0.0).toDouble();
        final saldoBloqueado = (data['saldoBloqueado'] ?? 0.0).toDouble();

        if (saldoDisponible < monto) {
          throw Exception('Saldo insuficiente');
        }

        transaction.update(conductorRef, {
          'saldoDisponible': saldoDisponible - monto,
          'saldoBloqueado': saldoBloqueado + monto,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('🔒 [WALLET] Saldo bloqueado: \$${monto.toStringAsFixed(0)}');
    } catch (e) {
      debugPrint('❌ [WALLET] Error bloqueando saldo: $e');
      rethrow;
    }
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
