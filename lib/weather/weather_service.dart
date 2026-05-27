import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'weather_model.dart';

/// Servicio responsable de consumir la API de OpenWeatherMap.
/// Encapsula toda la lógica de red para mantener el código limpio.
class WeatherService {
  // ⚠️ IMPORTANTE: Reemplaza esta clave con tu API key de OpenWeatherMap.
  // Regístrate gratis en: https://openweathermap.org/api
  static const String _apiKey = 'ac1d8b576ae5a3969884df4c56c61ac7';

  // URL base de la API de clima actual
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // URL de la API de geocodificación inversa (para obtener ciudad por coordenadas)
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0/reverse';

  // Tiempo de espera máximo para las peticiones HTTP
  static const Duration _timeout = Duration(seconds: 15);

  /// Obtiene el clima actual para las coordenadas dadas.
  ///
  /// [lat] - Latitud (ej: 7.1198 para Bucaramanga)
  /// [lon] - Longitud (ej: -73.1227 para Bucaramanga)
  ///
  /// Retorna un [WeatherModel] con todos los datos del clima.
  /// Lanza un [WeatherException] en caso de error.
  Future<WeatherModel> fetchWeather({
    required double lat,
    required double lon,
  }) async {
    // Construimos la URL con los parámetros requeridos:
    // - lat, lon: coordenadas geográficas
    // - appid: nuestra clave de API
    // - units=metric: para recibir temperatura en Celsius
    // - lang=es: para descripciones en español
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'appid': _apiKey,
      'units': 'metric',
      'lang': 'es',
    });

    try {
      // Realizamos la petición GET de forma asíncrona con timeout
      // El await suspende la ejecución hasta que la petición complete
      final response = await http.get(uri).timeout(_timeout);

      // Verificamos el código de respuesta HTTP
      if (response.statusCode == 200) {
        // Decodificamos el JSON de la respuesta
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        // Convertimos el mapa JSON en nuestro modelo de datos
        return WeatherModel.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw WeatherException(
          'API Key inválida. Por favor verifica tu clave de OpenWeatherMap.',
          WeatherErrorType.invalidApiKey,
        );
      } else if (response.statusCode == 404) {
        throw WeatherException(
          'Ubicación no encontrada.',
          WeatherErrorType.locationNotFound,
        );
      } else if (response.statusCode == 429) {
        throw WeatherException(
          'Límite de peticiones excedido. Intenta más tarde.',
          WeatherErrorType.rateLimitExceeded,
        );
      } else {
        throw WeatherException(
          'Error del servidor (${response.statusCode}).',
          WeatherErrorType.serverError,
        );
      }
    } on SocketException {
      // No hay conexión a internet
      throw WeatherException(
        'Sin conexión a internet. Verifica tu red.',
        WeatherErrorType.noConnection,
      );
    } on HttpException {
      throw WeatherException(
        'Error de comunicación HTTP.',
        WeatherErrorType.serverError,
      );
    } on FormatException {
      // El JSON recibido no tiene el formato esperado
      throw WeatherException(
        'Error al procesar la respuesta del servidor.',
        WeatherErrorType.parseError,
      );
    }
  }

  /// Busca el clima de una ciudad por nombre usando la API de geocodificación.
  /// Primero convierte el nombre de ciudad a coordenadas, luego obtiene el clima.
  Future<WeatherModel> fetchWeatherByCity(String cityName) async {
    final geoUri = Uri.parse(
      'https://api.openweathermap.org/geo/1.0/direct',
    ).replace(queryParameters: {
      'q': cityName,
      'limit': '1',
      'appid': _apiKey,
    });

    try {
      final geoResponse = await http.get(geoUri).timeout(_timeout);

      if (geoResponse.statusCode == 200) {
        final List<dynamic> geoData = jsonDecode(geoResponse.body);
        if (geoData.isEmpty) {
          throw WeatherException(
            'Ciudad "$cityName" no encontrada.',
            WeatherErrorType.locationNotFound,
          );
        }
        final location = geoData.first as Map<String, dynamic>;
        final lat = (location['lat'] as num).toDouble();
        final lon = (location['lon'] as num).toDouble();
        // Una vez obtenidas las coordenadas, consultamos el clima
        return fetchWeather(lat: lat, lon: lon);
      } else {
        throw WeatherException(
          'Error buscando la ciudad.',
          WeatherErrorType.serverError,
        );
      }
    } on SocketException {
      throw WeatherException(
        'Sin conexión a internet.',
        WeatherErrorType.noConnection,
      );
    }
  }
}

/// Tipos de error posibles al consultar el clima
enum WeatherErrorType {
  noConnection,
  invalidApiKey,
  locationNotFound,
  rateLimitExceeded,
  serverError,
  parseError,
}

/// Excepción personalizada para errores del servicio de clima
class WeatherException implements Exception {
  final String message;
  final WeatherErrorType type;

  const WeatherException(this.message, this.type);

  @override
  String toString() => 'WeatherException: $message';
}
