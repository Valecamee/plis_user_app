import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/travel_model.dart';
import '../../services/travel_booking_service.dart';
import '../../utils/app_colors.dart';
import '../../screens/historial_viajes_screen.dart';

/// Widget que muestra los próximos 3 viajes del usuario en formato timeline
class ProximosViajesWidget extends StatelessWidget {
  const ProximosViajesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'Inicia sesión',
        subtitle: 'Para ver tus viajes programados',
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: TravelBookingService.getUpcomingUserTravelsStream(user.uid, limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.principal),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'Error',
            subtitle: 'No se pudieron cargar los viajes',
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.luggage,
            title: 'No tienes viajes programados',
            subtitle: 'Busca y reserva tu próximo viaje',
          );
        }

        final upcomingTravels = snapshot.data!;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistorialViajesScreen(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                // Header con título y botón ver todos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.principal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event_note,
                            color: AppColors.principal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Próximos viajes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.titulo,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppColors.gris400,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Timeline de viajes
                ...List.generate(upcomingTravels.length, (index) {
                  final item = upcomingTravels[index];
                  final Travel travel = item['travel'];
                  final isLast = index == upcomingTravels.length - 1;

                  return _buildTimelineItem(
                    travel: travel,
                    isLast: isLast,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem({
    required Travel travel,
    required bool isLast,
  }) {
    // Calcular días restantes
    final daysUntil = travel.fechaViaje.difference(DateTime.now()).inDays;
    String timeLabel;

    if (daysUntil == 0) {
      timeLabel = 'HOY';
    } else if (daysUntil == 1) {
      timeLabel = 'MAÑANA';
    } else {
      timeLabel = 'EN $daysUntil DÍAS';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline visual (círculo y línea)
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.principal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.gris300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),

        const SizedBox(width: 16),

        // Contenido del viaje
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de tiempo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.principal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$timeLabel - ${travel.horaFormateada}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.principal,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Ruta
              Row(
                children: [
                  Expanded(
                    child: Text(
                      travel.origen,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.titulo,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.gris400,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      travel.destino,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.titulo,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Conductor
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.gris200,
                    radius: 10,
                    child: Text(
                      travel.conductorIniciales,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: AppColors.titulo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    travel.conductorNombreCompleto,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitulo,
                    ),
                  ),
                ],
              ),

              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secundario.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, size: 32, color: AppColors.secundario),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.titulo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: AppColors.subtitulo),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}