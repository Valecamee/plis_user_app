import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';

class DriverProfileScreen extends StatefulWidget {
  final String conductorId;
  final String conductorNombre;
  final String conductorApellido;

  const DriverProfileScreen({
    Key? key,
    required this.conductorId,
    required this.conductorNombre,
    required this.conductorApellido,
  }) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _driverData;
  int _totalTrips = 0;
  double _rating = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  /// Carga los datos del conductor desde Firestore
  Future<void> _loadDriverData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Obtener datos del conductor desde la colección 'users' o 'drivers'
      final driverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.conductorId)
          .get();

      if (driverDoc.exists) {
        _driverData = driverDoc.data();
      }

      // Contar viajes completados del conductor
      final tripsQuery = await FirebaseFirestore.instance
          .collection('travels')
          .where('conductorId', isEqualTo: widget.conductorId)
          .where('estado', isEqualTo: 'completado')
          .get();

      _totalTrips = tripsQuery.docs.length;

      // Obtener calificación del conductor (si existe en el documento)
      _rating = (_driverData?['rating'] as num?)?.toDouble() ?? 4.5;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar los datos del conductor';
      });
      print('Error cargando datos del conductor: $e');
    }
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
              AppColors.gris50,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con botón de regresar
              _buildHeader(),

              // Contenido
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.gris50,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.principal,
                          ),
                        )
                      : _errorMessage != null
                          ? _buildErrorState()
                          : _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Perfil del conductor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Para centrar el título
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Foto de perfil
          _buildProfilePicture(),

          const SizedBox(height: 20),

          // Nombre del conductor
          Text(
            '${widget.conductorNombre} ${widget.conductorApellido}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.titulo,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Badge de conductor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.principal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.principal.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.principal, size: 18),
                SizedBox(width: 6),
                Text(
                  'Conductor verificado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.principal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Estadísticas del conductor
          _buildStatsCards(),

          const SizedBox(height: 24),

          // Información adicional
          _buildInfoCard(),

          const SizedBox(height: 24),

          // Botón de contactar
          _buildContactButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    String iniciales = widget.conductorNombre.isNotEmpty && widget.conductorApellido.isNotEmpty
        ? '${widget.conductorNombre[0].toUpperCase()}${widget.conductorApellido[0].toUpperCase()}'
        : 'C';

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.principal, AppColors.secundario],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.principal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          iniciales,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            value: _rating.toStringAsFixed(1),
            label: 'Calificación',
            color: AppColors.verdePlis,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.route,
            value: _totalTrips.toString(),
            label: 'Viajes realizados',
            color: AppColors.principal,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.subtitulo,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del conductor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.titulo,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Nombre completo',
            value: '${widget.conductorNombre} ${widget.conductorApellido}',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.star_outline,
            label: 'Calificación promedio',
            value: '${_rating.toStringAsFixed(1)} estrellas',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.route_outlined,
            label: 'Viajes completados',
            value: '$_totalTrips viajes',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.principal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.principal, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subtitulo,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.titulo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.principal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: const Icon(Icons.message, size: 20),
        label: const Text(
          'Contactar conductor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de mensajería próximamente'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.subtitulo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDriverData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.principal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
