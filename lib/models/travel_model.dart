import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modelo de datos para representar un viaje publicado por un conductor.
/// Este modelo es compatible con la colección 'travels' de Firebase.

/// Estados posibles de un viaje.
enum EstadoViaje {
  programado,
  en_curso,
  completado,
  cancelado,
}

/// Tipos de equipaje permitidos en el viaje.
enum TipoEquipaje {
  pequeno,
  mediano,
  grande,
}

class Travel {
  final String? id;
  final String conductorId;
  final String conductorNombre;
  final String conductorApellido;
  final String conductorTelefono;
  final String origen;
  final String destino;
  final DateTime fechaViaje;
  final TimeOfDay horaViaje;
  final int plazasTotales;
  final int plazasDisponibles;
  final TipoEquipaje tipoEquipaje;
  final double? precio;
  final EstadoViaje estado;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final String? observaciones;
  final String? motivoCancelacion;
  final String? vehiculoPlaca;

  // Datos de Google Places y Routes
  final String? origenPlaceId;
  final double? origenLat;
  final double? origenLng;
  final String? destinoPlaceId;
  final double? destinoLat;
  final double? destinoLng;
  final int? distanciaMetros;
  final String? distanciaTexto;
  final int? duracionSegundos;
  final String? duracionTexto;
  final String? polyline;
  final double? precioPorAsiento;
  final double? precioTotal;

  Travel({
    this.id,
    required this.conductorId,
    required this.conductorNombre,
    required this.conductorApellido,
    required this.conductorTelefono,
    required this.origen,
    required this.destino,
    required this.fechaViaje,
    required this.horaViaje,
    required this.plazasTotales,
    required this.plazasDisponibles,
    required this.tipoEquipaje,
    this.precio,
    required this.estado,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.observaciones,
    this.motivoCancelacion,
    this.vehiculoPlaca,
    this.origenPlaceId,
    this.origenLat,
    this.origenLng,
    this.destinoPlaceId,
    this.destinoLat,
    this.destinoLng,
    this.distanciaMetros,
    this.distanciaTexto,
    this.duracionSegundos,
    this.duracionTexto,
    this.polyline,
    this.precioPorAsiento,
    this.precioTotal,
  });

  /// Crea un objeto [Travel] a partir de un mapa proveniente de Firestore.
  factory Travel.fromMap(Map<String, dynamic> map, String documentId) {
    return Travel(
      id: documentId,
      conductorId: map['conductorId'] ?? '',
      conductorNombre: map['conductorNombre'] ?? '',
      conductorApellido: map['conductorApellido'] ?? '',
      conductorTelefono: map['conductorTelefono'] ?? '',
      vehiculoPlaca: map['vehiculoPlaca'] ?? '',
      origen: map['origen'] ?? '',
      destino: map['destino'] ?? '',
      fechaViaje: (map['fechaViaje'] as Timestamp).toDate(),
      horaViaje: _parseTimeOfDay(map['horaViaje'] ?? '00:00'),
      plazasTotales: map['plazasTotales'] ?? 0,
      plazasDisponibles: map['plazasDisponibles'] ?? 0,
      tipoEquipaje: _parseTipoEquipaje(map['tipoEquipaje'] ?? 'pequeno'),
      precio: map['precio']?.toDouble(),
      estado: _parseEstadoViaje(map['estado'] ?? 'programado'),
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? (map['fechaActualizacion'] as Timestamp).toDate()
          : null,
      observaciones: map['observaciones'],
      motivoCancelacion: map['motivoCancelacion'],
      origenPlaceId: map['origenPlaceId'],
      origenLat: map['origenLat']?.toDouble(),
      origenLng: map['origenLng']?.toDouble(),
      destinoPlaceId: map['destinoPlaceId'],
      destinoLat: map['destinoLat']?.toDouble(),
      destinoLng: map['destinoLng']?.toDouble(),
      distanciaMetros: map['distanciaMetros'],
      distanciaTexto: map['distanciaTexto'],
      duracionSegundos: map['duracionSegundos'],
      duracionTexto: map['duracionTexto'],
      polyline: map['polyline'],
      precioPorAsiento: map['precioPorAsiento']?.toDouble(),
      precioTotal: map['precioTotal']?.toDouble(),
    );
  }

  /// Convierte un string en un objeto [TimeOfDay].
  static TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      // Manejar diferentes formatos de hora
      if (timeString.contains('PM') || timeString.contains('AM')) {
        // Formato: "2:30 PM" o "02:30 PM"
        final isPM = timeString.contains('PM');
        final cleanTime = timeString.replaceAll('PM', '').replaceAll('AM', '').trim();
        final parts = cleanTime.split(':');

        int hour = int.parse(parts[0]);
        int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

        // Convertir a formato 24 horas
        if (isPM && hour != 12) {
          hour += 12;
        } else if (!isPM && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      } else {
        // Formato 24 horas: "14:30" o "14:30:00"
        final parts = timeString.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Error parseando hora "$timeString": $e');
      // Retornar hora por defecto si hay error
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  /// Convierte un string en un [TipoEquipaje].
  static TipoEquipaje _parseTipoEquipaje(String equipaje) {
    switch (equipaje) {
      case 'pequeno':
        return TipoEquipaje.pequeno;
      case 'mediano':
        return TipoEquipaje.mediano;
      case 'grande':
        return TipoEquipaje.grande;
      default:
        return TipoEquipaje.pequeno;
    }
  }

  /// Convierte un string en un [EstadoViaje].
  static EstadoViaje _parseEstadoViaje(String estado) {
    switch (estado) {
      case 'programado':
        return EstadoViaje.programado;
      case 'en_curso':
        return EstadoViaje.en_curso;
      case 'completado':
        return EstadoViaje.completado;
      case 'cancelado':
        return EstadoViaje.cancelado;
      default:
        return EstadoViaje.programado;
    }
  }

  /// Obtiene el nombre completo del conductor.
  String get conductorNombreCompleto => '$conductorNombre $conductorApellido';

  /// Obtiene las iniciales del conductor para avatares.
  String get conductorIniciales {
    String inicialNombre = conductorNombre.isNotEmpty ? conductorNombre[0].toUpperCase() : '';
    String inicialApellido = conductorApellido.isNotEmpty ? conductorApellido[0].toUpperCase() : '';
    return '$inicialNombre$inicialApellido';
  }

  /// Formatea la fecha del viaje.
  String get fechaFormateada {
    return '${fechaViaje.day.toString().padLeft(2, '0')}/${fechaViaje.month.toString().padLeft(2, '0')}/${fechaViaje.year}';
  }

  /// Formatea la hora del viaje.
  String get horaFormateada {
    return '${horaViaje.hour.toString().padLeft(2, '0')}:${horaViaje.minute.toString().padLeft(2, '0')}';
  }

  /// Verifica si el viaje está disponible para reservar.
  bool get estaDisponible {
    return estado == EstadoViaje.programado &&
           plazasDisponibles > 0 &&
           fechaViaje.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Obtiene el texto descriptivo del tipo de equipaje.
  String get tipoEquipajeTexto {
    switch (tipoEquipaje) {
      case TipoEquipaje.pequeno:
        return 'Pequeño';
      case TipoEquipaje.mediano:
        return 'Mediano';
      case TipoEquipaje.grande:
        return 'Grande';
    }
  }

  /// Obtiene el texto descriptivo del estado del viaje.
  String get estadoTexto {
    switch (estado) {
      case EstadoViaje.programado:
        return 'Programado';
      case EstadoViaje.en_curso:
        return 'En curso';
      case EstadoViaje.completado:
        return 'Completado';
      case EstadoViaje.cancelado:
        return 'Cancelado';
    }
  }

  @override
  String toString() {
    return 'Travel(id: $id, origen: $origen, destino: $destino, fecha: $fechaFormateada)';
  }
}
