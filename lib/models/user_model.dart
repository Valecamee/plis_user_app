import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para representar un usuario pasajero en la app Plis Usuario.
/// Similar al modelo de conductor pero específico para pasajeros.

class UserModel {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String documento;
  final bool verificado;
  final DateTime fechaRegistro;
  final DateTime? fechaActualizacion;
  final String? fotoPerfilUrl;
  final String? cedulaUrl; // URL de la foto de la cédula

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.documento,
    this.verificado = false,
    required this.fechaRegistro,
    this.fechaActualizacion,
    this.fotoPerfilUrl,
    this.cedulaUrl,
  });

  /// Crea una instancia de [UserModel] a partir de un mapa de Firestore.
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      documento: map['documento'] ?? '',
      verificado: map['verificado'] ?? false,
      fechaRegistro: map['fechaRegistro'] != null
          ? (map['fechaRegistro'] as Timestamp).toDate()
          : DateTime.now(),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? (map['fechaActualizacion'] as Timestamp).toDate()
          : null,
      fotoPerfilUrl: map['fotoPerfilUrl'],
      cedulaUrl: map['cedulaUrl'],
    );
  }

  /// Convierte el objeto [UserModel] a un mapa para almacenarlo en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'documento': documento,
      'verificado': verificado,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'fechaActualizacion': fechaActualizacion != null
          ? Timestamp.fromDate(fechaActualizacion!)
          : null,
      'fotoPerfilUrl': fotoPerfilUrl,
      'cedulaUrl': cedulaUrl,
    };
  }

  /// Obtiene el nombre completo del usuario.
  String get nombreCompleto => '$nombre $apellido';

  /// Obtiene las iniciales del usuario para mostrar en avatares.
  String get iniciales {
    String inicialNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    String inicialApellido = apellido.isNotEmpty ? apellido[0].toUpperCase() : '';
    return '$inicialNombre$inicialApellido';
  }

  /// Crea una copia del objeto con los campos especificados modificados.
  UserModel copyWith({
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? documento,
    bool? verificado,
    DateTime? fechaRegistro,
    DateTime? fechaActualizacion,
    String? fotoPerfilUrl,
    String? cedulaUrl,
  }) {
    return UserModel(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      documento: documento ?? this.documento,
      verificado: verificado ?? this.verificado,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      cedulaUrl: cedulaUrl ?? this.cedulaUrl,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, nombre: $nombre, apellido: $apellido, email: $email)';
  }
}