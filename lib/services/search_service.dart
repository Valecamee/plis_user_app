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

  /// Búsqueda avanzada con múltiples filtros opcionales.
  ///
  /// [query] - Texto de búsqueda general.
  /// [filters] - Mapa con filtros adicionales (origen, destino, fecha, hora, asientos).
  /// Si no se proporcionan filtros, retorna TODOS los viajes disponibles.
  /// Retorna: Future<List<Travel>> filtrados según los criterios opcionales.
  static Future<List<Travel>> advancedSearch({
    required String query,
    required Map<String, dynamic> filters,
  }) async {
    try {
      // Obtener todos los viajes disponibles (con índice en Firebase)
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: 'programado')
          .where('plazasDisponibles', isGreaterThan: 0)
          .get();

      List<Travel> travels = snapshot.docs
          .map((doc) => Travel.fromMap(doc.data(), doc.id))
          .toList();

      // Si no hay filtros ni búsqueda, retornar todos los viajes
      if (query.isEmpty && filters.isEmpty) {
        return travels;
      }

      // Extraer filtros opcionales
      final String? origen = filters['origen'];
      final String? destino = filters['destino'];
      final DateTime? fechaViaje = filters['fecha'];
      final TimeOfDay? horaMinima = filters['horaMinima'];
      final TimeOfDay? horaMaxima = filters['horaMaxima'];
      final int? asientosMinimos = filters['asientosMinimos'];

      // Aplicar filtros locales (solo si están presentes)
      travels = travels.where((travel) {
        // Filtro de texto general (búsqueda en origen y destino)
        if (query.isNotEmpty) {
          if (!TextUtils.containsIgnoreCaseAndAccents(travel.origen, query) &&
              !TextUtils.containsIgnoreCaseAndAccents(travel.destino, query)) {
            return false;
          }
        }

        // Filtro de origen específico
        if (origen != null && origen.isNotEmpty) {
          if (!TextUtils.containsIgnoreCaseAndAccents(travel.origen, origen)) {
            return false;
          }
        }

        // Filtro de destino específico
        if (destino != null && destino.isNotEmpty) {
          if (!TextUtils.containsIgnoreCaseAndAccents(travel.destino, destino)) {
            return false;
          }
        }

        // Filtro de fecha exacta
        if (fechaViaje != null) {
          if (travel.fechaViaje.year != fechaViaje.year ||
              travel.fechaViaje.month != fechaViaje.month ||
              travel.fechaViaje.day != fechaViaje.day) {
            return false;
          }
        }

        // Filtro de hora mínima (el viaje debe salir después o a esa hora)
        if (horaMinima != null) {
          if (!_isTimeAfterOrEqual(travel.horaViaje, horaMinima)) {
            return false;
          }
        }

        // Filtro de hora máxima (el viaje debe salir antes o a esa hora)
        if (horaMaxima != null) {
          if (!_isTimeBeforeOrEqual(travel.horaViaje, horaMaxima)) {
            return false;
          }
        }

        // Filtro de asientos mínimos disponibles
        if (asientosMinimos != null && asientosMinimos > 0) {
          if (travel.plazasDisponibles < asientosMinimos) {
            return false;
          }
        }

        return true;
      }).toList();

      return travels;
    } catch (e) {
      throw Exception('Error en búsqueda avanzada: $e');
    }
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