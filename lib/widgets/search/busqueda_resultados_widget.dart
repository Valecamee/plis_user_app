// lib/widgets/busqueda_resultados_widget.dart
import 'package:flutter/material.dart';
import '../../models/travel_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/travel_card.dart'; // 👈 importa tu nuevo widget

class BusquedaResultadosWidget extends StatelessWidget {
  final List<Travel> travels;
  final VoidCallback onClose;

  const BusquedaResultadosWidget({
    Key? key,
    required this.travels,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + botón cerrar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resultados de la búsqueda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.titulo,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.gris400),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de resultados o mensaje vacío
          if (travels.isEmpty)
            const Center(
              child: Text(
                'No se encontraron viajes',
                style: TextStyle(color: AppColors.subtitulo),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: travels.length,
              itemBuilder: (context, index) {
                final viaje = travels[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      // ✅ Navegación al detalle del viaje
                      Navigator.pushNamed(
                        context,
                        '/detalleViaje',
                        arguments: viaje,
                      );
                    },
                    child: TravelCard(viaje: viaje), // 👈 usa el nuevo widget
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

