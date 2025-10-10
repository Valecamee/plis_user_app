import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/travel_model.dart';

/// Servicio de búsqueda avanzada de viajes
/// Maneja filtros múltiples: origen, destino, precio, fecha, hora, asientos
class SearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'travels';

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

      // Filtrar por origen si se especifica
      if (origen != null && origen.isNotEmpty) {
        query = query.where('origen', isEqualTo: origen);
      }

      // Filtrar por destino si se especifica
      if (destino != null && destino.isNotEmpty) {
        query = query.where('destino', isEqualTo: destino);
      }

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

  /// Aplica filtros que no se pueden hacer en Firestore directamente
  static List<Travel> _applyLocalFilters(
      List<Travel> travels, {
        double? precioMaximo,
        TimeOfDay? horaMinima,
        TimeOfDay? horaMaxima,
        int? asientosMinimos,
      }) {
    return travels.where((travel) {
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

  /// Búsqueda rápida por texto (origen o destino)
  static Future<List<Travel>> quickSearch(String searchText) async {
    try {
      if (searchText.isEmpty) {
        return await _getAllAvailableTravels();
      }

      // Obtener todos los viajes disponibles
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('estado', isEqualTo: 'programado')
          .where('plazasDisponibles', isGreaterThan: 0)
          .get();

      String searchLower = searchText.toLowerCase();

      // Filtrar localmente por origen o destino
      return querySnapshot.docs
          .map((doc) => Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((travel) =>
      travel.origen.toLowerCase().contains(searchLower) ||
          travel.destino.toLowerCase().contains(searchLower))
          .toList();
    } catch (e) {
      throw Exception('Error en búsqueda rápida: $e');
    }
  }

  /// Obtiene todos los viajes disponibles
  static Future<List<Travel>> _getAllAvailableTravels() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection(_collectionName)
        .where('estado', isEqualTo: 'programado')
        .where('plazasDisponibles', isGreaterThan: 0)
        .orderBy('fechaViaje')
        .limit(50)
        .get();

    return querySnapshot.docs
        .map((doc) => Travel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Obtiene lista única de orígenes disponibles
  static Future<List<String>> getAvailableOrigins() async {
    final snapshot = await FirebaseFirestore.instance.collection('travels').get();
    final origins = snapshot.docs
        .map((doc) => doc['origen'] as String)
        .toSet()
        .toList();
    return origins;
  }


  /// Obtiene lista única de destinos disponibles
  static Future<List<String>> getAvailableDestinations() async {
    final snapshot = await FirebaseFirestore.instance.collection('travels').get();
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
}