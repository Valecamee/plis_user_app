// lib/widgets/busqueda_resultados_widget.dart
import 'package:flutter/material.dart';
import '../../models/travel_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/travel_card.dart';
import '../../screens/detalle_viaje_screen.dart';

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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    
    // Altura máxima: 55% del espacio disponible
    final maxHeight = (screenHeight - topPadding - bottomPadding) * 0.55;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título + botón cerrar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
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
          ),

          // Resultados con scroll
          if (travels.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No se encontraron viajes',
                  style: TextStyle(color: AppColors.subtitulo),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: travels.length,
                itemBuilder: (context, index) {
                  final viaje = travels[index];
                  return TravelCard(
                    viaje: viaje,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetalleViajeScreen(travel: viaje),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
