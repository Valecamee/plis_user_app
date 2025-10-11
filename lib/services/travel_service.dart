import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_model.dart';
// imports al top del archivo
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// Servicio para gestionar viajes en Firebase desde la app de usuarios.
/// - Consultar viajes disponibles.
/// - Buscar viajes por filtros (origen, destino, fecha).
/// - Obtener detalles de un viaje específico.

class TravelService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nombre de la colección (debe coincidir con la app conductor)
  static const String _collectionName = 'travels';

  /// Obtiene un stream de viajes disponibles ordenados por fecha.
  ///
  /// [limit] - Número máximo de viajes a retornar (por defecto 10).
  /// Retorna: Stream<List<Travel>> con los viajes disponibles.
  static Stream<List<Travel>> getAvailableTravelsStream({int limit = 10}) {
    return _firestore
        .collection(_collectionName)
        .limit(limit * 2) // Obtener más para filtrar localmente
        .snapshots()
        .map((snapshot) {
      // Filtrar localmente por estado y plazas disponibles
      return snapshot.docs
          .map((doc) => Travel.fromMap(doc.data(), doc.id))
          .where((travel) =>
              travel.plazasDisponibles > 0 &&
              travel.estado.toString().split('.').last == 'programado')
          .take(limit)
          .toList();
    });
  }

  /// Obtiene una lista de viajes disponibles (consulta única).
  ///
  /// [limit] - Número máximo de viajes a retornar (por defecto 10).
  /// Retorna: Future<List<Travel>> con los viajes disponibles.
  static Future<List<Travel>> getAvailableTravels({int limit = 10}) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: 'programado')
          .where('plazasDisponibles', isGreaterThan: 0)
          .orderBy('fechaCreacion', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener viajes disponibles: $e');
    }
  }

  /// Busca viajes según filtros específicos.
  ///
  /// [origen] - Filtro por ciudad de origen (opcional).
  /// [destino] - Filtro por ciudad de destino (opcional).
  /// [fecha] - Filtro por fecha específica (opcional).
  /// Retorna: Future<List<Travel>> con los viajes encontrados.
  static Future<List<Travel>> searchTravels({
    String? origen,
    String? destino,
    DateTime? fecha,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: 'programado')
          .where('plazasDisponibles', isGreaterThan: 0);

      // Aplicar filtros opcionales
      if (origen != null && origen.isNotEmpty) {
        query = query.where('origen', isEqualTo: origen);
      }

      if (destino != null && destino.isNotEmpty) {
        query = query.where('destino', isEqualTo: destino);
      }

      if (fecha != null) {
        DateTime fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
        DateTime fechaFin = fechaInicio.add(const Duration(days: 1));
        query = query
            .where('fechaViaje', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
            .where('fechaViaje', isLessThan: Timestamp.fromDate(fechaFin));
      }

      QuerySnapshot querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar viajes: $e');
    }
  }

  /// Obtiene un viaje específico por su ID.
  ///
  /// [travelId] - ID del documento del viaje.
  /// Retorna: Future<Travel?> con el viaje encontrado o null si no existe.
  static Future<Travel?> getTravelById(String travelId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(travelId)
          .get();

      if (!doc.exists) return null;

      return Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Error al obtener viaje: $e');
    }
  }

  /// Obtiene viajes recientes (últimos creados).
  ///
  /// [limit] - Número máximo de viajes a retornar (por defecto 5).
  /// Retorna: Stream<List<Travel>> con los viajes recientes.
  static Stream<List<Travel>> getRecentTravelsStream({int limit = 5}) {
    return _firestore
        .collection(_collectionName)
        .where('estado', isEqualTo: 'programado')
        .where('plazasDisponibles', isGreaterThan: 0)
        .orderBy('fechaCreacion', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Travel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Busca viajes por texto en origen o destino (búsqueda parcial).
  ///
  /// [searchText] - Texto a buscar.
  /// Retorna: Future<List<Travel>> con los viajes que coinciden.
  static Future<List<Travel>> searchByText(String searchText) async {
    try {
      if (searchText.isEmpty) return [];

      // Nota: Firestore no soporta búsqueda LIKE nativa,
      // por lo que obtenemos todos los viajes disponibles y filtramos localmente
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: 'programado')
          .where('plazasDisponibles', isGreaterThan: 0)
          .get();

      String searchLower = searchText.toLowerCase();

      return querySnapshot.docs
          .map((doc) => Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((travel) =>
              travel.origen.toLowerCase().contains(searchLower) ||
              travel.destino.toLowerCase().contains(searchLower))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar viajes por texto: $e');
    }
  }
  static Future<List<Travel>> advancedSearch({
    required String query,
    required Map<String, dynamic> filters,
  }) async {
    final snapshot = await FirebaseFirestore.instance.collection('travels').get();
    final allTravels = snapshot.docs
        .map((doc) => Travel.fromMap(doc.data(), doc.id))
        .toList();

    // Filtros del widget (puedes agregar más campos si los tienes)
    final String? origen = filters['origen'];
    final String? destino = filters['destino'];
    final DateTime? fechaViaje = filters['fechaViaje'];
    final double? precio = filters['precio'];
    final int? plazasTotales = filters['plazasTotales'];

    // Lógica de coincidencia ponderada (no exacta)
    final filtered = allTravels.where((travel) {
      double score = 0;

      if (origen != null &&
          travel.origen.toLowerCase().contains(origen.toLowerCase())) {
        score += 2;
      }

      if (destino != null &&
          travel.destino.toLowerCase().contains(destino.toLowerCase())) {
        score += 2;
      }

      if (fechaViaje != null &&
          (travel.fechaViaje.year == fechaViaje.year &&
              travel.fechaViaje.month == fechaViaje.month &&
              travel.fechaViaje.day == fechaViaje.day)) {
        score += 1.5;
      }

      if (precio != null && travel.precio != null && travel.precio! <= precio) {
        score += 1;
      }


      if (plazasTotales != null && travel.plazasDisponibles != null && travel.plazasDisponibles! >= plazasTotales) {
        score += 1;
      }

      // Si coincide con el query general (texto libre)
      if (query.isNotEmpty &&
          (travel.origen.toLowerCase().contains(query.toLowerCase()) ||
              travel.destino.toLowerCase().contains(query.toLowerCase()))) {
        score += 2;
      }

      return score > 0; // lo incluimos si tiene algún nivel de coincidencia
    }).toList();

    // Ordenamos por mayor puntuación
    filtered.sort((a, b) {
      double scoreA = _calculateMatchScore(a, query, filters);
      double scoreB = _calculateMatchScore(b, query, filters);
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  static double _calculateMatchScore(
      Travel travel, String query, Map<String, dynamic> filters) {
    double score = 0;

    final String? origen = filters['origen'];
    final String? destino = filters['destino'];
    final DateTime? fechaViaje = filters['fechaViaje'];
    final double? precio = filters['precio'];
    final int? plazasTotales = filters['plazasTotales'];

    if (origen != null &&
        travel.origen.toLowerCase().contains(origen.toLowerCase())) score += 2;
    if (destino != null &&
        travel.destino.toLowerCase().contains(destino.toLowerCase())) score += 2;
    if (fechaViaje != null &&
        (travel.fechaViaje.year == fechaViaje.year &&
            travel.fechaViaje.month == fechaViaje.month &&
            travel.fechaViaje.day == fechaViaje.day)) score += 1.5;
    if (precio != null && travel.precio != null && travel.precio! <= precio) score += 1;

    if (plazasTotales != null && travel.plazasTotales >= plazasTotales) score += 1;

    if (query.isNotEmpty &&
        (travel.origen.toLowerCase().contains(query.toLowerCase()) ||
            travel.destino.toLowerCase().contains(query.toLowerCase()))) score += 2;

    return score;
  }

  /// Obtiene el número de plazas disponibles de un viaje.
  ///
  /// [travelId] - ID del viaje.
  /// Retorna: Future<int> con el número de plazas disponibles.
  static Future<int> getAvailableSeats(String travelId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(travelId)
          .get();

      if (!doc.exists) return 0;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return data['plazasDisponibles'] ?? 0;
    } catch (e) {
      throw Exception('Error al obtener plazas disponibles: $e');
    }
  }
  // ---------------- RESERVAR ASIENTO ----------------
  /// Reserva 1 asiento (por defecto) de forma atómica.
  /// passengerData debe contener al menos: { 'userId', 'name', 'phone' (opcional) }
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

      // Crear la reserva (doc id = userId)
      final reservationData = <String, dynamic>{
        'userId': userId,
        'name': passengerData['name'] ?? '',
        'phone': passengerData['phone'] ?? '',
        'seats': seats,
        'createdAt': FieldValue.serverTimestamp(),
      };
      tx.set(reservationRef, reservationData);

      // Decrementar plazas disponibles
      tx.update(travelRef, {'plazasDisponibles': available - seats});

      // Crear referencia en user/bookings para fácil consulta desde usuario
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

  // ---------------- CANCELAR RESERVA ----------------
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

      // Borramos la reserva y aumentamos plazas
      tx.delete(reservationRef);
      tx.update(travelRef, {'plazasDisponibles': available + seats});

      // Borrar booking del usuario
      tx.delete(userBookingRef);
    });
  }

  // ---------------- STREAM DE PASAJEROS ----------------
  /// Stream de documentos de reservas para un viaje específico.
  static Stream<List<Map<String, dynamic>>> getPassengersStream(String travelId) {
    return _firestore
        .collection(_collectionName)
        .doc(travelId)
        .collection('reservations')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return data;
    }).toList());
  }
}
