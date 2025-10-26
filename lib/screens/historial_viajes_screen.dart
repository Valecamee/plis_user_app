import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../services/travel_booking_service.dart';
import '../models/travel_model.dart';
import 'detalle_viaje_screen.dart';
import 'viaje_en_curso_usuario_screen.dart';

/// Pantalla de historial de viajes para USUARIOS (pasajeros)
/// Muestra los viajes que el usuario ha reservado como pasajero
class HistorialViajesScreen extends StatefulWidget {
  const HistorialViajesScreen({Key? key}) : super(key: key);

  @override
  State<HistorialViajesScreen> createState() => _HistorialViajesScreenState();
}

class _HistorialViajesScreenState extends State<HistorialViajesScreen> {
  String _filtroActual = 'programados'; // programados, completados

  Travel? _viajeEnCurso;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.principal,
                AppColors.secundario,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Debes iniciar sesión',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.principal,
              AppColors.secundario,
              AppColors.gris50
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis viajes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Viajes que has reservado',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Agregar tarjeta de viaje en curso AQUÍ
              StreamBuilder<List<Map<String, dynamic>>>(
                  stream: TravelBookingService.getUserReservedTravelsStream(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final viajeEnCurso = snapshot.data!.firstWhere(
                            (item) => (item['travel'] as Travel).estado == EstadoViaje.en_curso,
                        orElse: () => {},
                      );

                      if (viajeEnCurso.isNotEmpty) {
                        final Travel travel = viajeEnCurso['travel'];
                        return _buildViajeEnCursoCard(travel);
                      }
                    }
                    return const SizedBox.shrink();
                  },
              ),
              // Filtros
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildFilterChip('Programados', 'programados'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completados', 'completados'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contenido
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.gris50,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: TravelBookingService.getUserReservedTravelsStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.principal,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error.toString());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Filtrar viajes según el filtro actual
                      List<Map<String, dynamic>> items = snapshot.data!;
                      List<Map<String, dynamic>> filteredItems = items.where((item) {
                        final Travel travel = item['travel'];

                        if (_filtroActual == 'programados') {
                          return travel.estado == EstadoViaje.programado;
                        } else if (_filtroActual == 'completados') {
                          return travel.estado == EstadoViaje.completado;
                        }
                        return false;
                      }).toList();

                      if (filteredItems.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final Travel travel = filteredItems[index]['travel'];
                          final Map<String, dynamic> reservation = filteredItems[index]['reservation'];
                          return _buildViajeCard(travel, reservation, user.uid);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViajeEnCursoCard(Travel viaje) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.exito.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.exito.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_circle_fill,
              color: AppColors.exito,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Viaje en curso',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.titulo,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${viaje.origen} → ${viaje.destino}',
                  style: const TextStyle(
                    color: AppColors.subtitulo,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViajeEnCursoUsuarioScreen(travel: viaje),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.exito,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }


  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroActual == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filtroActual = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.principal : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViajeCard(Travel viaje, Map<String, dynamic> reservation, String userId) {
    Color estadoColor;
    IconData estadoIcon;

    switch (viaje.estado) {
      case EstadoViaje.programado:
        estadoColor = AppColors.informacion;
        estadoIcon = Icons.schedule;
        break;
      case EstadoViaje.en_curso:
        estadoColor = AppColors.advertencia;
        estadoIcon = Icons.directions_car;
        break;
      case EstadoViaje.completado:
        estadoColor = AppColors.exito;
        estadoIcon = Icons.check_circle;
        break;
      case EstadoViaje.cancelado:
        estadoColor = AppColors.error;
        estadoIcon = Icons.cancel;
        break;
    }

    final int seatsReserved = reservation['seats'] ?? 1;
    final bool isProgramado = viaje.estado == EstadoViaje.programado;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleViajeScreen(travel: viaje),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Parte superior con estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(estadoIcon, color: estadoColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    viaje.estadoTexto,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: estadoColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    viaje.fechaFormateada,
                    style: TextStyle(
                      fontSize: 12,
                      color: estadoColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del viaje
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Ruta
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.principal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    viaje.origen,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.titulo,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Container(
                                width: 1,
                                height: 16,
                                color: AppColors.gris300,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    viaje.destino,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.titulo,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (viaje.precioPorAsiento != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${viaje.precioPorAsiento!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.principal,
                              ),
                            ),
                            const Text(
                              'por asiento',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.subtitulo,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.gris200),
                  const SizedBox(height: 16),

                  // Info conductor y detalles
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.principal, AppColors.secundario],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            viaje.conductorIniciales,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viaje.conductorNombreCompleto,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.titulo,
                              ),
                            ),
                            Text(
                              '${viaje.horaFormateada} • ${viaje.duracionTexto ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.subtitulo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.principal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_seat,
                              size: 16,
                              color: AppColors.principal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$seatsReserved ${seatsReserved == 1 ? 'asiento' : 'asientos'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.principal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Botón de cancelar (solo si está programado)
                  if (isProgramado) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.gris200),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(viaje.id!, userId, seatsReserved),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancelar reserva'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra el diálogo de confirmación para cancelar
  void _showCancelDialog(String travelId, String userId, int seats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Cancelar reserva'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro que deseas cancelar tu reserva?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gris50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppColors.subtitulo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se liberarán $seats ${seats == 1 ? 'asiento' : 'asientos'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitulo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelReservation(travelId, userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  /// Cancela la reserva del usuario
  Future<void> _cancelReservation(String travelId, String userId) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.principal),
      ),
    );

    try {
      await TravelBookingService.cancelUserReservation(
        travelId: travelId,
        userId: userId,
      );

      if (!mounted) return;

      // Cerrar loading
      Navigator.pop(context);

      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Reserva cancelada exitosamente'),
            ],
          ),
          backgroundColor: AppColors.exito,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Cerrar loading
      Navigator.pop(context);

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.secundario.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.luggage,
                size: 64,
                color: AppColors.secundario,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No tienes viajes reservados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.titulo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes viajes $_filtroActual',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.subtitulo,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar viajes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.titulo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.subtitulo,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}