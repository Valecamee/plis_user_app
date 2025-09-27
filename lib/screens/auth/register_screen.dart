import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/link_text.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'login_screen.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _documentoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Registrar usuario
      UserModel userData = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        documento: _documentoController.text.trim(),
      );

      // Registro exitoso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada exitosamente!'),
            backgroundColor: AppColors.exito,
          ),
        );

        // Navegar al home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }

    } catch (e) {
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.principal,
              AppColors.secundario,
              Colors.white,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), // Para centrar el título
                  ],
                ),
              ),

              // Contenido en tarjeta
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // Título y subtítulo
                          const Text(
                            'Datos personales',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.titulo,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ingresa tu información para crear tu cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.subtitulo,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Campos de formulario
                          CustomTextField(
                            controller: _nombreController,
                            label: 'Nombre(s)',
                            hintText: 'Tu nombre',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu nombre';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _apellidoController,
                            label: 'Apellido(s)',
                            hintText: 'Tu apellido',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu apellido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _emailController,
                            label: 'Correo electrónico',
                            hintText: 'ejemplo@correo.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu correo';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Correo inválido';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _telefonoController,
                            label: 'Número de teléfono',
                            hintText: '3001234567',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu teléfono';
                              }
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Solo se permiten números';
                              }
                              if (value.length < 8) {
                                return 'Mínimo 8 dígitos';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _documentoController,
                            label: 'Cédula de ciudadanía',
                            hintText: '12345678',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu cédula';
                              }
                              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                return 'Solo se permiten números';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            hintText: 'Crea una contraseña segura',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.gris400,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Crea una contraseña';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirmar contraseña',
                            hintText: 'Repite tu contraseña',
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.gris400,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirma tu contraseña';
                              }
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Botón de registro
                          _isLoading
                              ? Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.gris200,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.principal,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                              : GradientButton(
                            text: 'Crear cuenta',
                            onTap: _handleRegister,
                          ),

                          const SizedBox(height: 24),

                          // Link para ir al login
                          LinkText(
                            text1: "¿Ya tienes una cuenta? ",
                            text2: "Iniciar sesión",
                            colorText1: AppColors.subtitulo,
                            colorText2: AppColors.principal,
                            onTap: () => _goToLogin(context),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}