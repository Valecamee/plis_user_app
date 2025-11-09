import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de un pago
enum PaymentStatus {
  pending,      // Iniciado pero no completado
  processing,   // Enviado a la pasarela
  completed,    // Pago exitoso
  failed,       // Pago rechazado
  refunded,     // Dinero devuelto
  cancelled,    // Cancelado por el usuario
}

/// Métodos de pago soportados
enum PaymentMethod {
  card,         // Tarjeta de crédito/débito
  pse,          // PSE (débito bancario Colombia)
  nequi,        // Nequi
  bancolombia,  // Bancolombia QR
  cash,         // Efectivo (Efecty, Baloto, etc.)
}

/// Modelo de datos para representar un pago
class PaymentModel {
  final String? id;                      // ID del documento en Firestore
  final String transactionId;            // ID único de la transacción
  final String passengerId;              // UID del pasajero
  final String travelId;                 // ID del viaje
  final String? reservationId;           // ID de la reserva (si existe)
  final double amount;                   // Monto total
  final PaymentStatus status;            // Estado del pago
  final PaymentMethod paymentMethod;     // Método de pago usado
  final String? wompiTransactionId;      // Referencia de Wompi
  final String? wompiReference;          // Referencia de pago
  final String? paymentUrl;              // URL de redirección (para PSE, etc.)
  final DateTime createdAt;              // Fecha de creación
  final DateTime? updatedAt;             // Fecha de actualización
  final DateTime? completedAt;           // Fecha de completado
  final Map<String, dynamic>? metadata;  // Datos adicionales
  final String? errorMessage;            // Mensaje de error (si falló)
  final int seatsReserved;               // Cantidad de asientos reservados

  PaymentModel({
    this.id,
    required this.transactionId,
    required this.passengerId,
    required this.travelId,
    this.reservationId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.wompiTransactionId,
    this.wompiReference,
    this.paymentUrl,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.metadata,
    this.errorMessage,
    required this.seatsReserved,
  });

  /// Convierte el modelo a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'passengerId': passengerId,
      'travelId': travelId,
      'reservationId': reservationId,
      'amount': amount,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'wompiTransactionId': wompiTransactionId,
      'wompiReference': wompiReference,
      'paymentUrl': paymentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
      'errorMessage': errorMessage,
      'seatsReserved': seatsReserved,
    };
  }

  /// Crea un objeto PaymentModel desde un mapa de Firestore
  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PaymentModel(
      id: documentId,
      transactionId: map['transactionId'] ?? '',
      passengerId: map['passengerId'] ?? '',
      travelId: map['travelId'] ?? '',
      reservationId: map['reservationId'],
      amount: (map['amount'] ?? 0).toDouble(),
      status: _parsePaymentStatus(map['status'] ?? 'pending'),
      paymentMethod: _parsePaymentMethod(map['paymentMethod'] ?? 'card'),
      wompiTransactionId: map['wompiTransactionId'],
      wompiReference: map['wompiReference'],
      paymentUrl: map['paymentUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'],
      errorMessage: map['errorMessage'],
      seatsReserved: map['seatsReserved'] ?? 1,
    );
  }

  /// Parsea un string a PaymentStatus
  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  /// Parsea un string a PaymentMethod
  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return PaymentMethod.card;
      case 'pse':
        return PaymentMethod.pse;
      case 'nequi':
        return PaymentMethod.nequi;
      case 'bancolombia':
        return PaymentMethod.bancolombia;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.card;
    }
  }

  /// Obtiene el texto descriptivo del estado
  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.processing:
        return 'Procesando';
      case PaymentStatus.completed:
        return 'Completado';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.refunded:
        return 'Reembolsado';
      case PaymentStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Obtiene el texto descriptivo del método de pago
  String get paymentMethodText {
    switch (paymentMethod) {
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.pse:
        return 'PSE';
      case PaymentMethod.nequi:
        return 'Nequi';
      case PaymentMethod.bancolombia:
        return 'Bancolombia';
      case PaymentMethod.cash:
        return 'Efectivo';
    }
  }

  /// Verifica si el pago está completado
  bool get isCompleted => status == PaymentStatus.completed;

  /// Verifica si el pago está pendiente o procesando
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.processing;

  /// Verifica si el pago falló
  bool get isFailed => status == PaymentStatus.failed;

  /// Crea una copia del modelo con campos actualizados
  PaymentModel copyWith({
    String? id,
    String? transactionId,
    String? passengerId,
    String? travelId,
    String? reservationId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? paymentMethod,
    String? wompiTransactionId,
    String? wompiReference,
    String? paymentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    String? errorMessage,
    int? seatsReserved,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      passengerId: passengerId ?? this.passengerId,
      travelId: travelId ?? this.travelId,
      reservationId: reservationId ?? this.reservationId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      wompiTransactionId: wompiTransactionId ?? this.wompiTransactionId,
      wompiReference: wompiReference ?? this.wompiReference,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
      seatsReserved: seatsReserved ?? this.seatsReserved,
    );
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, transactionId: $transactionId, amount: $amount, status: ${status.name})';
  }
}
