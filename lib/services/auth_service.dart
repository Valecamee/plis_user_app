import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Servicio de autenticación para usuarios pasajeros.
/// Maneja registro, login, logout y operaciones relacionadas con Firebase Auth.
/// IMPORTANTE: Usa la colección 'users' (no 'drivers')

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene el usuario autenticado actual.
  User? get currentUser => _auth.currentUser;

  /// Escucha los cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registra un nuevo usuario pasajero.
  Future<UserModel> register({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String telefono,
    required String documento,
  }) async {
    try {
      // 1. Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Error al crear usuario en Auth');

      // 2. Crear modelo de usuario
      UserModel newUser = UserModel(
        id: user.uid,
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        documento: documento,
        verificado: false,
        fechaRegistro: DateTime.now(),
      );

      // 3. Guardar datos en Firestore (colección 'users')
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      return newUser;

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  /// Inicia sesión con email y contraseña.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Error en autenticación');

      // 2. Obtener datos del usuario de Firestore (colección 'users')
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      // 3. Convertir a UserModel y retornar
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(userData, user.uid);

    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  /// Obtiene el usuario actual desde Firestore.
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return null;

      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(userData, user.uid);

    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      return null;
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Envía email de restablecimiento de contraseña.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al enviar email de restablecimiento: $e');
    }
  }

  /// Maneja las excepciones de FirebaseAuth y retorna un mensaje amigable.
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'El formato del correo electrónico es inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Inténtalo más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'invalid-credential':
        return 'Las credenciales proporcionadas son inválidas';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}