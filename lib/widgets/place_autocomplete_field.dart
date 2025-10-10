import 'package:flutter/material.dart';
import '../../services/google_places_service.dart';

class PlaceAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final Function(PlaceDetails) onPlaceSelected;
  final String? Function(String?)? validator;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onPlaceSelected,
    this.validator,
  });

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  final GooglePlacesService _placesService = GooglePlacesService();
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _isSelectingPlace = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    // No buscar si estamos en proceso de selección
    if (_isSelectingPlace) return;

    final text = widget.controller.text;
    if (text.isEmpty) {
      _removeOverlay();
      setState(() {
        _predictions = [];
      });
      return;
    }

    _searchPlaces(text);
  }

  Future<void> _searchPlaces(String query) async {
    print('🔎 PlaceAutocompleteField: Buscando "$query"');

    setState(() {
      _isLoading = true;
    });

    final predictions = await _placesService.getPlacePredictions(query);

    print('📋 PlaceAutocompleteField: Recibidas ${predictions.length} predicciones');

    if (!mounted) return;

    setState(() {
      _predictions = predictions;
      _isLoading = false;
    });

    if (predictions.isNotEmpty) {
      print('✨ PlaceAutocompleteField: Mostrando overlay con sugerencias');
      _showOverlay();
    } else {
      print('❌ PlaceAutocompleteField: Sin resultados, ocultando overlay');
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Color(0xFF6366F1)),
                    title: Text(
                      prediction.mainText,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      prediction.secondaryText,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    onTap: () => _selectPlace(prediction),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    // Marcar que estamos seleccionando para evitar búsquedas automáticas
    _isSelectingPlace = true;
    _removeOverlay();

    widget.controller.text = prediction.description;

    setState(() {
      _isLoading = true;
      _predictions = [];
    });

    final placeDetails = await _placesService.getPlaceDetails(prediction.placeId);

    setState(() {
      _isLoading = false;
    });

    if (placeDetails != null) {
      widget.onPlaceSelected(placeDetails);
    }

    // Restablecer después de un pequeño delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _isSelectingPlace = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: const TextStyle(color: Color(0xFF6366F1)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
          suffixIcon: _isLoading
              ? const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : null,
        ),
        validator: widget.validator,
      ),
    );
  }
}
