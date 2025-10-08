import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_model.dart';

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
}
