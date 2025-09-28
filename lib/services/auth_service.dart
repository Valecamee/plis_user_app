import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Servicio de autenticación para usuarios pasajeros.
/// Maneja registro, login, logout y operaciones relacionadas con Firebase Auth.
/// IMPORTANTE: Usa la colección 'users' (no 'drivers')
/// Maneja el caso donde un usuario ya existe como conductor.

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene el usuario autenticado actual.
  User? get currentUser => _auth.currentUser;

  /// Escucha los cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registra un nuevo usuario pasajero.
  /// Si ya existe como conductor, usa la misma cuenta de Auth.
  Future<UserModel> register({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String telefono,
    required String documento,
  }) async {
    try {
      UserCredential? userCredential;
      User? user;

      // 1. Verificar si ya existe como conductor
      bool existsAsDriver = await _checkIfExistsAsDriver(email);

      if (existsAsDriver) {
        // Ya existe como conductor, intentar hacer login
        try {
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          user = userCredential.user;

          if (user == null) {
            throw Exception('No se pudo obtener el usuario existente');
          }

          // Verificar si ya existe como usuario también
          bool existsAsUser = await _checkIfExistsAsUser(user.uid);
          if (existsAsUser) {
            throw Exception(
                'Ya tienes una cuenta como usuario con este correo');
          }
        } catch (e) {
          if (e.toString().contains('wrong-password')) {
            throw Exception(
                'Ya tienes una cuenta como conductor con este correo, pero la contraseña es diferente');
          }
          rethrow;
        }
      } else {
        // No existe como conductor, crear nueva cuenta
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;

        if (user == null) throw Exception('Error al crear usuario en Auth');
      }

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

  /// Verifica si un email ya existe en la colección de conductores
  Future<bool> _checkIfExistsAsDriver(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando conductor: $e');
      return false;
    }
  }

  /// Verifica si un UID ya existe en la colección de usuarios
  Future<bool> _checkIfExistsAsUser(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error verificando usuario: $e');
      return false;
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
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        throw Exception(
            'No tienes una cuenta como usuario. ¿Eres conductor? Regístrate primero como usuario.');
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

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

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

  /// Envía email de verificación.
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Error al enviar email de verificación: $e');
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

  /// Actualiza la contraseña del usuario actual.
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al actualizar contraseña: $e');
    }
  }

  /// Reautentica al usuario con su contraseña actual.
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('No hay usuario autenticado');
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error en reautenticación: $e');
    }
  }

  /// Elimina la cuenta del usuario actual.
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      // Eliminar datos de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Eliminar cuenta de Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error al eliminar cuenta: $e');
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
        return 'Ya tienes una cuenta con este correo.\n¿Eres conductor? Usa la misma contraseña para registrarte como usuario también.';
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
      case 'requires-recent-login':
        return 'Esta operación requiere una autenticación reciente';
      case 'invalid-credential':
        return 'Las credenciales proporcionadas son inválidas';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
