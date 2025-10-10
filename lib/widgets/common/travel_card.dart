import 'package:flutter/material.dart';
import "../../models/travel_model.dart";
import "../../utils/app_colors.dart";

class TravelCard extends StatelessWidget {
  final Travel viaje;
  final VoidCallback? onTap;

  const TravelCard({
    Key? key,
    required this.viaje,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String origen = viaje.origen;
    String destino = viaje.destino;
    String conductorNombre = viaje.conductorNombre;
    String conductorApellido = viaje.conductorApellido;
    String fechaViaje = viaje.fechaFormateada;
    String horaViaje = viaje.horaFormateada;
    int plazasDisponibles = viaje.plazasDisponibles;
    double precio = viaje.precioPorAsiento ?? 0;

    return GestureDetector(
      onTap: onTap,
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Ruta y precio
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
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(origen,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                              width: 1,
                              height: 12,
                              color: AppColors.gris300),
                        ),
                        Row(
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(destino,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.principal),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info y conductor
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
                        '${conductorNombre.isNotEmpty ? conductorNombre[0] : ''}${conductorApellido.isNotEmpty ? conductorApellido[0] : ''}'
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$conductorNombre $conductorApellido',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(
                          '$fechaViaje • $horaViaje • $plazasDisponibles asientos',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.subtitulo),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.principal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('Reservar',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.principal)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
