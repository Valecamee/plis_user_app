import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../services/search_service.dart';

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

  // Filtros
  String? _selectedOrigen;
  String? _selectedDestino;
  double? _precioMaximo;
  DateTime? _selectedFecha;
  TimeOfDay? _horaMinima;
  TimeOfDay? _horaMaxima;
  int? _asientosMinimos;

  // Datos para dropdowns
  List<String> _origenes = [];
  List<String> _destinos = [];
  double _minPrice = 0;
  double _maxPrice = 100000;

  bool _showFilters = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Carga datos para los filtros (orígenes, destinos, precios)
  Future<void> _loadFilterData() async {
    setState(() => _isLoadingData = true);

    try {
      final results = await Future.wait([
        SearchService.getAvailableOrigins(),
        SearchService.getAvailableDestinations(),
        SearchService.getPriceRange(),
      ]);

      setState(() {
        _origenes = results[0] as List<String>;
        _destinos = results[1] as List<String>;
        final priceRange = results[2] as Map<String, double>;
        _minPrice = priceRange['min']!;
        _maxPrice = priceRange['max']!;
        _precioMaximo = _maxPrice;
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error cargando datos de filtros: $e');
      setState(() => _isLoadingData = false);
    }
  }

  /// Ejecuta la búsqueda con los filtros actuales
  void _performSearch() {
    final filters = <String, dynamic>{};

    if (_searchController.text.isNotEmpty) {
      filters['searchText'] = _searchController.text;
    }
    if (_selectedOrigen != null) {
      filters['origen'] = _selectedOrigen;
    }
    if (_selectedDestino != null) {
      filters['destino'] = _selectedDestino;
    }
    if (_precioMaximo != null && _precioMaximo! < _maxPrice) {
      filters['precioMaximo'] = _precioMaximo;
    }
    if (_selectedFecha != null) {
      filters['fecha'] = _selectedFecha;
    }
    if (_horaMinima != null) {
      filters['horaMinima'] = _horaMinima;
    }
    if (_horaMaxima != null) {
      filters['horaMaxima'] = _horaMaxima;
    }
    if (_asientosMinimos != null && _asientosMinimos! > 0) {
      filters['asientosMinimos'] = _asientosMinimos;
    }


    // Oculta los filtros al buscar
    setState(() {
      _showFilters = false;
    });

    widget.onSearch(
      _searchController.text,
      filters,
    );

  }

  /// Limpia todos los filtros
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedOrigen = null;
      _selectedDestino = null;
      _precioMaximo = _maxPrice;
      _selectedFecha = null;
      _horaMinima = null;
      _horaMaxima = null;
      _asientosMinimos = null;
      _showFilters = false;
    });

    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  /// Selector de fecha
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.principal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedFecha = picked);
    }
  }

  /// Selector de hora
  Future<void> _selectTime(bool isMinima) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMinima
          ? (_horaMinima ?? TimeOfDay.now())
          : (_horaMaxima ?? const TimeOfDay(hour: 23, minute: 59)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.principal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMinima) {
          _horaMinima = picked;
        } else {
          _horaMaxima = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Barra de búsqueda principal
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
                    decoration: const InputDecoration(
                      hintText: '¿A dónde quieres ir?',
                      hintStyle: TextStyle(color: AppColors.gris400, fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_alt : Icons.tune,
                    color: _showFilters ? AppColors.principal : AppColors.gris400,
                  ),
                  onPressed: () {
                    setState(() => _showFilters = !_showFilters);
                  },
                ),
              ],
            ),
          ),

          // Panel de filtros avanzados
          if (_showFilters) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        'Filtros avanzados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.titulo,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Origen y Destino
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'Origen',
                          value: _selectedOrigen,
                          items: _origenes,
                          onChanged: (value) => setState(() => _selectedOrigen = value),
                          icon: Icons.radio_button_checked,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildDropdown(
                          label: 'Destino',
                          value: _selectedDestino,
                          items: _destinos,
                          onChanged: (value) => setState(() => _selectedDestino = value),
                          icon: Icons.location_on,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Fecha
                  _buildDateSelector(),
                  const SizedBox(height: 5),

                  // Precio máximo
                  _buildPriceSlider(),
                  const SizedBox(height: 5),

                  // Hora mínima y máxima
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'Hora desde',
                          time: _horaMinima,
                          onTap: () => _selectTime(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeSelector(
                          label: 'Hora hasta',
                          time: _horaMaxima,
                          onTap: () => _selectTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Asientos mínimos
                  _buildSeatsSelector(),
                  const SizedBox(height: 20),

                  // Botón de búsqueda
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.principal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Buscar viajes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,

                        ),
                      ),

                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );

  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.titulo,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gris300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.gris400),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    hint: Text('Seleccionar', style: TextStyle(color: AppColors.gris400)),
                    isExpanded: true,
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha del viaje',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.titulo,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gris300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.gris400),
                const SizedBox(width: 12),
                Text(
                  _selectedFecha != null
                      ? '${_selectedFecha!.day.toString().padLeft(2, '0')}/${_selectedFecha!.month.toString().padLeft(2, '0')}/${_selectedFecha!.year}'
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    color: _selectedFecha != null ? AppColors.titulo : AppColors.gris400,
                  ),
                ),
                const Spacer(),
                if (_selectedFecha != null)
                  GestureDetector(
                    onTap: () => setState(() => _selectedFecha = null),
                    child: const Icon(Icons.close, size: 18, color: AppColors.gris400),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Precio máximo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.titulo,
              ),
            ),
            Text(
              '\$${_precioMaximo?.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.principal,
              ),
            ),
          ],
        ),
        Slider(
          value: _precioMaximo ?? _maxPrice,
          min: _minPrice,
          max: _maxPrice,
          divisions: 20,
          activeColor: AppColors.principal,
          onChanged: (value) {
            setState(() => _precioMaximo = value);
          },
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.titulo,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gris300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: AppColors.gris400),
                const SizedBox(width: 8),
                Text(
                  time != null
                      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                      : '--:--',
                  style: TextStyle(
                    color: time != null ? AppColors.titulo : AppColors.gris400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Asientos mínimos necesarios',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.titulo,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final seats = index + 1;
            final isSelected = _asientosMinimos == seats;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _asientosMinimos = isSelected ? null : seats;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.principal.withOpacity(0.1)
                          : Colors.transparent,
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
            );
          }),
        ),
      ],
    );
  }
}