import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_model.dart';

/// Servicio para GESTIONAR RESERVAS de usuarios.
/// Responsabilidad: Operaciones de reserva, cancelación y consulta de reservas del usuario.
class TravelBookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'travels';

  // ============== VERIFICACIÓN DE RESERVAS ==============

  /// ✅ NUEVO: Verifica si un usuario tiene reserva en un viaje específico.
  ///
  /// [travelId] - ID del viaje a verificar.
  /// [userId] - ID del usuario.
  /// Retorna: Future<bool> - true si el usuario tiene reserva, false si no.
  static Future<bool> hasUserReservation({
    required String travelId,
    required String userId,
  }) async {
    try {
      print('🔍 [VERIFICAR] Verificando reserva de $userId en viaje $travelId');

      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(travelId)
          .get();

      if (!doc.exists) {
        print('❌ [VERIFICAR] Viaje no existe');
        return false;
      }

      final travelData = doc.data() as Map<String, dynamic>;
      List<dynamic> usuarios = travelData['usuarios'] ?? [];

      // Buscar si el usuario está en el array
      for (var usuario in usuarios) {
        if (usuario['id'] == userId) {
          print('✅ [VERIFICAR] Usuario tiene reserva con ${usuario['plazas']} plazas');
          return true;
        }
      }

      print('❌ [VERIFICAR] Usuario NO tiene reserva');
      return false;
    } catch (e) {
      print('❌ [VERIFICAR] Error: $e');
      return false;
    }
  }

  /// Obtiene los detalles de la reserva del usuario para un viaje específico.
  ///
  /// [travelId] - ID del viaje.
  /// [userId] - ID del usuario.
  /// Retorna: Map con datos de la reserva o null si no existe.
  static Future<Map<String, dynamic>?> getUserReservationDetails({
    required String travelId,
    required String userId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(travelId)
          .get();

      if (!doc.exists) return null;

      final travelData = doc.data() as Map<String, dynamic>;
      List<dynamic> usuarios = travelData['usuarios'] ?? [];

      // Buscar la reserva del usuario
      for (var usuario in usuarios) {
        if (usuario['id'] == userId) {
          return {
            'userId': usuario['id'],
            'seats': usuario['plazas'] ?? 1,
          };
        }
      }

      return null;
    } catch (e) {
      print('Error obteniendo detalles de reserva: $e');
      return null;
    }
  }

  // ============== RESERVAR Y CANCELAR ==============

  /// Reserva asientos en un viaje (método alternativo - crea subcolecciones).
  /// Nota: Este método NO se usa actualmente, la app usa el método de array 'usuarios'.
  static Future<void> reserveSeat({
    required String travelId,
    required String userId,
    required Map<String, dynamic> passengerData,
    int seats = 1,
  }) async {
    final travelRef = _firestore.collection(_collectionName).doc(travelId);
    final reservationRef = travelRef.collection('reservations').doc(userId);
    final userBookingRef = _firestore.collection('users').doc(userId).collection('bookings').doc(travelId);

    await _firestore.runTransaction((tx) async {
      final travelSnap = await tx.get(travelRef);
      if (!travelSnap.exists) throw Exception('Viaje no existe');

      final int available = (travelSnap.data()?['plazasDisponibles'] ?? 0) as int;
      if (available < seats) throw Exception('No hay suficientes plazas disponibles');

      final existingReservation = await tx.get(reservationRef);
      if (existingReservation.exists) throw Exception('Ya reservaste este viaje');

      final reservationData = <String, dynamic>{
        'userId': userId,
        'name': passengerData['name'] ?? '',
        'phone': passengerData['phone'] ?? '',
        'seats': seats,
        'createdAt': FieldValue.serverTimestamp(),
      };
      tx.set(reservationRef, reservationData);

      tx.update(travelRef, {'plazasDisponibles': available - seats});

      final bookingData = <String, dynamic>{
        'travelId': travelId,
        'createdAt': FieldValue.serverTimestamp(),
        'origin': travelSnap.data()?['origen'] ?? '',
        'destination': travelSnap.data()?['destino'] ?? '',
        'fechaViaje': travelSnap.data()?['fechaViaje'] ?? null,
      };
      tx.set(userBookingRef, bookingData);
    });
  }

  /// Cancela una reserva (método alternativo - borra de subcolecciones).
  /// Nota: Este método NO se usa actualmente, la app usa el método de array 'usuarios'.
  static Future<void> cancelReservation({
    required String travelId,
    required String userId,
    int seats = 1,
  }) async {
    final travelRef = _firestore.collection(_collectionName).doc(travelId);
    final reservationRef = travelRef.collection('reservations').doc(userId);
    final userBookingRef = _firestore.collection('users').doc(userId).collection('bookings').doc(travelId);

    await _firestore.runTransaction((tx) async {
      final travelSnap = await tx.get(travelRef);
      if (!travelSnap.exists) throw Exception('Viaje no existe');

      final existingReservation = await tx.get(reservationRef);
      if (!existingReservation.exists) throw Exception('No existe tu reserva');

      final int available = (travelSnap.data()?['plazasDisponibles'] ?? 0) as int;

      tx.delete(reservationRef);
      tx.update(travelRef, {'plazasDisponibles': available + seats});
      tx.delete(userBookingRef);
    });
  }

  /// Cancela la reserva de un usuario (elimina del array usuarios y devuelve plazas).
  ///
  /// [travelId] - ID del viaje.
  /// [userId] - ID del usuario que cancela.
  /// Retorna Future<void> si tiene éxito, lanza Exception si hay error.
  static Future<void> cancelUserReservation({
    required String travelId,
    required String userId,
  }) async {
    print('🚫 [CANCELAR] Cancelando reserva de $userId en viaje $travelId');

    final travelRef = _firestore.collection(_collectionName).doc(travelId);

    await _firestore.runTransaction((transaction) async {
      final travelSnap = await transaction.get(travelRef);

      if (!travelSnap.exists) {
        throw Exception('El viaje no existe');
      }

      final travelData = travelSnap.data() as Map<String, dynamic>;
      List<dynamic> usuarios = List.from(travelData['usuarios'] ?? []);
      int plazasDisponibles = travelData['plazasDisponibles'] ?? 0;

      // Buscar al usuario en el array
      Map<String, dynamic>? userReservation;
      int userIndex = -1;

      for (int i = 0; i < usuarios.length; i++) {
        if (usuarios[i]['id'] == userId) {
          userReservation = usuarios[i];
          userIndex = i;
          break;
        }
      }

      if (userReservation == null || userIndex == -1) {
        throw Exception('No tienes una reserva en este viaje');
      }

      // Obtener las plazas que había reservado
      int plazasReservadas = userReservation['plazas'] ?? 1;

      // Eliminar usuario del array
      usuarios.removeAt(userIndex);

      // Devolver las plazas
      int nuevasPlazasDisponibles = plazasDisponibles + plazasReservadas;

      // Actualizar el documento
      transaction.update(travelRef, {
        'usuarios': usuarios,
        'plazasDisponibles': nuevasPlazasDisponibles,
      });

      print('✅ [CANCELAR] Reserva cancelada. Plazas devueltas: $plazasReservadas');
    });
  }

  // ============== HISTORIAL Y PRÓXIMOS VIAJES ==============

  /// Obtiene un stream de los viajes reservados por el usuario como pasajero.
  /// Lee desde el array 'usuarios' en cada documento de viaje.
  /// Retorna viajes programados, en curso y completados.
  static Stream<List<Map<String, dynamic>>> getUserReservedTravelsStream(String userId) {
    print('📚 [HISTORIAL] Buscando reservas para usuario: $userId');

    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      print('📚 [HISTORIAL] Total de viajes en BD: ${snapshot.docs.length}');

      List<Map<String, dynamic>> travelsWithReservation = [];

      for (var doc in snapshot.docs) {
        try {
          final travelData = doc.data();

          // Buscar si este viaje tiene al usuario en el array 'usuarios'
          List<dynamic> usuarios = travelData['usuarios'] ?? [];

          print('📚 [HISTORIAL] Viaje ${doc.id}: ${usuarios.length} usuarios registrados');

          // Buscar la reserva del usuario actual
          Map<String, dynamic>? userReservation;
          for (var usuario in usuarios) {
            if (usuario['id'] == userId) {
              userReservation = {
                'userId': usuario['id'],
                'seats': usuario['plazas'] ?? 1,
                'createdAt': DateTime.now(),
              };
              print('📚 [HISTORIAL] ✅ Usuario encontrado en viaje ${doc.id} con ${userReservation['seats']} plazas');
              break;
            }
          }

          // Si encontramos la reserva, agregar al resultado
          if (userReservation != null) {
            travelsWithReservation.add({
              'travel': Travel.fromMap(travelData, doc.id),
              'reservation': userReservation,
            });
          }

        } catch (e) {
          print('❌ [HISTORIAL] Error procesando viaje ${doc.id}: $e');
        }
      }

      print('📚 [HISTORIAL] Total de viajes reservados: ${travelsWithReservation.length}');

      // Ordenar por fecha de viaje (más recientes primero)
      travelsWithReservation.sort((a, b) {
        Travel travelA = a['travel'];
        Travel travelB = b['travel'];
        return travelB.fechaViaje.compareTo(travelA.fechaViaje);
      });

      return travelsWithReservation;
    });
  }

  /// Obtiene un stream de los próximos viajes del usuario (solo programados y futuros).
  ///
  /// [userId] - ID del usuario.
  /// [limit] - Número máximo de viajes a retornar (por defecto 3).
  /// Retorna solo viajes con estado 'programado' y fecha >= hoy, ordenados por fecha ascendente.
  static Stream<List<Map<String, dynamic>>> getUpcomingUserTravelsStream(
      String userId, {
        int limit = 3,
      }) {
    print('🚀 [PRÓXIMOS] Buscando próximos viajes para usuario: $userId');

    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> upcomingTravels = [];
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        try {
          final travelData = doc.data();
          final travel = Travel.fromMap(travelData, doc.id);

          // Filtros: debe estar programado y ser fecha futura
          if (travel.estado != EstadoViaje.programado) continue;
          if (travel.fechaViaje.isBefore(now.subtract(const Duration(hours: 1)))) continue;

          // Buscar si el usuario está en este viaje
          List<dynamic> usuarios = travelData['usuarios'] ?? [];
          Map<String, dynamic>? userReservation;

          for (var usuario in usuarios) {
            if (usuario['id'] == userId) {
              userReservation = {
                'userId': usuario['id'],
                'seats': usuario['plazas'] ?? 1,
              };
              break;
            }
          }

          if (userReservation != null) {
            upcomingTravels.add({
              'travel': travel,
              'reservation': userReservation,
            });
          }

        } catch (e) {
          print('❌ [PRÓXIMOS] Error procesando viaje ${doc.id}: $e');
        }
      }

      // Ordenar por fecha ascendente (más cercanos primero)
      upcomingTravels.sort((a, b) {
        Travel travelA = a['travel'];
        Travel travelB = b['travel'];
        return travelA.fechaViaje.compareTo(travelB.fechaViaje);
      });

      // Limitar resultados
      final result = upcomingTravels.take(limit).toList();
      print('🚀 [PRÓXIMOS] Encontrados ${result.length} viajes próximos');

      return result;
    });
  }
}