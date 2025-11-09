import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_model.dart';
import '../models/travel_model.dart';
import 'wompi_service.dart';
import 'wallet_integration_service.dart';

/// Servicio para gestión de pagos
class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Inicia un proceso de pago
  static Future<PaymentModel> initializePayment({
    required String passengerId,
    required String travelId,
    required double amount,
    required int seatsReserved,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final transactionId = 'TXN_${_uuid.v4().substring(0, 8).toUpperCase()}';

      final payment = PaymentModel(
        transactionId: transactionId,
        passengerId: passengerId,
        travelId: travelId,
        amount: amount,
        status: PaymentStatus.pending,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        seatsReserved: seatsReserved,
      );

      // Guardar en Firestore
      final docRef = await _firestore.collection('payments').add(payment.toMap());

      return payment.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Error inicializando pago: $e');
    }
  }

  /// Procesa un pago con tarjeta
  static Future<Map<String, dynamic>> processCardPayment({
    required PaymentModel payment,
    required String cardNumber,
    required String cvc,
    required String expMonth,
    required String expYear,
    required String cardHolder,
    required String customerEmail,
    required Travel travel,
  }) async {
    try {
      // Actualizar estado a procesando
      await updatePaymentStatus(
        paymentId: payment.id!,
        status: PaymentStatus.processing,
      );

      // Procesar con Wompi
      final wompiResult = await WompiService.processCardPayment(
        cardNumber: cardNumber,
        cvc: cvc,
        expMonth: expMonth,
        expYear: expYear,
        cardHolder: cardHolder,
        amount: payment.amount,
        customerEmail: customerEmail,
        reference: payment.transactionId,
        customerData: {
          'phone_number': '+573001234567', // TODO: Obtener del usuario
          'full_name': cardHolder,
        },
      );

      if (wompiResult['success']) {
        final transaction = wompiResult['transaction'];
        final wompiStatus = transaction['status'];

        // Mapear estado de Wompi a nuestro sistema
        PaymentStatus newStatus;
        if (wompiStatus == 'APPROVED') {
          newStatus = PaymentStatus.completed;
        } else if (wompiStatus == 'DECLINED' || wompiStatus == 'VOIDED') {
          newStatus = PaymentStatus.failed;
        } else {
          newStatus = PaymentStatus.processing;
        }

        // Actualizar pago con información de Wompi
        await _firestore.collection('payments').doc(payment.id).update({
          'status': newStatus.name,
          'wompiTransactionId': transaction['id'],
          'wompiReference': transaction['reference'],
          'updatedAt': FieldValue.serverTimestamp(),
          'completedAt': newStatus == PaymentStatus.completed
              ? FieldValue.serverTimestamp()
              : null,
          'metadata': {
            'wompi_status': wompiStatus,
            'payment_method_type': transaction['payment_method_type'],
            'currency': transaction['currency'],
          },
        });

        // Si el pago fue exitoso, registrar en billetera del conductor
        if (newStatus == PaymentStatus.completed) {
          await _handleSuccessfulPayment(
            payment: payment,
            travel: travel,
            wompiTransactionId: transaction['id'],
          );
        }

        return {
          'success': newStatus == PaymentStatus.completed,
          'status': newStatus,
          'transaction': transaction,
          'message': _getStatusMessage(wompiStatus),
        };
      } else {
        // Error en Wompi
        await updatePaymentStatus(
          paymentId: payment.id!,
          status: PaymentStatus.failed,
          errorMessage: wompiResult['error'],
        );

        return {
          'success': false,
          'status': PaymentStatus.failed,
          'error': wompiResult['error'],
          'message': WompiService.getFriendlyErrorMessage(wompiResult['error']),
        };
      }
    } catch (e) {
      await updatePaymentStatus(
        paymentId: payment.id!,
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );

      return {
        'success': false,
        'status': PaymentStatus.failed,
        'error': e.toString(),
        'message': 'Error procesando el pago',
      };
    }
  }

  /// Maneja un pago exitoso (registra en billetera, actualiza viaje, etc.)
  static Future<void> _handleSuccessfulPayment({
    required PaymentModel payment,
    required Travel travel,
    required String wompiTransactionId,
  }) async {
    try {
      // 1. Registrar ingreso en billetera del conductor
      await WalletIntegrationService.registrarIngresoViaje(
        conductorId: travel.conductorId,
        viajeId: payment.travelId,
        montoTotal: payment.amount,
        pasajeroId: payment.passengerId,
        transaccionId: wompiTransactionId,
      );

      // 2. Actualizar documento del viaje con información de pago
      await _firestore.collection('travels').doc(payment.travelId).update({
        'pagos': FieldValue.arrayUnion([
          {
            'paymentId': payment.id,
            'passengerId': payment.passengerId,
            'amount': payment.amount,
            'completedAt': FieldValue.serverTimestamp(),
          }
        ]),
      });

      // 3. Crear notificación para el conductor (opcional)
      // TODO: Implementar sistema de notificaciones
    } catch (e) {
      // Log error pero no fallar el proceso
      // El pago ya fue exitoso, esto es solo metadata adicional
      debugPrint('⚠️ Error en post-procesamiento de pago: $e');
    }
  }

  /// Actualiza el estado de un pago
  static Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? errorMessage,
    String? wompiTransactionId,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (errorMessage != null) {
      updateData['errorMessage'] = errorMessage;
    }

    if (wompiTransactionId != null) {
      updateData['wompiTransactionId'] = wompiTransactionId;
    }

    if (status == PaymentStatus.completed) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('payments').doc(paymentId).update(updateData);
  }

  /// Obtiene un pago por ID
  static Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();

      if (!doc.exists) return null;

      return PaymentModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error obteniendo pago: $e');
      return null;
    }
  }

  /// Obtiene el pago asociado a una reserva
  static Future<PaymentModel?> getPaymentByReservation({
    required String travelId,
    required String passengerId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('travelId', isEqualTo: travelId)
          .where('passengerId', isEqualTo: passengerId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return PaymentModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      debugPrint('Error obteniendo pago por reserva: $e');
      return null;
    }
  }

  /// Obtiene el historial de pagos de un pasajero
  static Stream<List<PaymentModel>> getPassengerPaymentsStream(
      String passengerId) {
    return _firestore
        .collection('payments')
        .where('passengerId', isEqualTo: passengerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Verifica el estado de una transacción en Wompi
  static Future<Map<String, dynamic>> verifyPaymentStatus(
      String wompiTransactionId) async {
    try {
      final result =
          await WompiService.getTransactionStatus(wompiTransactionId);

      if (result['success']) {
        final transaction = result['transaction'];
        return {
          'success': true,
          'status': transaction['status'],
          'transaction': transaction,
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Solicita un reembolso (requiere implementación en backend)
  static Future<Map<String, dynamic>> requestRefund({
    required String paymentId,
    required String reason,
  }) async {
    try {
      final payment = await getPaymentById(paymentId);

      if (payment == null) {
        return {
          'success': false,
          'error': 'Pago no encontrado',
        };
      }

      if (payment.status != PaymentStatus.completed) {
        return {
          'success': false,
          'error': 'Solo se pueden reembolsar pagos completados',
        };
      }

      // TODO: Implementar lógica de reembolso con Wompi API
      // Por ahora solo actualizar el estado en nuestra DB

      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.refunded.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata.refund_reason': reason,
        'metadata.refund_requested_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Solicitud de reembolso creada',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error solicitando reembolso: $e',
      };
    }
  }

  /// Obtiene mensaje amigable para estado de pago
  static String _getStatusMessage(String wompiStatus) {
    switch (wompiStatus) {
      case 'APPROVED':
        return '¡Pago exitoso!';
      case 'DECLINED':
        return 'Pago rechazado por el banco';
      case 'VOIDED':
        return 'Pago anulado';
      case 'ERROR':
        return 'Error en la transacción';
      case 'PENDING':
        return 'Pago pendiente de confirmación';
      default:
        return 'Estado desconocido';
    }
  }

  /// Valida si un pago puede ser procesado
  static bool canProcessPayment(PaymentModel payment) {
    return payment.status == PaymentStatus.pending ||
        payment.status == PaymentStatus.failed;
  }

  /// Cancela un pago pendiente
  static Future<void> cancelPayment(String paymentId) async {
    await updatePaymentStatus(
      paymentId: paymentId,
      status: PaymentStatus.cancelled,
    );
  }
}

// Helper para debug print que no genera warning
void debugPrint(String message) {
  // En producción usar logging framework
  // ignore: avoid_print
  print(message);
}
