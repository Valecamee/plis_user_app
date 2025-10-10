// lib/widgets/busqueda_resultados_widget.dart
import 'package:flutter/material.dart';
import '../models/travel_model.dart';
import '../utils/app_colors.dart';


// En busqueda_resultados_widget.dart
class BusquedaResultadosWidget extends StatelessWidget {
  final List<Travel> travels;
  final Widget Function(Travel) viajeCardBuilder;
  final VoidCallback onClose;

  const BusquedaResultadosWidget({
    Key? key,
    required this.travels,
    required this.viajeCardBuilder,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Mismos márgenes y decoración que AdvancedSearchWidget
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
          if (travels.isEmpty)
            const Center(
              child: Text('No se encontraron viajes'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: travels.length,
              itemBuilder: (context, index) {
                final viaje = travels[index];
                return viajeCardBuilder(viaje);
              },
            ),
        ],
      ),
    );
  }
}
