import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: json['structured_formatting']?['main_text'] ?? '',
      secondaryText: json['structured_formatting']?['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final double latitude;
  final double longitude;
  final String formattedAddress;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']?['location'];
    return PlaceDetails(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      latitude: location?['lat']?.toDouble() ?? 0.0,
      longitude: location?['lng']?.toDouble() ?? 0.0,
      formattedAddress: json['formatted_address'] ?? '',
    );
  }
}

class GooglePlacesService {
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Obtiene predicciones de lugares basadas en el texto ingresado
  /// Usa la API de Places Autocomplete (New)
  Future<List<PlacePrediction>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    if (_apiKey.isEmpty) {
      throw Exception('Google Maps API Key no configurada. Verifica tu archivo .env');
    }

    try {
      // Usando la API de Autocomplete clásica
      final url = Uri.parse(
        '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&language=es&components=country:co',
      );

      print('🔍 Buscando lugares: $input');
      print('📍 URL: ${url.toString().replaceAll(_apiKey, 'API_KEY_HIDDEN')}');

      final response = await http.get(url);

      print('📡 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('📦 Response status: ${data['status']}');

        if (data['status'] == 'OK') {
          final predictions = (data['predictions'] as List)
              .map((prediction) => PlacePrediction.fromJson(prediction))
              .toList();
          print('✅ Encontradas ${predictions.length} sugerencias');
          return predictions;
        } else {
          print('⚠️ Error en Places API: ${data['status']}');
          if (data['error_message'] != null) {
            print('💬 Mensaje: ${data['error_message']}');
          }
          return [];
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('📄 Body: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Error al obtener predicciones: $e');
      print('📚 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Obtiene los detalles de un lugar específico usando su place_id
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey&language=es&fields=place_id,name,geometry,formatted_address',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        } else {
          print('Error en Place Details: ${data['status']}');
          return null;
        }
      } else {
        print('Error HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener detalles del lugar: $e');
      return null;
    }
  }
}
