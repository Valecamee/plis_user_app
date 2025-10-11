import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_model.dart';

/// Servicio para CONSULTAR y BUSCAR viajes disponibles.
/// Responsabilidad: Operaciones de lectura y búsqueda de viajes.
class TravelQueryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'travels';

  // ============== CONSULTAS GENERALES ==============

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

  // ============== BÚSQUEDAS Y FILTROS ==============

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

  /// Búsqueda avanzada con múltiples filtros y scoring.
  ///
  /// [query] - Texto de búsqueda general.
  /// [filters] - Mapa con filtros adicionales (origen, destino, fecha, precio, etc).
  /// Retorna: Future<List<Travel>> ordenados por relevancia.
  static Future<List<Travel>> advancedSearch({
    required String query,
    required Map<String, dynamic> filters,
  }) async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final allTravels = snapshot.docs
        .map((doc) => Travel.fromMap(doc.data(), doc.id))
        .toList();

    // Filtros del widget
    final String? origen = filters['origen'];
    final String? destino = filters['destino'];
    final DateTime? fechaViaje = filters['fechaViaje'];
    final double? precio = filters['precio'];
    final int? plazasTotales = filters['plazasTotales'];

    // Lógica de coincidencia ponderada
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

      if (plazasTotales != null && travel.plazasDisponibles >= plazasTotales) {
        score += 1;
      }

      // Si coincide con el query general (texto libre)
      if (query.isNotEmpty &&
          (travel.origen.toLowerCase().contains(query.toLowerCase()) ||
              travel.destino.toLowerCase().contains(query.toLowerCase()))) {
        score += 2;
      }

      return score > 0;
    }).toList();

    // Ordenar por puntuación
    filtered.sort((a, b) {
      double scoreA = _calculateMatchScore(a, query, filters);
      double scoreB = _calculateMatchScore(b, query, filters);
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  /// Calcula el score de coincidencia para ordenar resultados.
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
}