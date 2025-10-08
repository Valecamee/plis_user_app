import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/travel_model.dart';
import '../utils/app_colors.dart';

/// Widget que muestra un mapa con la ruta del viaje
/// usando Google Maps y la polyline almacenada en Firebase
class RouteMapWidget extends StatefulWidget {
  final Travel travel;
  final double height;

  const RouteMapWidget({
    Key? key,
    required this.travel,
    this.height = 250,
  }) : super(key: key);

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // Crear marcadores
      _createMarkers();

      // Crear polyline si existe
      if (widget.travel.polyline != null && widget.travel.polyline!.isNotEmpty) {
        _createPolyline();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error inicializando mapa: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createMarkers() {
    if (widget.travel.origenLat != null && widget.travel.origenLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(widget.travel.origenLat!, widget.travel.origenLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Origen',
            snippet: widget.travel.origen,
          ),
        ),
      );
    }

    if (widget.travel.destinoLat != null && widget.travel.destinoLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(widget.travel.destinoLat!, widget.travel.destinoLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destino',
            snippet: widget.travel.destino,
          ),
        ),
      );
    }
  }

  void _createPolyline() {
    if (widget.travel.polyline == null) return;

    try {
      // Decodificar la polyline
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(widget.travel.polyline!);

      // Convertir a LatLng
      List<LatLng> polylineCoordinates = result
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      // Crear la polyline
      Polyline polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: AppColors.principal,
        width: 5,
        points: polylineCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );

      setState(() {
        _polylines.add(polyline);
      });
    } catch (e) {
      print('Error creando polyline: $e');
    }
  }

  LatLng _getCenter() {
    if (widget.travel.origenLat != null &&
        widget.travel.origenLng != null &&
        widget.travel.destinoLat != null &&
        widget.travel.destinoLng != null) {
      // Centro entre origen y destino
      double centerLat = (widget.travel.origenLat! + widget.travel.destinoLat!) / 2;
      double centerLng = (widget.travel.origenLng! + widget.travel.destinoLng!) / 2;
      return LatLng(centerLat, centerLng);
    }
    // Coordenadas por defecto (Bogotá, Colombia)
    return const LatLng(4.7110, -74.0721);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Ajustar cámara para mostrar toda la ruta
    if (widget.travel.origenLat != null &&
        widget.travel.origenLng != null &&
        widget.travel.destinoLat != null &&
        widget.travel.destinoLng != null) {
      _fitBounds();
    }
  }

  Future<void> _fitBounds() async {
    if (_mapController == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.travel.origenLat! < widget.travel.destinoLat!
            ? widget.travel.origenLat!
            : widget.travel.destinoLat!,
        widget.travel.origenLng! < widget.travel.destinoLng!
            ? widget.travel.origenLng!
            : widget.travel.destinoLng!,
      ),
      northeast: LatLng(
        widget.travel.origenLat! > widget.travel.destinoLat!
            ? widget.travel.origenLat!
            : widget.travel.destinoLat!,
        widget.travel.origenLng! > widget.travel.destinoLng!
            ? widget.travel.origenLng!
            : widget.travel.destinoLng!,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay coordenadas, mostrar mensaje
    if (widget.travel.origenLat == null || widget.travel.destinoLat == null) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.gris50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.map_outlined, size: 48, color: AppColors.gris400),
              SizedBox(height: 16),
              Text(
                'Mapa no disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.titulo,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No hay información de ubicación para este viaje',
                style: TextStyle(fontSize: 14, color: AppColors.subtitulo),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            // Mapa
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _getCenter(),
                zoom: 10,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            // Información de ruta superpuesta
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route, color: AppColors.principal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.travel.distanciaTexto ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.titulo,
                            ),
                          ),
                          Text(
                            'Duración: ${widget.travel.duracionTexto ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.subtitulo,
                            ),
                          ),
                        ],
                      ),
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
}
