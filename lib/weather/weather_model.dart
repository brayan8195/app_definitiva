/// Modelo de datos que representa la información del clima
/// obtenida desde la API de OpenWeatherMap.
class WeatherModel {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int pressure;
  final int humidity;
  final double windSpeed;
  final int visibility;
  final String description;
  final String icon;
  final DateTime timestamp;

  const WeatherModel({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.pressure,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
    required this.description,
    required this.icon,
    required this.timestamp,
  });

  /// Factory constructor que parsea el JSON de la API de OpenWeatherMap.
  /// El JSON tiene la siguiente estructura relevante:
  /// {
  ///   "name": "Bucaramanga",
  ///   "sys": { "country": "CO" },
  ///   "main": { "temp": 25.3, "feels_like": 26.1, ... },
  ///   "wind": { "speed": 3.2 },
  ///   "visibility": 10000,
  ///   "weather": [{ "description": "...", "icon": "..." }]
  /// }
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List<dynamic>;
    final weatherInfo = weatherList.first as Map<String, dynamic>;

    return WeatherModel(
      cityName: json['name'] as String? ?? 'Unknown',
      country: (json['sys'] as Map<String, dynamic>?)?['country'] as String? ?? '',
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      tempMin: (main['temp_min'] as num).toDouble(),
      tempMax: (main['temp_max'] as num).toDouble(),
      pressure: (main['pressure'] as num).toInt(),
      humidity: (main['humidity'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
      // La visibilidad viene en metros; se convierte a km dividiendo entre 1000
      visibility: (json['visibility'] as num?)?.toInt() ?? 0,
      description: weatherInfo['description'] as String? ?? '',
      icon: weatherInfo['icon'] as String? ?? '01d',
      timestamp: DateTime.now(),
    );
  }

  /// Devuelve la visibilidad en kilómetros para mostrar en la UI
  double get visibilityKm => visibility / 1000.0;

  /// URL del ícono del clima proporcionado por OpenWeatherMap
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  /// Nombre completo con país: "Bucaramanga, CO"
  String get fullLocation => country.isNotEmpty ? '$cityName, $country' : cityName;
}
