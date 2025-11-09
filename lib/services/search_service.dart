import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/travel_model.dart';
import '../utils/text_utils.dart';

/// Servicio unificado para CONSULTAR y BUSCAR viajes disponibles.
/// Responsabilidad: Operaciones de lectura, búsqueda y filtrado de viajes.
class SearchService {
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

  /// Realiza una búsqueda avanzada con múltiples filtros
  static Future<List<Travel>> searchTravels({
    String? origen,
    String? destino,
    double? precioMaximo,
    DateTime? fecha,
    TimeOfDay? horaMinima,
    TimeOfDay? horaMaxima,
    int? asientosMinimos,
  }) async {
    try {
      // Construir query base
      Query query = _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: 'programado')
          .where('plazasDisponibles', isGreaterThan: 0);

      // Filtrar por fecha si se especifica
      if (fecha != null) {
        DateTime fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
        DateTime fechaFin = fechaInicio.add(const Duration(days: 1));
        query = query
            .where('fechaViaje', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
            .where('fechaViaje', isLessThan: Timestamp.fromDate(fechaFin));
      }

      // Obtener resultados
      QuerySnapshot querySnapshot = await query.get();

      // Convertir documentos a objetos Travel
      List<Travel> travels = querySnapshot.docs
          .map((doc) => Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Aplicar filtros locales (Firestore no soporta todos los filtros nativamente)
      travels = _applyLocalFilters(
        travels,
        origen: origen,
        destino: destino,
        precioMaximo: precioMaximo,
        horaMinima: horaMinima,
        horaMaxima: horaMaxima,
        asientosMinimos: asientosMinimos,
      );

      return travels;
    } catch (e) {
      throw Exception('Error en búsqueda: $e');
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

      // Filtrar usando búsqueda flexible (sin tildes, case-insensitive)
      return querySnapshot.docs
          .map((doc) => Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((travel) =>
              TextUtils.containsIgnoreCaseAndAccents(travel.origen, searchText) ||
              TextUtils.containsIgnoreCaseAndAccents(travel.destino, searchText))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar viajes por texto: $e');
    }
  }

  /// Búsqueda rápida por texto (origen o destino) - Alias de searchByText
  static Future<List<Travel>> quickSearch(String searchText) async {
    return searchByText(searchText);
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

    // Lógica de coincidencia ponderada con búsqueda flexible
    final filtered = allTravels.where((travel) {
      double score = 0;

      if (origen != null && TextUtils.containsIgnoreCaseAndAccents(travel.origen, origen)) {
        score += 2;
      }

      if (destino != null && TextUtils.containsIgnoreCaseAndAccents(travel.destino, destino)) {
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

      // Si coincide con el query general (texto libre) con búsqueda flexible
      if (query.isNotEmpty &&
          (TextUtils.containsIgnoreCaseAndAccents(travel.origen, query) ||
              TextUtils.containsIgnoreCaseAndAccents(travel.destino, query))) {
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

  // ============== MÉTODOS AUXILIARES ==============

  /// Obtiene lista única de orígenes disponibles
  static Future<List<String>> getAvailableOrigins() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final origins = snapshot.docs
        .map((doc) => doc['origen'] as String)
        .toSet()
        .toList();
    return origins;
  }

  /// Obtiene lista única de destinos disponibles
  static Future<List<String>> getAvailableDestinations() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    final destinations = snapshot.docs
        .map((doc) => doc['destino'] as String)
        .toSet()
        .toList();
    return destinations;
  }

  /// Obtiene el rango de precios disponibles
  static Future<Map<String, double>> getPriceRange() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: 'programado')
          .where('precioPorAsiento', isGreaterThan: 0)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'min': 0, 'max': 100000};
      }

      double minPrice = double.infinity;
      double maxPrice = 0;

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double? precio = data['precioPorAsiento']?.toDouble();
        if (precio != null && precio > 0) {
          if (precio < minPrice) minPrice = precio;
          if (precio > maxPrice) maxPrice = precio;
        }
      }

      return {
        'min': minPrice == double.infinity ? 0 : minPrice,
        'max': maxPrice == 0 ? 100000 : maxPrice,
      };
    } catch (e) {
      print('Error obteniendo rango de precios: $e');
      return {'min': 0, 'max': 100000};
    }
  }

  // ============== MÉTODOS PRIVADOS ==============

  /// Aplica filtros que no se pueden hacer en Firestore directamente
  static List<Travel> _applyLocalFilters(
      List<Travel> travels, {
        String? origen,
        String? destino,
        double? precioMaximo,
        TimeOfDay? horaMinima,
        TimeOfDay? horaMaxima,
        int? asientosMinimos,
      }) {
    return travels.where((travel) {
      // Filtro de origen (búsqueda flexible)
      if (origen != null && origen.isNotEmpty) {
        if (!TextUtils.containsIgnoreCaseAndAccents(travel.origen, origen)) {
          return false;
        }
      }

      // Filtro de destino (búsqueda flexible)
      if (destino != null && destino.isNotEmpty) {
        if (!TextUtils.containsIgnoreCaseAndAccents(travel.destino, destino)) {
          return false;
        }
      }

      // Filtro de precio máximo
      if (precioMaximo != null) {
        if (travel.precioPorAsiento == null || travel.precioPorAsiento! > precioMaximo) {
          return false;
        }
      }

      // Filtro de hora mínima
      if (horaMinima != null) {
        if (!_isTimeAfterOrEqual(travel.horaViaje, horaMinima)) {
          return false;
        }
      }

      // Filtro de hora máxima
      if (horaMaxima != null) {
        if (!_isTimeBeforeOrEqual(travel.horaViaje, horaMaxima)) {
          return false;
        }
      }

      // Filtro de asientos mínimos
      if (asientosMinimos != null) {
        if (travel.plazasDisponibles < asientosMinimos) {
          return false;
        }
      }

      return true;
    }).toList();
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

    if (origen != null && TextUtils.containsIgnoreCaseAndAccents(travel.origen, origen)) score += 2;
    if (destino != null && TextUtils.containsIgnoreCaseAndAccents(travel.destino, destino)) score += 2;
    if (fechaViaje != null &&
        (travel.fechaViaje.year == fechaViaje.year &&
            travel.fechaViaje.month == fechaViaje.month &&
            travel.fechaViaje.day == fechaViaje.day)) score += 1.5;
    if (precio != null && travel.precio != null && travel.precio! <= precio) score += 1;
    if (plazasTotales != null && travel.plazasTotales >= plazasTotales) score += 1;

    if (query.isNotEmpty &&
        (TextUtils.containsIgnoreCaseAndAccents(travel.origen, query) ||
            TextUtils.containsIgnoreCaseAndAccents(travel.destino, query))) score += 2;

    return score;
  }

  /// Compara si una hora es después o igual a otra
  static bool _isTimeAfterOrEqual(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour > time2.hour) return true;
    if (time1.hour == time2.hour && time1.minute >= time2.minute) return true;
    return false;
  }

  /// Compara si una hora es antes o igual a otra
  static bool _isTimeBeforeOrEqual(TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour < time2.hour) return true;
    if (time1.hour == time2.hour && time1.minute <= time2.minute) return true;
    return false;
  }
}