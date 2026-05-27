import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'weather_model.dart';
import 'weather_service.dart';
import 'gauge_widget.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();

  final TextEditingController _cityController = TextEditingController();

  WeatherModel? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  double _lat = 7.1198;
  double _lon = -73.1227;

  Timer? _refreshTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fetchWeatherByCoords();

    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _fetchWeatherByCoords();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cityController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherByCoords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await _weatherService.fetchWeather(lat: _lat, lon: _lon);
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
        _fadeController.forward(from: 0);
      }
    } on WeatherException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error inesperado. Por favor intenta de nuevo.';
        });
      }
    }
  }

  Future<void> _searchByCity() async {
    FocusScope.of(context).unfocus();
    final query = _cityController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await _weatherService.fetchWeatherByCity(query);
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
        _fadeController.forward(from: 0);
      }
    } on WeatherException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ciudad no encontrada. Intenta con otro nombre.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCitySearch(),
                if (_isLoading)
                  _buildLoadingState()
                else if (_errorMessage != null)
                  _buildErrorState()
                else if (_weatherData != null)
                  _buildWeatherContent(_weatherData!)
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A1628),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        tooltip: 'Volver al menú',
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 36),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A6B9A).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.wb_sunny_rounded,
                          color: Color(0xFFFFCC44),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _weatherData?.fullLocation ?? 'WeatherPro',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (_lastUpdated != null)
                            Text(
                              'Actualizado: ${_formatTime(_lastUpdated!)}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isLoading ? null : _fetchWeatherByCoords,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1A6B9A),
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white60,
                              ),
                        tooltip: 'Actualizar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCitySearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search_rounded, color: Color(0xFF5BC8F5), size: 16),
              SizedBox(width: 6),
              Text(
                'BUSCAR CIUDAD O PAÍS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchByCity(),
                  decoration: InputDecoration(
                    hintText: 'Ej: Bogotá, Madrid, Tokyo...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    prefixIcon: const Icon(Icons.location_city_rounded,
                        color: Colors.white38, size: 18),
                    suffixIcon: _cityController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.white38, size: 16),
                            onPressed: () {
                              _cityController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF5BC8F5), width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _searchByCity,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A6B9A), Color(0xFF0D4D73)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A6B9A).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Rápido: ',
                    style: TextStyle(color: Colors.white30, fontSize: 11)),
                const SizedBox(width: 6),
                ...[
                  'Bucaramanga',
                  'Bogotá',
                  'Medellín',
                  'Madrid',
                  'New York',
                  'Tokyo',
                ].map((city) => GestureDetector(
                      onTap: () {
                        _cityController.text = city;
                        _searchByCity();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5BC8F5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF5BC8F5).withOpacity(0.2)),
                        ),
                        child: Text(
                          city,
                          style: const TextStyle(
                            color: Color(0xFF5BC8F5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A6B9A)),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Obteniendo datos del clima...',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Error desconocido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchWeatherByCoords,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Intentar de nuevo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B9A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent(WeatherModel weather) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildTemperatureCard(weather),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'INDICADORES EN TIEMPO REAL',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GaugeWidget(
                        label: 'Humedad',
                        value: weather.humidity.toDouble(),
                        minValue: 0,
                        maxValue: 100,
                        unit: '%',
                        icon: Icons.water_drop_rounded,
                        zones: const [
                          GaugeZone(min: 0,  max: 30,  color: Color(0xFFE74C3C), label: 'Bajo'),
                          GaugeZone(min: 30, max: 70,  color: Color(0xFF2ECC71), label: 'Óptimo'),
                          GaugeZone(min: 70, max: 100, color: Color(0xFFF39C12), label: 'Alto'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GaugeWidget(
                        label: 'Viento',
                        value: weather.windSpeed,
                        minValue: 0,
                        maxValue: 30,
                        unit: 'm/s',
                        icon: Icons.air_rounded,
                        zones: const [
                          GaugeZone(min: 0,  max: 5,  color: Color(0xFF2ECC71), label: 'Calmo'),
                          GaugeZone(min: 5,  max: 15, color: Color(0xFFF39C12), label: 'Moderado'),
                          GaugeZone(min: 15, max: 30, color: Color(0xFFE74C3C), label: 'Fuerte'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GaugeWidget(
                        label: 'Visibilidad',
                        value: weather.visibilityKm,
                        minValue: 0,
                        maxValue: 10,
                        unit: 'km',
                        icon: Icons.visibility_rounded,
                        zones: const [
                          GaugeZone(min: 0, max: 2,  color: Color(0xFFE74C3C), label: 'Baja'),
                          GaugeZone(min: 2, max: 5,  color: Color(0xFFF39C12), label: 'Moderada'),
                          GaugeZone(min: 5, max: 10, color: Color(0xFF2ECC71), label: 'Buena'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GaugeWidget(
                        label: 'Presión',
                        value: weather.pressure.toDouble(),
                        minValue: 970,
                        maxValue: 1040,
                        unit: 'hPa',
                        icon: Icons.compress_rounded,
                        zones: const [
                          GaugeZone(min: 970,  max: 990,  color: Color(0xFFE74C3C), label: 'Baja'),
                          GaugeZone(min: 990,  max: 1020, color: Color(0xFF2ECC71), label: 'Normal'),
                          GaugeZone(min: 1020, max: 1040, color: Color(0xFFF39C12), label: 'Alta'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailsGrid(weather),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(WeatherModel weather) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A4B6E), Color(0xFF0D2137)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A6B9A).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6B9A).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weather.temperature.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                    height: 0.9,
                    letterSpacing: -4,
                  ),
                ),
                const Text(
                  'Celsius',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6B9A).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalize(weather.description),
                    style: const TextStyle(
                      color: Color(0xFF5BC8F5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTempRange(
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF5BC8F5),
                      value: weather.tempMin,
                      label: 'Mín',
                    ),
                    const SizedBox(width: 16),
                    _buildTempRange(
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFFF7043),
                      value: weather.tempMax,
                      label: 'Máx',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getWeatherEmoji(weather.icon),
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${weather.feelsLike.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Text(
                'Sensación',
                style: TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempRange({
    required IconData icon,
    required Color color,
    required double value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${value.toStringAsFixed(0)}°',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label,
                style: const TextStyle(color: Colors.white30, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsGrid(WeatherModel weather) {
    final details = [
      _DetailItem(icon: Icons.thermostat_rounded, label: 'Sensación',
          value: '${weather.feelsLike.toStringAsFixed(1)}°C', color: const Color(0xFFFF7043)),
      _DetailItem(icon: Icons.compress_rounded, label: 'Presión',
          value: '${weather.pressure} hPa', color: const Color(0xFF9B59B6)),
      _DetailItem(icon: Icons.water_drop_rounded, label: 'Humedad',
          value: '${weather.humidity}%', color: const Color(0xFF5BC8F5)),
      _DetailItem(icon: Icons.air_rounded, label: 'Viento',
          value: '${weather.windSpeed.toStringAsFixed(1)} m/s', color: const Color(0xFF2ECC71)),
      _DetailItem(icon: Icons.visibility_rounded, label: 'Visibilidad',
          value: '${weather.visibilityKm.toStringAsFixed(1)} km', color: const Color(0xFFF39C12)),
      _DetailItem(icon: Icons.arrow_downward_rounded, label: 'Temp. Mín',
          value: '${weather.tempMin.toStringAsFixed(1)}°C', color: const Color(0xFF3498DB)),
      _DetailItem(icon: Icons.arrow_upward_rounded, label: 'Temp. Máx',
          value: '${weather.tempMax.toStringAsFixed(1)}°C', color: const Color(0xFFE74C3C)),
      _DetailItem(icon: Icons.location_on_rounded, label: 'Ubicación',
          value: weather.fullLocation, color: const Color(0xFF1A6B9A)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'DETALLES METEOROLÓGICOS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: details.length,
            itemBuilder: (context, index) {
              final item = details[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A3A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: item.color.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.value,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                          Text(item.label,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _getWeatherEmoji(String iconCode) {
    final code = iconCode.replaceAll('d', '').replaceAll('n', '');
    const map = {
      '01': '☀️', '02': '🌤️', '03': '☁️', '04': '🌥️',
      '09': '🌧️', '10': '🌦️', '11': '⛈️', '13': '❄️', '50': '🌫️',
    };
    return map[code] ?? '🌡️';
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailItem({required this.icon, required this.label, required this.value, required this.color});
}
