import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/travel_model.dart';
import '../widgets/route_map_widget.dart';
// imports necesarios:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/travel_service.dart';
import 'historial_viajes_screen.dart';


class DetalleViajeScreen extends StatefulWidget {
  final Travel travel;

  const DetalleViajeScreen({Key? key, required this.travel}) : super(key: key);

  @override
  State<DetalleViajeScreen> createState() => _DetalleViajeScreenState();
}

class _DetalleViajeScreenState extends State<DetalleViajeScreen> {
  bool _isReserving = false;

  @override
  Widget build(BuildContext context) {
    // Accede a widget.travel, no travel directamente
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

    // Verificar disponibilidad del viaje
    bool viajeDisponible = travel.estaDisponible;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Viaje'),
        backgroundColor: AppColors.principal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _compartirViaje(context),
            tooltip: 'Compartir viaje',
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenido principal scrolleable
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner de estado del viaje
                    if (!viajeDisponible) _buildStatusBanner(),

                    // Información del conductor (arriba para generar confianza)
                    _buildConductorSection(conductorNombre, conductorApellido),
                    const SizedBox(height: 20),

                    // Información de ruta (más prominente)
                    _buildRutaSection(origen, destino),
                    const SizedBox(height: 20),

                    // Fecha y hora (información crítica)
                    _buildFechaHoraSection(fechaViaje, horaViaje),
                    const SizedBox(height: 20),

                    // Detalles adicionales
                    _buildDetallesSection(plazasDisponibles, vehiculoPlaca),
                    const SizedBox(height: 20),

                    // Información de ruta
                    _buildRutaInfoSection(distanciaTexto, duracionTexto, tipoEquipaje),
                    const SizedBox(height: 20),

                    // Mapa con la ruta
                    RouteMapWidget(
                      travel: travel,
                      height: 300,
                    ),
                    const SizedBox(height: 100), // Espacio para el botón fijo
                  ],
                ),
              ),
            ),
          ),

          // Barra inferior fija con precio y botón
          _buildBottomBar(context, precio.toInt(), viajeDisponible),
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

  Widget _buildRutaSection(String origen, String destino) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Origen
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

            // Línea conectora
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

            // Destino
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
              child: Column(
                children: [
                  Icon(Icons.calendar_today,
                      color: AppColors.principal, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Fecha',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitulo,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fecha,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.titulo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: AppColors.gris300,
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.access_time, color: AppColors.principal, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Hora',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitulo,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hora,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.titulo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
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
        title: Text(
          '$nombre $apellido',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.titulo,
          ),
        ),
        subtitle: const Text('Conductor',
            style: TextStyle(color: AppColors.subtitulo)),
        trailing: TextButton.icon(
          onPressed: () => _contactarConductor(nombre),
          icon: const Icon(Icons.message, size: 18, color: AppColors.principal),
          label: const Text('Contactar'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.principal,
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
                  child: _buildInfoItem(
                    icon: Icons.event_seat,
                    label: 'Asientos disponibles',
                    value: '$plazas',
                    isAvailable: plazas > 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.directions_car,
                    label: 'Placa del vehículo',
                    value: placa,
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

            // Botón de reserva
            Expanded(
              child: ElevatedButton.icon(
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
                icon:
                    Icon(disponible ? Icons.check_circle_outline : Icons.block),
                label: Text(
                  disponible ? 'Reservar viaje' : 'No disponible',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed:
                    disponible ? () => _reservarViaje(context, precio) : null,
              ),
            ),
          ],
        ),
      ),
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

  void _contactarConductor(String nombreConductor) {
    // Implementar contacto con conductor
  }

  void _reservarViaje(BuildContext context, int precio) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              Icons.info_outline,
              size: 48,
              color: AppColors.principal,
            ),
            const SizedBox(height: 16),
            const Text(
              'Confirmar reserva',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.titulo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total a pagar: \$${precio.toString()}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.subtitulo,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.principal,
                    ),
                    onPressed: () {

                      _mostrarDialogReserva(context);


                    },
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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

    print(">>> ID recibido del viaje: ${travel.id}");

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(viajeRef);

      if (!snapshot.exists) throw Exception("El viaje no existe");
      final data = snapshot.data()!;

      int plazasDisponibles = data['plazasDisponibles'];
      if (plazasDisponibles < cantidadPlazas) {
        throw Exception("No hay suficientes plazas disponibles");
      }

      List usuarios = List.from(data['usuarios'] ?? []);
      // Cada elemento será un mapa { id: userId, plazas: cantidad }
      usuarios.add({
        'id': user.uid,
        'plazas': cantidadPlazas,
      });

      transaction.update(viajeRef, {
        'usuarios': usuarios,
        'plazasDisponibles': plazasDisponibles - cantidadPlazas,
      });
    });

    // Si todo sale bien:
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reserva confirmada ✅")),
      );

      // Espera un segundo y navega a la pantalla de “Mis viajes”
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MisViajesScreen()),
      );
    }

    print(">>> Reserva confirmada correctamente ✅");
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Reserva confirmada ✅")),
                );
              },
            ),
          ],
        );
      },
    );
  }



}
