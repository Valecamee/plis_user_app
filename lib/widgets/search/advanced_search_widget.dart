// language: dart
// lib/widgets/search/advanced_search_widget.dart
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/keyboard_utils.dart';
import '../../services/search_service.dart';
import 'autocomplete_field.dart';

/// Widget de búsqueda avanzada con filtros múltiples
class AdvancedSearchWidget extends StatefulWidget {
  final Function(String query, Map<String, dynamic> filters) onSearch;
  final VoidCallback? onClear;

  const AdvancedSearchWidget({
    Key? key,
    required this.onSearch,
    this.onClear,
  }) : super(key: key);

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Filtros
  String? _selectedOrigen;
  String? _selectedDestino;
  DateTime? _selectedFecha;
  TimeOfDay? _horaMinima;
  TimeOfDay? _horaMaxima;
  int? _asientosMinimos;

  // Datos para dropdowns
  List<String> _origenes = [];
  List<String> _destinos = [];

  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFilterData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait([
        SearchService.getAvailableOrigins(),
        SearchService.getAvailableDestinations(),
      ]);
      setState(() {
        // Limpiar y extraer solo nombres de ciudades
        _origenes = _cleanCityNames(results[0] as List<String>);
        _destinos = _cleanCityNames(results[1] as List<String>);
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error cargando datos de filtros: $e');
      setState(() => _isLoadingData = false);
    }
  }

  /// Limpia y extrae solo los nombres de ciudades principales
  /// Ejemplo: "Cali, Valle del Cauca, Colombia" -> "Cali"
  ///          "Av Caracas #40a-39, Bogotá" -> "Bogotá"
  List<String> _cleanCityNames(List<String> rawLocations) {
    Set<String> cleanedCities = {};
    
    for (String location in rawLocations) {
      // Intentar extraer el nombre de la ciudad
      String cityName = _extractCityName(location);
      if (cityName.isNotEmpty) {
        cleanedCities.add(cityName);
      }
    }
    
    // Convertir a lista y ordenar alfabéticamente
    List<String> sortedCities = cleanedCities.toList()..sort();
    return sortedCities;
  }

  /// Extrae el nombre de la ciudad de una dirección completa
  String _extractCityName(String location) {
    // Eliminar espacios extra
    String cleaned = location.trim();
    
    // Si contiene coma, tomar la primera parte antes de la coma
    // "Cali, Valle del Cauca" -> "Cali"
    if (cleaned.contains(',')) {
      List<String> parts = cleaned.split(',');
      
      // Si la primera parte parece una dirección (contiene #, números al inicio)
      // tomar la segunda parte
      String firstPart = parts[0].trim();
      if (firstPart.contains('#') || firstPart.contains('Calle') || 
          firstPart.contains('Carrera') || firstPart.contains('Av ') ||
          RegExp(r'^\d').hasMatch(firstPart)) {
        // Es una dirección, tomar la segunda parte si existe
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }
      
      // Si no, la primera parte es la ciudad
      return firstPart;
    }
    
    // Si no tiene coma, retornar tal cual (probablemente ya es solo ciudad)
    return cleaned;
  }

  void _performSearch() {
    // Usar KeyboardUtils para cerrar el teclado de forma segura
    KeyboardUtils.hideKeyboardAndThen(
      context,
      () {
        final filters = <String, dynamic>{};
        if (_searchController.text.isNotEmpty) filters['searchText'] = _searchController.text;
        if (_selectedOrigen != null) filters['origen'] = _selectedOrigen;
        if (_selectedDestino != null) filters['destino'] = _selectedDestino;
        if (_selectedFecha != null) filters['fecha'] = _selectedFecha;
        if (_horaMinima != null) filters['horaMinima'] = _horaMinima;
        if (_horaMaxima != null) filters['horaMaxima'] = _horaMaxima;
        if (_asientosMinimos != null && _asientosMinimos! > 0) filters['asientosMinimos'] = _asientosMinimos;

        widget.onSearch(_searchController.text, filters);
      },
      delayMs: 100, // Delay más corto para búsqueda
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedOrigen = null;
      _selectedDestino = null;
      _selectedFecha = null;
      _horaMinima = null;
      _horaMaxima = null;
      _asientosMinimos = null;
    });
    if (widget.onClear != null) widget.onClear!();
  }

  Future<void> _selectDate(StateSetter setModalState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.principal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedFecha = picked);
      setModalState(() => _selectedFecha = picked);
    }
  }

  Future<void> _selectTime(bool isMinima, StateSetter setModalState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMinima
          ? (_horaMinima ?? TimeOfDay.now())
          : (_horaMaxima ?? const TimeOfDay(hour: 23, minute: 59)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.principal),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMinima) _horaMinima = picked;
        else _horaMaxima = picked;
      });
      setModalState(() {
        if (isMinima) _horaMinima = picked;
        else _horaMaxima = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.principal),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: '¿A dónde quieres ir?',
                hintStyle: TextStyle(color: AppColors.gris400, fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) {
                KeyboardUtils.hideKeyboard(context);
                _performSearch();
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: AppColors.gris400,
            ),
            onPressed: () => _openFiltersModal(context),
          ),
        ],
      ),
    );
  }

  void _openFiltersModal(BuildContext context) {
    KeyboardUtils.hideKeyboard(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFiltersModal(context),
    );
  }

  Widget _buildFiltersModal(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle del modal
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gris300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtros avanzados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.titulo,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Contenido con scroll
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [

                            // Origen y Destino
                            Row(
                              children: [
                                Expanded(
                                  child: AutocompleteField(
                                    label: 'Origen',
                                    hint: 'Seleccionar origen',
                                    icon: Icons.radio_button_checked,
                                    options: _origenes,
                                    initialValue: _selectedOrigen,
                                    onChanged: (value) {
                                      setState(() => _selectedOrigen = value);
                                      setModalState(() => _selectedOrigen = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AutocompleteField(
                                    label: 'Destino',
                                    hint: 'Seleccionar destino',
                                    icon: Icons.location_on,
                                    options: _destinos,
                                    initialValue: _selectedDestino,
                                    onChanged: (value) {
                                      setState(() => _selectedDestino = value);
                                      setModalState(() => _selectedDestino = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Fecha
                            _buildDateSelector(setModalState),
                            const SizedBox(height: 12),

                        // Hora mínima y máxima
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Hora desde', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.titulo)),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _selectTime(true, setModalState),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.gris300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 18, color: AppColors.gris400),
                                            const SizedBox(width: 8),
                                            Text(
                                              _horaMinima != null ? '${_horaMinima!.hour.toString().padLeft(2, '0')}:${_horaMinima!.minute.toString().padLeft(2, '0')}' : '--:--',
                                              style: TextStyle(color: _horaMinima != null ? AppColors.titulo : AppColors.gris400),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Hora hasta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.titulo)),
                                  const SizedBox(height: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _selectTime(false, setModalState),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.gris300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 18, color: AppColors.gris400),
                                            const SizedBox(width: 8),
                                            Text(
                                              _horaMaxima != null ? '${_horaMaxima!.hour.toString().padLeft(2, '0')}:${_horaMaxima!.minute.toString().padLeft(2, '0')}' : '--:--',
                                              style: TextStyle(color: _horaMaxima != null ? AppColors.titulo : AppColors.gris400),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Asientos mínimos
                        _buildSeatsSelector(setModalState),
                        const SizedBox(height: 100), // Espacio para el botón fijo
                      ],
                    ),
                  ),
                  // Botones fijos en la parte inferior
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedOrigen = null;
                                _selectedDestino = null;
                                _selectedFecha = null;
                                _horaMinima = null;
                                _horaMaxima = null;
                                _asientosMinimos = null;
                              });
                              setModalState(() {
                                _selectedOrigen = null;
                                _selectedDestino = null;
                                _selectedFecha = null;
                                _horaMinima = null;
                                _horaMaxima = null;
                                _asientosMinimos = null;
                              });
                              if (widget.onClear != null) widget.onClear!();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.principal),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Limpiar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.principal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _performSearch();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.principal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Aplicar filtros',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha del viaje',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.titulo),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectDate(setModalState),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gris300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: AppColors.gris400),
                  const SizedBox(width: 12),
                  Text(
                    _selectedFecha != null
                        ? '${_selectedFecha!.day.toString().padLeft(2, '0')}/${_selectedFecha!.month.toString().padLeft(2, '0')}/${_selectedFecha!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(color: _selectedFecha != null ? AppColors.titulo : AppColors.gris400),
                  ),
                  const Spacer(),
                  if (_selectedFecha != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.gris400),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _selectedFecha = null);
                        setModalState(() => _selectedFecha = null);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatsSelector(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Asientos mínimos necesarios', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.titulo)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (index) {
            final seats = index + 1;
            final isSelected = _asientosMinimos == seats;
            
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() => _asientosMinimos = isSelected ? null : seats);
                      setModalState(() => _asientosMinimos = isSelected ? null : seats);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.principal.withOpacity(0.1) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.principal : AppColors.gris300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$seats',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? AppColors.principal : AppColors.titulo,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
