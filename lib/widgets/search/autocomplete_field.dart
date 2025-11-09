// lib/widgets/search/autocomplete_field.dart
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Widget de autocompletado personalizado para origen y destino
/// Muestra sugerencias mientras el usuario escribe
class AutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<String> options;
  final String? initialValue;
  final Function(String?) onChanged;
  final TextEditingController? controller;

  const AutocompleteField({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.onChanged,
    this.initialValue,
    this.controller,
  }) : super(key: key);

  @override
  State<AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<AutocompleteField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.titulo,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            
            // Filtrar opciones que contengan el texto (sin tildes, case-insensitive)
            return widget.options.where((String option) {
              return _normalizeText(option).contains(_normalizeText(textEditingValue.text));
            }).take(5); // Mostrar máximo 5 sugerencias
          },
          onSelected: (String selection) {
            _controller.text = selection;
            widget.onChanged(selection);
            _focusNode.unfocus();
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Sincronizar con el controller externo
            if (_controller.text != fieldTextEditingController.text) {
              fieldTextEditingController.text = _controller.text;
            }
            
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gris300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(color: AppColors.gris400, fontSize: 14),
                  prefixIcon: Icon(widget.icon, size: 20, color: AppColors.gris400),
                  suffixIcon: fieldTextEditingController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.gris400),
                          onPressed: () {
                            fieldTextEditingController.clear();
                            _controller.clear();
                            widget.onChanged(null);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                onChanged: (value) {
                  _controller.text = value;
                  widget.onChanged(value.isEmpty ? null : value);
                  setState(() {}); // Para actualizar el botón de limpiar
                },
                onSubmitted: (_) => onFieldSubmitted(),
              ),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 150, // Reducido para evitar overflow
                    maxWidth: 300,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: options.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Icon(widget.icon, size: 18, color: AppColors.principal),
                        title: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.titulo,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Normaliza texto para comparación (sin tildes, minúsculas)
  String _normalizeText(String text) {
    String normalized = text.toLowerCase().trim();
    const Map<String, String> accentMap = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ñ': 'n', 'ü': 'u',
    };
    accentMap.forEach((accented, plain) {
      normalized = normalized.replaceAll(accented, plain);
    });
    return normalized;
  }
}
