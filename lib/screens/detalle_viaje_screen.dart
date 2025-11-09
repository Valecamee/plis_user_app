import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/travel_model.dart';
import '../widgets/route_map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/travel_booking_service.dart';
import 'historial_viajes_screen.dart';
import 'driver_profile_screen.dart';


class DetalleViajeScreen extends StatefulWidget {
  final Travel travel;

  const DetalleViajeScreen({Key? key, required this.travel}) : super(key: key);

  @override
  State<DetalleViajeScreen> createState() => _DetalleViajeScreenState();
}

class _DetalleViajeScreenState extends State<DetalleViajeScreen> {
  bool _isReserving = false;
  bool _hasReservation = false;
  bool _isCheckingReservation = true;
  int _reservedSeats = 0;

  @override
  void initState() {
    super.initState();
    _checkUserReservation();
  }

  /// Verifica si el usuario actual tiene una reserva en este viaje
  Future<void> _checkUserReservation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.travel.id == null) {
      setState(() {
        _isCheckingReservation = false;
      });
      return;
    }

    try {
      // Verificar si tiene reserva
      final hasReservation = await TravelBookingService.hasUserReservation(
        travelId: widget.travel.id!,
        userId: user.uid,
      );

      // Obtener detalles de la reserva si existe
      if (hasReservation) {
        final reservationDetails = await TravelBookingService.getUserReservationDetails(
          travelId: widget.travel.id!,
          userId: user.uid,
        );

        setState(() {
          _hasReservation = true;
          _reservedSeats = reservationDetails?['seats'] ?? 1;
          _isCheckingReservation = false;
        });
      } else {
        setState(() {
          _hasReservation = false;
          _isCheckingReservation = false;
        });
      }
    } catch (e) {
      print('Error verificando reserva: $e');
      setState(() {
        _isCheckingReservation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final travel = widget.travel;

    String origen = travel.origen;
    String destino = travel.destino;
    String conductorNombre = travel.conductorNombre;
    String conductorApellido = travel.conductorApellido;
    String fechaViaje = travel.fechaFormateada;
    String horaViaje = travel.horaFormateada;
    int plazasDisponibles = travel.plazasDisponibles;
    double precio = travel.precioPorAsiento ?? 0;
    String vehiculoPlaca = travel.vehiculoPlaca ?? 'No programado';
    String distanciaTexto = travel.distanciaTexto ?? 'No disponible';
    String duracionTexto = travel.duracionTexto ?? 'No disponible';
    String tipoEquipaje = travel.tipoEquipajeTexto;

    bool viajeDisponible = travel.estaDisponible;

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
              // Header personalizado
              _buildHeader(context),

              const SizedBox(height: 16),

              // Contenido principal
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.gris50,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Solo mostrar "no disponible" si NO tiene reserva
                          if (!viajeDisponible && !_hasReservation) _buildStatusBanner(),

                          // Banner de reserva existente
                          if (_hasReservation) _buildReservationBanner(),

                          _buildConductorSection(conductorNombre, conductorApellido),
                          const SizedBox(height: 20),
                          _buildRutaSection(origen, destino),
                          const SizedBox(height: 20),
                          _buildFechaHoraSection(fechaViaje, horaViaje),
                          const SizedBox(height: 20),
                          _buildDetallesSection(plazasDisponibles, vehiculoPlaca),
                          const SizedBox(height: 20),
                          _buildRutaInfoSection(distanciaTexto, duracionTexto, tipoEquipaje),
                          const SizedBox(height: 20),
                          RouteMapWidget(
                            travel: travel,
                            height: 300,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Barra inferior con botón dinámico
              _buildBottomBar(context, precio.toInt(), viajeDisponible),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Botón de regresar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.principal),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle del viaje',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Información completa',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Botón de compartir
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: AppColors.principal),
              onPressed: () => _compartirViaje(context),
              tooltip: 'Compartir viaje',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Este viaje no está disponible actualmente',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationBanner() {
    // Calcular fecha límite de cancelación
    final now = DateTime.now();
    final travelDateTime = DateTime(
      widget.travel.fechaViaje.year,
      widget.travel.fechaViaje.month,
      widget.travel.fechaViaje.day,
      widget.travel.horaViaje.hour,
      widget.travel.horaViaje.minute,
    );
    
    // 🚨 VALIDACIÓN NO SHOW: Verificar si el viaje ya ocurrió
    final travelHasPassed = now.isAfter(travelDateTime);
    
    final hoursUntilTravel = travelDateTime.difference(now).inHours;
    
    int freeCancellationHours;
    if (hoursUntilTravel >= 168) {
      freeCancellationHours = 48;
    } else if (hoursUntilTravel >= 48 && hoursUntilTravel < 168) {
      freeCancellationHours = 24;
    } else {
      freeCancellationHours = 1;
    }
    
    final deadlineDate = travelDateTime.subtract(Duration(hours: freeCancellationHours));
    final deadlineFormatted = _formatDateTime(deadlineDate);
    final canCancelFree = now.isBefore(deadlineDate);
    
    // 🔍 DEBUG: Ver estado de cancelación
    print('═══════════════════════════════════════');
    print('📋 ESTADO DE RESERVA EXISTENTE');
    print('═══════════════════════════════════════');
    print('Ahora: ${now.toString()}');
    print('Fecha/hora del viaje: ${travelDateTime.toString()}');
    print('🚨 ¿El viaje ya ocurrió?: ${travelHasPassed ? "SÍ - NO SHOW" : "NO"}');
    if (travelHasPassed) {
      final hoursSinceTravel = now.difference(travelDateTime).inHours;
      print('   Horas desde el viaje: $hoursSinceTravel');
      print('   → ESTADO: NO SHOW - 0% reembolso');
    } else {
      print('Plazo límite: ${deadlineDate.toString()}');
      print('¿Puede cancelar gratis?: ${canCancelFree ? "SÍ ✅" : "NO ⚠️"}');
      if (canCancelFree) {
        final hoursRemaining = deadlineDate.difference(now).inHours;
        print('Horas restantes para cancelar gratis: $hoursRemaining');
      } else {
        final hoursLate = now.difference(deadlineDate).inHours;
        print('Horas después del plazo: $hoursLate → Reembolso 50%');
      }
    }
    print('═══════════════════════════════════════\n');
    
    return Column(
      children: [
        // Banner principal de reserva
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                travelHasPassed 
                    ? AppColors.error.withOpacity(0.15)
                    : AppColors.principal.withOpacity(0.1),
                travelHasPassed 
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.secundario.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: travelHasPassed 
                  ? AppColors.error.withOpacity(0.5)
                  : AppColors.principal.withOpacity(0.3), 
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: travelHasPassed ? AppColors.error : AppColors.principal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  travelHasPassed ? Icons.event_busy : Icons.check_circle, 
                  color: Colors.white, 
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      travelHasPassed 
                          ? 'Viaje realizado'
                          : '¡Ya tienes una reserva!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.titulo,
                      ),
                    ),
                    Text(
                      travelHasPassed
                          ? 'Este viaje ya se realizó'
                          : 'Has reservado $_reservedSeats ${_reservedSeats == 1 ? 'asiento' : 'asientos'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.subtitulo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Card de política de cancelación
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: travelHasPassed
                ? Color(0xFFFEE2E2) // Rojo muy claro
                : (canCancelFree 
                    ? Color(0xFFECFDF5) // Verde muy claro
                    : Color(0xFFFEF3C7)), // Amarillo claro
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: travelHasPassed
                  ? AppColors.error
                  : (canCancelFree 
                      ? Color(0xFF059669)
                      : AppColors.advertencia),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    travelHasPassed
                        ? Icons.cancel
                        : (canCancelFree ? Icons.event_available : Icons.access_time),
                    color: travelHasPassed
                        ? AppColors.error
                        : (canCancelFree 
                            ? Color(0xFF059669)
                            : AppColors.advertencia),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      travelHasPassed
                          ? 'No es posible cancelar'
                          : (canCancelFree 
                              ? 'Puedes cancelar gratis hasta:'
                              : 'Cancelación con penalización'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.titulo,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!travelHasPassed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    deadlineFormatted,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: canCancelFree 
                          ? Color(0xFF059669)
                          : AppColors.advertencia,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'El viaje ya se realizó - Sin reembolso',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildPolicyRow(
                Icons.check_circle,
                'Antes de esa fecha: Reembolso del 100%',
                Color(0xFF059669),
              ),
              const SizedBox(height: 6),
              _buildPolicyRow(
                Icons.warning_amber,
                'Después de esa fecha: Reembolso del 50%',
                AppColors.advertencia,
              ),
              const SizedBox(height: 6),
              _buildPolicyRow(
                Icons.cancel,
                'Si no te presentas: Sin reembolso',
                AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRutaSection(String origen, String destino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.principal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desde',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtitulo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        origen,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titulo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Container(
                    width: 2,
                    height: 30,
                    color: AppColors.gris300,
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.more_vert, color: AppColors.subtitulo, size: 16),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasta',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtitulo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        destino,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titulo,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFechaHoraSection(String fecha, String hora) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.principal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today,
                        color: AppColors.principal, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Fecha',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subtitulo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fecha,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titulo,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.oceano.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.access_time,
                        color: AppColors.oceano, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Hora',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.subtitulo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hora,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titulo,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConductorSection(String nombre, String apellido) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verPerfilConductor(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.principal,
                radius: 24,
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nombre $apellido',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.titulo,
                      ),
                    ),
                    const Text(
                      'Conductor',
                      style: TextStyle(color: AppColors.subtitulo),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _contactarConductor(nombre),
                    icon: const Icon(Icons.message, size: 18, color: AppColors.principal),
                    label: const Text('Contactar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.principal,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.subtitulo,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetallesSection(int plazas, String placa) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información adicional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.titulo,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: plazas > 0 
                          ? AppColors.verdePlis.withOpacity(0.1)
                          : AppColors.gris100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: plazas > 0
                            ? AppColors.verdePlis.withOpacity(0.3)
                            : AppColors.gris300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_seat,
                          color: plazas > 0 ? AppColors.verdePlis : AppColors.gris400,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Asientos',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.subtitulo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$plazas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: plazas > 0 ? AppColors.verdePlis : AppColors.gris500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secundario.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.secundario.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: AppColors.secundario,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Placa',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.subtitulo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          placa,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.titulo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isAvailable = true,
  }) {
    Color color = isAvailable ? AppColors.principal : AppColors.gris400;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.subtitulo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int precio, bool disponible) {
    // Mostrar loading mientras verifica
    if (_isCheckingReservation) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.gris600.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.principal),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gris600.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Precio
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Precio por persona',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitulo,
                  ),
                ),
                Text(
                  '\$${precio.toString()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.principal,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Botón dinámico
            Expanded(
              child: _hasReservation
                  ? _buildCancelButton()
                  : _buildReserveButton(context, precio, disponible),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón de cancelar reserva (outline rojo)
  Widget _buildCancelButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error, width: 2),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.cancel_outlined),
      label: const Text(
        'Cancelar reserva',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () => _showCancelDialog(),
    );
  }

  /// Botón de reservar viaje (normal)
  Widget _buildReserveButton(BuildContext context, int precio, bool disponible) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor:
        disponible ? AppColors.principal : AppColors.gris400,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: disponible ? 2 : 0,
      ),
      icon: Icon(disponible ? Icons.check_circle_outline : Icons.block),
      label: Text(
        disponible ? 'Reservar viaje' : 'No disponible',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: disponible ? () => _reservarViaje(context, precio) : null,
    );
  }

  void _compartirViaje(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _verPerfilConductor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverProfileScreen(
          conductorId: widget.travel.conductorId,
          conductorNombre: widget.travel.conductorNombre,
          conductorApellido: widget.travel.conductorApellido,
        ),
      ),
    );
  }

  void _contactarConductor(String nombreConductor) {
    // Implementar contacto con conductor
  }

  void _reservarViaje(BuildContext context, int precio) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reservar')),
      );
      return;
    }

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Obtener información del usuario desde Firebase
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((userDoc) {
      // Cerrar indicador de carga
      Navigator.pop(context);

      if (!userDoc.exists) {
        if (context.mounted) {
          // Intentar con datos básicos del usuario
          _showSeatSelectionModal(
            context,
            precio,
            user.displayName ?? 'Usuario',
            user.phoneNumber ?? '',
            user.uid,
          );
          
          // Mostrar advertencia
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usando información básica del perfil'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userData = userDoc.data()!;
      final userName = userData['nombre'] ?? user.displayName ?? 'Usuario';
      final userPhone = userData['telefono'] ?? user.phoneNumber ?? '';

      // Mostrar modal para seleccionar cantidad de asientos
      _showSeatSelectionModal(context, precio, userName, userPhone, user.uid);
    }).catchError((error) {
      // Cerrar indicador de carga
      Navigator.pop(context);
      
      if (context.mounted) {
        // En caso de error, usar datos básicos
        _showSeatSelectionModal(
          context,
          precio,
          user.displayName ?? 'Usuario',
          user.phoneNumber ?? '',
          user.uid,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar perfil: ${error.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _showSeatSelectionModal(
    BuildContext context,
    int precio,
    String userName,
    String userPhone,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int selectedSeats = 1;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gris300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.airline_seat_recline_normal,
                    size: 48,
                    color: AppColors.principal,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Cuántos asientos necesitas?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.titulo,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedSeats > 1
                            ? () {
                                setModalState(() {
                                  selectedSeats--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 40,
                        color: AppColors.principal,
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.principal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$selectedSeats',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.principal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: selectedSeats < widget.travel.plazasDisponibles
                            ? () {
                                setModalState(() {
                                  selectedSeats++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 40,
                        color: AppColors.principal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.travel.plazasDisponibles} asientos disponibles',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.subtitulo,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.principal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // Usar la lógica original de reserva
                        _confirmarReservaDirecta(selectedSeats);
                      },
                      child: Text(
                        'Continuar (Total: \$${precio * selectedSeats})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Método simplificado que usa la lógica original de reserva
  void _confirmarReservaDirecta(int cantidadPlazas) {
    // Calcular fecha límite de cancelación gratuita
    final now = DateTime.now();
    final travelDateTime = DateTime(
      widget.travel.fechaViaje.year,
      widget.travel.fechaViaje.month,
      widget.travel.fechaViaje.day,
      widget.travel.horaViaje.hour,
      widget.travel.horaViaje.minute,
    );
    
    final hoursUntilTravel = travelDateTime.difference(now).inHours;
    
    // 🔍 DEBUG: Ver cálculos en consola
    print('═══════════════════════════════════════');
    print('📅 CÁLCULO DE POLÍTICA DE CANCELACIÓN');
    print('═══════════════════════════════════════');
    print('Ahora: ${now.toString()}');
    print('Viaje: ${travelDateTime.toString()}');
    print('Horas hasta el viaje: $hoursUntilTravel');
    
    // Determinar ventana de cancelación según política
    int freeCancellationHours;
    if (hoursUntilTravel >= 168) { // >= 7 días
      freeCancellationHours = 48;
      print('✅ Categoría: RESERVA ANTICIPADA (≥7 días)');
      print('   → Plazo de cancelación gratis: 48 horas antes');
    } else if (hoursUntilTravel >= 48 && hoursUntilTravel < 168) { // 2-7 días
      freeCancellationHours = 24;
      print('⚠️  Categoría: RESERVA MEDIA (2-7 días)');
      print('   → Plazo de cancelación gratis: 24 horas antes');
    } else { // < 2 días
      freeCancellationHours = 1;
      print('🔴 Categoría: RESERVA PRÓXIMA (<2 días)');
      print('   → Plazo de cancelación gratis: 1 hora antes');
    }
    
    final deadlineDate = travelDateTime.subtract(Duration(hours: freeCancellationHours));
    final deadlineFormatted = _formatDateTime(deadlineDate);
    
    print('⏰ Fecha límite cancelación gratis: ${deadlineDate.toString()}');
    print('   Formateado: $deadlineFormatted');
    print('═══════════════════════════════════════\n');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.event_seat, color: AppColors.principal),
              SizedBox(width: 12),
              Text("Confirmar reserva"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reservarás $cantidadPlazas ${cantidadPlazas == 1 ? 'asiento' : 'asientos'}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Política de cancelación
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.indigoSuave,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.principal.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.event_available, 
                            color: AppColors.principal, 
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cancelación gratuita hasta:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.titulo,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          deadlineFormatted,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.principal,
                          ),
                        ),
                      ),
                      const Divider(height: 20),
                      _buildPolicyRow(
                        Icons.check_circle,
                        'Antes de esa fecha: Reembolso del 100%',
                        Color(0xFF059669), // Verde más oscuro
                      ),
                      const SizedBox(height: 6),
                      _buildPolicyRow(
                        Icons.warning_amber,
                        'Después de esa fecha: Reembolso del 50%',
                        AppColors.advertencia,
                      ),
                      const SizedBox(height: 6),
                      _buildPolicyRow(
                        Icons.cancel,
                        'Si no te presentas: Sin reembolso',
                        AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Podrás consultar esta información en "Mis Viajes" en cualquier momento.',
                  style: TextStyle(fontSize: 12, color: AppColors.subtitulo),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.principal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await confirmarReservaViaje(widget.travel, cantidadPlazas);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                }
              },
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPolicyRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final dayName = days[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    
    return '$dayName $day de $month a las $hour:$minute';
  }

  Widget _buildRutaInfoSection(String distancia, String duracion, String equipaje) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la ruta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.titulo,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.straighten,
                    label: 'Distancia',
                    value: distancia,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: 'Duración estimada',
                    value: duracion,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              icon: Icons.luggage,
              label: 'Equipaje permitido',
              value: equipaje,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmarReservaViaje(Travel travel, int cantidadPlazas) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final viajeRef = FirebaseFirestore.instance.collection('travels').doc(travel.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(viajeRef);

      if (!snapshot.exists) throw Exception("El viaje no existe");
      final data = snapshot.data()!;

      int plazasDisponibles = data['plazasDisponibles'];
      if (plazasDisponibles < cantidadPlazas) {
        throw Exception("No hay suficientes plazas disponibles");
      }

      List usuarios = List.from(data['usuarios'] ?? []);
      usuarios.add({
        'id': user.uid,
        'plazas': cantidadPlazas,
      });

      transaction.update(viajeRef, {
        'usuarios': usuarios,
        'plazasDisponibles': plazasDisponibles - cantidadPlazas,
      });
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reserva confirmada ✅")),
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HistorialViajesScreen()),
      );
    }
  }

  void _mostrarDialogReserva(BuildContext context) {
    int cantidadPlazas = 1;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirmar reserva"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Selecciona cuántas plazas deseas reservar:"),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (cantidadPlazas > 1) {
                            setState(() => cantidadPlazas--);
                          }
                        },
                      ),
                      Text('$cantidadPlazas', style: TextStyle(fontSize: 20)),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (cantidadPlazas < widget.travel.plazasDisponibles) {
                            setState(() => cantidadPlazas++);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Confirmar"),
              onPressed: () async {
                Navigator.pop(context);
                await confirmarReservaViaje(widget.travel, cantidadPlazas);
              },
            ),
          ],
        );
      },
    );
  }

  /// Muestra el diálogo de confirmación para cancelar desde detalle
  void _showCancelDialog() {
    // Calcular información de reembolso
    final now = DateTime.now();
    final travelDateTime = DateTime(
      widget.travel.fechaViaje.year,
      widget.travel.fechaViaje.month,
      widget.travel.fechaViaje.day,
      widget.travel.horaViaje.hour,
      widget.travel.horaViaje.minute,
    );
    
    // 🚨 VALIDACIÓN NO SHOW: Verificar si el viaje ya ocurrió
    final travelHasPassed = now.isAfter(travelDateTime);
    
    final hoursUntilTravel = travelDateTime.difference(now).inHours;
    
    int freeCancellationHours;
    if (hoursUntilTravel >= 168) {
      freeCancellationHours = 48;
    } else if (hoursUntilTravel >= 48 && hoursUntilTravel < 168) {
      freeCancellationHours = 24;
    } else {
      freeCancellationHours = 1;
    }
    
    final deadlineDate = travelDateTime.subtract(Duration(hours: freeCancellationHours));
    final canCancelFree = now.isBefore(deadlineDate);
    final refundPercentage = travelHasPassed ? 0 : (canCancelFree ? 100 : 50);
    
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
            Expanded(
              child: Text(
                travelHasPassed ? 'No es posible cancelar' : 'Cancelar reserva',
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                travelHasPassed
                    ? 'El viaje ya se realizó y no es posible cancelar la reserva.'
                    : '¿Estás seguro que deseas cancelar tu reserva?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              
              if (!travelHasPassed) ...[
                // Info de asientos
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gris50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat, size: 20, color: AppColors.subtitulo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Se liberarán $_reservedSeats ${_reservedSeats == 1 ? 'asiento' : 'asientos'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.subtitulo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Info de reembolso
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: travelHasPassed
                      ? Color(0xFFFEE2E2) // Rojo claro
                      : (canCancelFree 
                          ? Color(0xFFECFDF5)
                          : Color(0xFFFEF3C7)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: travelHasPassed
                        ? AppColors.error
                        : (canCancelFree 
                            ? Color(0xFF059669)
                            : AppColors.advertencia),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          travelHasPassed 
                              ? Icons.cancel 
                              : (canCancelFree ? Icons.check_circle : Icons.warning_amber),
                          color: travelHasPassed
                              ? AppColors.error
                              : (canCancelFree 
                                  ? Color(0xFF059669)
                                  : AppColors.advertencia),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reembolso: $refundPercentage%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.titulo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      travelHasPassed
                          ? 'El viaje ya se realizó. No recibirás ningún reembolso.'
                          : (canCancelFree
                              ? 'Estás dentro del plazo. Recibirás el reembolso completo.'
                              : 'Ya pasó el plazo de cancelación gratuita. Recibirás el 50% del valor.'),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.subtitulo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(travelHasPassed ? 'Entendido' : 'No, mantener'),
          ),
          if (!travelHasPassed)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelReservation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  /// Cancela la reserva del usuario
  Future<void> _cancelReservation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.travel.id == null) return;

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
        travelId: widget.travel.id!,
        userId: user.uid,
      );

      if (!mounted) return;

      // Cerrar loading
      Navigator.pop(context);

      // Actualizar estado local
      setState(() {
        _hasReservation = false;
        _reservedSeats = 0;
      });

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

      // Opcional: Regresar al historial después de 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HistorialViajesScreen()),
        );
      }
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
}