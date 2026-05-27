// ============================================================
// COLOMBIA EXPLORER APP — main.dart
// Una aplicación Flutter completa sobre Colombia
// Consume datos reales desde https://api-colombia.com/api/v1/
// Autor: Generado con Flutter + Dart
// ============================================================
//
// CONFIGURACIÓN PREVIA:
// 1. Agregar dependencia HTTP al pubspec.yaml:
//    flutter pub add http
//
// 2. Permisos de internet en android/app/src/main/AndroidManifest.xml
//    (justo antes de <application ...>):
//    <uses-permission android:name="android.permission.INTERNET"/>
//
// 3. Para web, no se requieren permisos adicionales.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================
// MODELO DE DATOS: Departamento
// Representa la estructura JSON que devuelve la API
// ============================================================
class Department {
  final int id;
  final String name;
  final String description;
  final String cityCapital;
  final int municipalities;
  final double surface;
  final int population;
  final String phonePrefix;
  final int countryId;
  final int regionId;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.cityCapital,
    required this.municipalities,
    required this.surface,
    required this.population,
    required this.phonePrefix,
    required this.countryId,
    required this.regionId,
  });

  // Factory constructor para construir desde JSON
  factory Department.fromJson(Map<String, dynamic> json) {
  String parseText(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;

    if (value is String) {
      return value;
    }

    if (value is Map) {
      if (value['es'] != null) return value['es'].toString();
      if (value['en'] != null) return value['en'].toString();
      if (value['name'] != null) return value['name'].toString();
      return value.values.isNotEmpty ? value.values.first.toString() : defaultValue;
    }

    return value.toString();
  }

  int parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  double parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  return Department(
    id: parseInt(json['id'], 0),
    name: parseText(json['name'], 'Sin nombre'),
    description: parseText(json['description'], 'Sin descripción disponible.'),
    cityCapital: parseText(json['cityCapital'], 'Sin capital'),
    municipalities: parseInt(json['municipalities'], 0),
    surface: parseDouble(json['surface'], 0),
    population: parseInt(json['population'], 0),
    phonePrefix: parseText(json['phonePrefix'], '0'),
    countryId: parseInt(json['countryId'], 1),
    regionId: parseInt(json['regionId'], 0),
  );
}

  // Nombre de región basado en regionId
  String get regionName {
    switch (regionId) {
      case 1: return 'Amazonía';
      case 2: return 'Andina';
      case 3: return 'Caribe';
      case 4: return 'Insular';
      case 5: return 'Orinoquía';
      case 6: return 'Pacífica';
      default: return 'Desconocida';
    }
  }

  // Color asociado a la región
  Color get regionColor {
    switch (regionId) {
      case 1: return const Color(0xFF2E7D32); // Verde Amazonía
      case 2: return const Color(0xFF1565C0); // Azul Andina
      case 3: return const Color(0xFF00838F); // Cian Caribe
      case 4: return const Color(0xFF6A1B9A); // Violeta Insular
      case 5: return const Color(0xFFE65100); // Naranja Orinoquía
      case 6: return const Color(0xFF00695C); // Verde Pacífica
      default: return const Color(0xFF546E7A);
    }
  }

  // Ícono asociado a la región
  IconData get regionIcon {
    switch (regionId) {
      case 1: return Icons.forest;
      case 2: return Icons.terrain;
      case 3: return Icons.beach_access;
      case 4: return Icons.waves;
      case 5: return Icons.grass;
      case 6: return Icons.water;
      default: return Icons.map;
    }
  }
}

// ============================================================
// MODELO: Atracción Turística (datos estáticos curados)
// ============================================================
class TouristAttraction {
  final String name;
  final String location;
  final String description;
  final IconData icon;
  final Color color;
  final String category;

  TouristAttraction({
    required this.name,
    required this.location,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
  });
}

// ============================================================
// SERVICIO DE API: Comunicación con api-colombia.com
// ============================================================
class ColombiaApiService {
  static const String _baseUrl = 'https://api-colombia.com/api/v1';

  // Obtener lista de departamentos
  static Future<List<Department>> getDepartments() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/Department'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
final List<dynamic> jsonData = json.decode(responseBody) as List<dynamic>;
        return jsonData.map((json) => Department.fromJson(json)).toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}

// ============================================================
// SCAFFOLD PRINCIPAL: Estructura base con Drawer y navegación
// ============================================================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with SingleTickerProviderStateMixin {
  // Índice de sección activa en el Drawer
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Títulos de secciones del Drawer
  final List<String> _sectionTitles = [
    'Información General',
    'Departamentos',
    'Regiones',
    'Atracciones Turísticas',
  ];

  final List<IconData> _sectionIcons = [
    Icons.info_outline,
    Icons.map_outlined,
    Icons.layers_outlined,
    Icons.camera_alt_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Cambiar sección activa con animación
  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _animController.reset();
      _animController.forward();
    });
    Navigator.pop(context); // Cerrar el drawer
  }

  // Construir la sección activa según índice seleccionado
  Widget _buildActiveSection() {
    switch (_selectedIndex) {
      case 0: return const GeneralInfoSection();
      case 1: return const DepartmentsSection();
      case 2: return const RegionsSection();
      case 3: return const TouristSection();
      default: return const GeneralInfoSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar con gradiente Colombia ──────────────────────
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFCD116), // Amarillo
                Color(0xFFFFE066),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🇨🇴', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              _sectionTitles[_selectedIndex],
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        actions: [
          // Botón de información sobre la app
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF003087)),
            onPressed: () => _showAppInfoDialog(context),
            tooltip: 'Acerca de la app',
          ),
          // Botón volver al menú principal
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Color(0xFF003087)),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver al menú',
          ),
        ],
      ),

      // ── Navigation Drawer ──────────────────────────────────
      drawer: _buildDrawer(context),

      // ── Cuerpo con animación de fade ───────────────────────
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildActiveSection(),
      ),

      // ── FloatingActionButton contextual ───────────────────
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Actualizando departamentos...'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF003087),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              backgroundColor: const Color(0xFF003087),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  // ── Construcción del Drawer lateral ──────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del Drawer con bandera de Colombia
            _buildDrawerHeader(),
            const SizedBox(height: 8),

            // Ítems del menú
            ...List.generate(_sectionTitles.length, (index) {
              return _buildDrawerItem(
                icon: _sectionIcons[index],
                title: _sectionTitles[index],
                index: index,
              );
            }),

            const Divider(color: Colors.white24, indent: 16, endIndent: 16),

            // Estadísticas rápidas en el drawer
            _buildDrawerStats(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFCD116), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Franjas de la bandera
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFCD116),
                  Color(0xFFFCD116),
                  Color(0xFF003087),
                  Color(0xFF003087),
                  Color(0xFFCE1126),
                  Color(0xFFCE1126),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Escudo simplificado
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('🇨🇴', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Colombia Explorer',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Text(
            '¡La respuesta de América!',
            style: TextStyle(
              color: Color(0xFF37474F),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? const Color(0xFFFCD116).withOpacity(0.15)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFFCD116) : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFCD116) : Colors.white70,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD116),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: () => _onDrawerItemTapped(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDrawerStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATOS RÁPIDOS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _buildStatRow(Icons.location_city, '32 Departamentos'),
          _buildStatRow(Icons.people, '~51 millones de hab.'),
          _buildStatRow(Icons.landscape, '1.141.748 km²'),
          _buildStatRow(Icons.language, 'Español oficial'),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🇨🇴', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text('Colombia Explorer'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplicación informativa sobre Colombia que consume datos reales desde api-colombia.com',
            ),
            SizedBox(height: 12),
            Text('Versión: 1.0.0', style: TextStyle(color: Colors.grey)),
            Text('API: api-colombia.com', style: TextStyle(color: Colors.grey)),
            Text('Flutter + Dart', style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECCIÓN 1: INFORMACIÓN GENERAL DE COLOMBIA
// ============================================================
class GeneralInfoSection extends StatelessWidget {
  const GeneralInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner principal con gradiente
          _buildHeroBanner(context),
          const SizedBox(height: 16),

          // Estadísticas en grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStatsGrid(context),
          ),
          const SizedBox(height: 16),

          // Información cultural
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCultureCard(context),
          ),
          const SizedBox(height: 16),

          // La bandera explicada
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFlagCard(context),
          ),
          const SizedBox(height: 16),

          // Geografía
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildGeographyCard(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003087), Color(0xFF0051C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '🇨🇴',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 12),
          const Text(
            'República de Colombia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFCD116),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '¡La respuesta de América!',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Franjas de la bandera decorativas
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFCD116),
                  Color(0xFFFCD116),
                  Color(0xFF003087),
                  Color(0xFF003087),
                  Color(0xFFCE1126),
                  Color(0xFFCE1126),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final stats = [
      {'icon': '🌆', 'value': 'Bogotá D.C.', 'label': 'Capital'},
      {'icon': '👥', 'value': '~51M', 'label': 'Habitantes'},
      {'icon': '📐', 'value': '1.14M km²', 'label': 'Superficie'},
      {'icon': '🗺️', 'value': '32', 'label': 'Departamentos'},
      {'icon': '💰', 'value': 'Peso (COP)', 'label': 'Moneda'},
      {'icon': '🌐', 'value': 'Español', 'label': 'Idioma oficial'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFFFCD116).withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stat['icon']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  stat['value']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF003087),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  stat['label']!,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCultureCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCE1126).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note,
                      color: Color(0xFFCE1126), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cultura y Patrimonio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Colombia es reconocida mundialmente por su extraordinaria diversidad cultural. '
              'Es la cuna del realismo mágico, con Gabriel García Márquez como máximo exponente. '
              'El vallenato, declarado Patrimonio de la Humanidad, llena el alma. '
              'La cumbia y el porro son ritmos que nacen de la mezcla afro, indígena y española.',
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('Vallenato 🎵', const Color(0xFFFCD116)),
                _buildTag('Cumbia 💃', const Color(0xFF003087)),
                _buildTag('García Márquez 📚', const Color(0xFFCE1126)),
                _buildTag('Café ☕', const Color(0xFF795548)),
                _buildTag('Esmeraldas 💎', const Color(0xFF2E7D32)),
                _buildTag('Orquídeas 🌸', const Color(0xFF6A1B9A)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD116).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag,
                      color: Color(0xFFB8860B), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'La Bandera Tricolor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Franja amarilla
            _buildFlagStripe(
              color: const Color(0xFFFCD116),
              meaning: 'AMARILLO — Riqueza del suelo, oro, soberanía',
              thickness: 36,
            ),
            // Franja azul
            _buildFlagStripe(
              color: const Color(0xFF003087),
              meaning: 'AZUL — Los ríos y mares que bañan Colombia',
              thickness: 18,
              textColor: Colors.white,
            ),
            // Franja roja
            _buildFlagStripe(
              color: const Color(0xFFCE1126),
              meaning: 'ROJO — La sangre de los héroes de la independencia',
              thickness: 18,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagStripe({
    required Color color,
    required String meaning,
    required double thickness,
    Color textColor = Colors.black87,
  }) {
    return Container(
      width: double.infinity,
      height: thickness,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        meaning,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildGeographyCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.terrain,
                      color: Color(0xFF2E7D32), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Geografía Única',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Colombia es el único país de Sudamérica con costas en el Océano Pacífico y en el Mar Caribe. '
              'Sus Andes se dividen en tres cordilleras: Occidental, Central y Oriental. '
              'Posee selvas amazónicas, llanos orientales, desiertos y arrecifes de coral.',
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildGeoItem(
                      '🏔️', 'Pico más alto', 'Cristóbal Colón\n5.775 m'),
                ),
                Expanded(
                  child: _buildGeoItem(
                      '🌊', 'Río principal', 'Magdalena\n1.528 km'),
                ),
                Expanded(
                  child: _buildGeoItem(
                      '🌳', 'Bosque', 'Amazonía\n35% del país'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeoItem(String emoji, String title, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================
// SECCIÓN 2: DEPARTAMENTOS (consume API real)
// ============================================================
class DepartmentsSection extends StatefulWidget {
  const DepartmentsSection({super.key});

  @override
  State<DepartmentsSection> createState() => _DepartmentsSectionState();
}

class _DepartmentsSectionState extends State<DepartmentsSection> {
  // Estado de carga de la lista
  List<Department> _departments = [];
  List<Department> _filteredDepartments = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name'; // Criterio de ordenamiento

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    // Escuchar cambios en el campo de búsqueda
    _searchController.addListener(_filterDepartments);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDepartments);
    _searchController.dispose();
    super.dispose();
  }

  // Consumir la API de departamentos
  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final departments = await ColombiaApiService.getDepartments();
      setState(() {
        _departments = departments;
        _filteredDepartments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Filtrar departamentos por nombre al escribir
  void _filterDepartments() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredDepartments = _departments
          .where((d) =>
    d.name.toLowerCase().contains(query) ||
    d.cityCapital.toLowerCase().contains(query) ||
    d.regionName.toLowerCase().contains(query))
.toList();
      _applySorting();
    });
  }

  // Aplicar ordenamiento a la lista filtrada
  void _applySorting() {
    switch (_sortBy) {
      case 'name':
        _filteredDepartments.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'population':
        _filteredDepartments
            .sort((a, b) => b.population.compareTo(a.population));
        break;
      case 'surface':
        _filteredDepartments.sort((a, b) => b.surface.compareTo(a.surface));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Barra de búsqueda y filtros ──────────────────────
        _buildSearchBar(),

        // ── Contador de resultados ───────────────────────────
        if (!_isLoading && _errorMessage == null)
          _buildResultsCounter(),

        // ── Lista de departamentos ───────────────────────────
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar departamento, capital o región...',
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF003087)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterDepartments();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF003087), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Chips de ordenamiento
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Ordenar: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                _buildSortChip('Nombre', 'name'),
                const SizedBox(width: 8),
                _buildSortChip('Población', 'population'),
                const SizedBox(width: 8),
                _buildSortChip('Superficie', 'surface'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _applySorting();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003087) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF003087) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCounter() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${_filteredDepartments.length} departamento${_filteredDepartments.length != 1 ? 's' : ''} encontrado${_filteredDepartments.length != 1 ? 's' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Estado de carga
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003087)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Cargando departamentos...',
              style: TextStyle(
                color: Color(0xFF003087),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consultando api-colombia.com',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Estado de error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Color(0xFFCE1126)),
              const SizedBox(height: 16),
              const Text(
                'Error de conexión',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDepartments,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003087),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Estado vacío tras búsqueda
    if (_filteredDepartments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No se encontraron resultados para\n"${_searchController.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Lista de departamentos
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredDepartments.length,
      itemBuilder: (context, index) {
        return _buildDepartmentCard(_filteredDepartments[index]);
      },
    );
  }

  // Tarjeta individual de departamento
  Widget _buildDepartmentCard(Department dept) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDepartmentDetails(dept),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar con inicial y color de región
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: dept.regionColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: dept.regionColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(dept.regionIcon, color: Colors.white, size: 20),
                    Text(
                      dept.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dept.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_city,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          dept.cityCapital,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.map, size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            dept.regionName,
                            style: TextStyle(
                              fontSize: 11,
                              color: dept.regionColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Barra de población relativa (visual)
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          _formatNumber(dept.population),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.aspect_ratio,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(
                          '${_formatNumber(dept.surface.toInt())} km²',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón "Ver más"
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF003087).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Ver más',
                  style: TextStyle(
                    color: Color(0xFF003087),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modal de detalles del departamento
  void _showDepartmentDetails(Department dept) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header del modal con color de región
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      dept.regionColor,
                      dept.regionColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(dept.regionIcon,
                              color: Colors.white, size: 24),
                          Text(
                            dept.name.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dept.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Región ${dept.regionName}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido scrollable
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Grid de datos clave
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      children: [
                        _buildDetailTile(
                            Icons.location_city, 'Capital', dept.cityCapital),
                        _buildDetailTile(
                            Icons.people, 'Población',
                            _formatNumber(dept.population)),
                        _buildDetailTile(
                            Icons.straighten, 'Superficie',
                            '${_formatNumber(dept.surface.toInt())} km²'),
                        _buildDetailTile(
                            Icons.home_work, 'Municipios',
                            dept.municipalities.toString()),
                        _buildDetailTile(
                            Icons.phone, 'Prefijo tel.',
                            '+57 (${dept.phonePrefix})'),
                        _buildDetailTile(
                            Icons.tag, 'ID región',
                            dept.regionId.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Descripción
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  color: dept.regionColor, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                'Descripción',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dept.description.isEmpty
                                ? 'Este departamento hace parte de la riqueza geográfica y cultural de Colombia. '
                                  'Su territorio alberga una gran biodiversidad y comunidades con tradiciones únicas.'
                                : dept.description,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF003087)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Formatear números grandes con separador de miles
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}

// ============================================================
// SECCIÓN 3: REGIONES DE COLOMBIA
// ============================================================
class RegionsSection extends StatelessWidget {
  const RegionsSection({super.key});

  // Datos curados de las 6 regiones naturales
  List<Map<String, dynamic>> get _regions => [
        {
          'id': 1,
          'name': 'Región Amazónica',
          'icon': Icons.forest,
          'emoji': '🌿',
          'color': const Color(0xFF2E7D32),
          'departments': ['Amazonas', 'Caquetá', 'Guainía', 'Putumayo', 'Vaupés'],
          'description':
              'La región más extensa de Colombia, cubierta por la selva tropical más biodiversa del planeta. '
              'Alberga cientos de especies únicas de flora y fauna. El río Amazonas es su arteria principal.',
          'area': '403.348 km²',
          'climate': 'Ecuatorial húmedo',
          'highlight': 'Mayor biodiversidad del planeta',
        },
        {
          'id': 2,
          'name': 'Región Andina',
          'icon': Icons.terrain,
          'emoji': '⛰️',
          'color': const Color(0xFF1565C0),
          'departments': [
            'Antioquia', 'Boyacá', 'Caldas', 'Cundinamarca', 'Huila',
            'Nariño', 'Norte de Santander', 'Quindío', 'Risaralda',
            'Santander', 'Tolima'
          ],
          'description':
              'El corazón económico y demográfico de Colombia. Atravesada por las tres cordilleras de los Andes. '
              'Aquí nació el café colombiano y se concentra la mayor parte de la población del país.',
          'area': '282.540 km²',
          'climate': 'Variado según altitud',
          'highlight': 'Eje cafetero y cultura paisa',
        },
        {
          'id': 3,
          'name': 'Región Caribe',
          'icon': Icons.beach_access,
          'emoji': '🏖️',
          'color': const Color(0xFF00838F),
          'departments': [
            'Atlántico', 'Bolívar', 'Cesar', 'Córdoba',
            'La Guajira', 'Magdalena', 'Sucre'
          ],
          'description':
              'Tierra de carnavales, vallenato y mar turquesa. La región Caribe es el alma festiva de Colombia. '
              'Cartagena de Indias es su joya colonial. La Sierra Nevada de Santa Marta es la montaña costera '
              'más alta del mundo.',
          'area': '132.218 km²',
          'climate': 'Tropical seco y húmedo',
          'highlight': 'Carnavales de Barranquilla',
        },
        {
          'id': 4,
          'name': 'Región Insular',
          'icon': Icons.waves,
          'emoji': '🏝️',
          'color': const Color(0xFF6A1B9A),
          'departments': ['Archipiélago de San Andrés y Providencia'],
          'description':
              'Las islas coralinas de Colombia en el Mar Caribe. San Andrés y Providencia son famosas '
              'por sus aguas cristalinas de siete colores. Declaradas Reserva de Biósfera por la UNESCO.',
          'area': '52,5 km²',
          'climate': 'Tropical oceánico',
          'highlight': 'Mar de los Siete Colores',
        },
        {
          'id': 5,
          'name': 'Región Orinoquía',
          'icon': Icons.grass,
          'emoji': '🌾',
          'color': const Color(0xFFE65100),
          'departments': [
            'Arauca', 'Casanare', 'Meta', 'Vichada'
          ],
          'description':
              'Los llanos orientales: una inmensa sabana surcada por ríos caudalosos. '
              'Es la tierra del llanero colombiano, del joropo, de la garza morena y los caballos criollos. '
              'Una frontera natural con Venezuela y Venezuela.',
          'area': '310.000 km²',
          'climate': 'Tropical de sabana',
          'highlight': 'Llanos y joropo llanero',
        },
        {
          'id': 6,
          'name': 'Región Pacífica',
          'icon': Icons.water,
          'emoji': '🌊',
          'color': const Color(0xFF00695C),
          'departments': ['Chocó', 'Cauca', 'Nariño', 'Valle del Cauca'],
          'description':
              'Una de las regiones con mayor pluviosidad del mundo. La costa pacífica colombiana alberga '
              'selvas húmedas, manglares y ballenas jorobadas que llegan cada año a reproducirse. '
              'Chocó es uno de los puntos más biodiversos de la Tierra.',
          'area': '83.170 km²',
          'climate': 'Superúmedo tropical',
          'highlight': 'Avistamiento de ballenas jorobadas',
        },
      ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _regions.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildRegionsHeader();
        return _buildRegionCard(context, _regions[index - 1]);
      },
    );
  }

  Widget _buildRegionsHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Text('🗺️', style: TextStyle(fontSize: 36)),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Las 6 Regiones Naturales',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Colombia, un territorio de contrastes y biodiversidad sin igual',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(
      BuildContext context, Map<String, dynamic> region) {
    final Color color = region['color'] as Color;
    final List<String> departments = region['departments'] as List<String>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
       color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showRegionDetail(context, region),
        child: Column(
          children: [
            // Header de la tarjeta con gradiente
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Text(
                    region['emoji'] as String,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          region['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${departments.length} dpts.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                region['area'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(region['icon'] as IconData,
                      color: Colors.white.withOpacity(0.5), size: 32),
                ],
              ),
            ),
            // Cuerpo de la tarjeta
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region['description'] as String,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Highlight
                  Row(
                    children: [
                      Icon(Icons.star, color: color, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        region['highlight'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Departamentos como chips
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: departments
                        .take(4)
                        .map((d) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color.withOpacity(0.9),
                                ),
                              ),
                            ))
                        .toList()
                      ..addAll(departments.length > 4
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${departments.length - 4} más',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              )
                            ]
                          : []),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegionDetail(
      BuildContext context, Map<String, dynamic> region) {
    final Color color = region['color'] as Color;
    final List<String> departments =
        region['departments'] as List<String>;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text(region['emoji'] as String,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        region['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region['description'] as String,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      const Text('Departamentos:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: departments
                            .map((d) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: color.withOpacity(0.3)),
                                  ),
                                  child: Text(d,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: color)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(Icons.thermostat, region['climate'] as String, color),
                          const SizedBox(width: 8),
                          _buildInfoChip(Icons.star, region['highlight'] as String, color),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 11, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECCIÓN 4: ATRACCIONES TURÍSTICAS
// ============================================================
class TouristSection extends StatefulWidget {
  const TouristSection({super.key});

  @override
  State<TouristSection> createState() => _TouristSectionState();
}

class _TouristSectionState extends State<TouristSection> {
  String _selectedCategory = 'Todos';

  // Lista curada de atracciones turísticas con categorías
  final List<TouristAttraction> _attractions = [
    TouristAttraction(
      name: 'Ciudad Amurallada de Cartagena',
      location: 'Cartagena, Bolívar',
      description:
          'Patrimonio de la Humanidad de la UNESCO. Sus murallas coloniales, '
          'calles adoquinadas y plazas coloridas la convierten en la joya del Caribe colombiano. '
          'Declarada Patrimonio en 1984.',
      icon: Icons.castle,
      color: const Color(0xFFE65100),
      category: 'Patrimonio',
    ),
    TouristAttraction(
      name: 'Parque Nacional Tayrona',
      location: 'Santa Marta, Magdalena',
      description:
          'Una de las reservas naturales más impresionantes del mundo. '
          'Playa Cristal y La Piscina son sus iconos: mar turquesa, selva densa y ruinas taironas.',
      icon: Icons.park,
      color: const Color(0xFF2E7D32),
      category: 'Naturaleza',
    ),
    TouristAttraction(
      name: 'Caño Cristales',
      location: 'La Macarena, Meta',
      description:
          'El "Río de los Cinco Colores". Entre julio y noviembre, una planta acuática tiñe '
          'sus aguas de amarillo, verde, azul, negro y rojo. Considerado el río más bonito del mundo.',
      icon: Icons.water,
      color: const Color(0xFFCE1126),
      category: 'Naturaleza',
    ),
    TouristAttraction(
      name: 'Eje Cafetero',
      location: 'Caldas, Quindío, Risaralda',
      description:
          'Patrimonio de la Humanidad. Coloridas haciendas cafeteras, el Parque Nacional del Café '
          'y pueblos pintorescos como Salento y Filandia. La mejor experiencia del café colombiano.',
      icon: Icons.coffee,
      color: const Color(0xFF795548),
      category: 'Cultura',
    ),
    TouristAttraction(
      name: 'Santuario Las Lajas',
      location: 'Ipiales, Nariño',
      description:
          'Una catedral neogótica construida sobre un cañón a 3.000 metros de altura. '
          'El puente que la conecta con el abismo y la basílica excavada en la roca son únicos en el mundo.',
      icon: Icons.church,
      color: const Color(0xFF1565C0),
      category: 'Religioso',
    ),
    TouristAttraction(
      name: 'Desierto de la Tatacoa',
      location: 'Villavieja, Huila',
      description:
          'El segundo desierto más grande de Colombia. Su cielo despejado lo convierte en uno de los '
          'mejores observatorios astronómicos de Sudamérica. Sus formaciones rojizas y grises son fascinantes.',
      icon: Icons.wb_sunny,
      color: const Color(0xFFF57F17),
      category: 'Naturaleza',
    ),
    TouristAttraction(
      name: 'Pueblito Paisa',
      location: 'Medellín, Antioquia',
      description:
          'Una réplica de pueblo antioqueño sobre el Cerro Nutibara. '
          'Desde sus miradores se aprecia el Valle de Aburrá. Símbolo de la identidad paisa.',
      icon: Icons.location_city,
      color: const Color(0xFF006064),
      category: 'Cultura',
    ),
    TouristAttraction(
      name: 'Isla de San Andrés',
      location: 'Archipiélago de San Andrés',
      description:
          'El Mar de los Siete Colores. Arrecifes de coral, aguas cristalinas y una mezcla única '
          'de cultura caribeña y raizal. Sede del famoso buceo de escala mundial.',
      icon: Icons.beach_access,
      color: const Color(0xFF00838F),
      category: 'Playa',
    ),
    TouristAttraction(
      name: 'Cocora Valley',
      location: 'Salento, Quindío',
      description:
          'Hogar de la palma de cera, el árbol nacional de Colombia. '
          'Las palmas de hasta 60 metros emergiendo entre la niebla forman uno de los paisajes '
          'más emblemáticos del país.',
      icon: Icons.nature,
      color: const Color(0xFF558B2F),
      category: 'Naturaleza',
    ),
    TouristAttraction(
      name: 'Museo del Oro',
      location: 'Bogotá D.C.',
      description:
          'El más importante del mundo en orfebrería precolombina. '
          'Más de 55.000 piezas de oro dan testimonio de la sofisticación de las culturas indígenas. '
          'La Balsa Muisca es su pieza estrella.',
      icon: Icons.museum,
      color: const Color(0xFFB8860B),
      category: 'Cultura',
    ),
    TouristAttraction(
      name: 'Ciudad Perdida (Teyuna)',
      location: 'Sierra Nevada, Magdalena',
      description:
          'Construida hace 1.400 años por la civilización tairona. '
          'Para llegar hay que caminar 4 días por la selva. Una de las ciudades '
          'arqueológicas más importantes de América.',
      icon: Icons.account_balance,
      color: const Color(0xFF4E342E),
      category: 'Patrimonio',
    ),
    TouristAttraction(
      name: 'Avistamiento de Ballenas',
      location: 'Bahía Málaga, Valle del Cauca',
      description:
          'Entre junio y noviembre, las ballenas jorobadas llegan al Pacífico colombiano '
          'para reproducirse. Una de las mejores experiencias de avistamiento del mundo.',
      icon: Icons.waves,
      color: const Color(0xFF01579B),
      category: 'Naturaleza',
    ),
  ];

  List<String> get _categories {
    final cats = _attractions.map((a) => a.category).toSet().toList();
    cats.sort();
    return ['Todos', ...cats];
  }

  List<TouristAttraction> get _filteredAttractions {
    if (_selectedCategory == 'Todos') return _attractions;
    return _attractions
        .where((a) => a.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner turístico
        _buildTouristBanner(),
        // Filtros por categoría
        _buildCategoryFilter(),
        // Lista de atracciones
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _filteredAttractions.length,
            itemBuilder: (context, index) =>
                _buildAttractionCard(context, _filteredAttractions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTouristBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFCE1126), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Text('✈️', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Colombia, realismo mágico hecho destino',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '12 atracciones imperdibles',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFCE1126) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFCE1126)
                        : const Color(0xFFE0E0E0),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFCE1126).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAttractionCard(
      BuildContext context, TouristAttraction attraction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showAttractionDetail(context, attraction),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen placeholder con gradiente
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    attraction.color,
                    attraction.color.withOpacity(0.6),
                    attraction.color.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  // Patrón decorativo
                  Positioned.fill(
                    child: CustomPaint(painter: _PatternPainter(attraction.color)),
                  ),
                  // Ícono grande
                  Center(
                    child: Icon(
                      attraction.icon,
                      size: 52,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  // Badge de categoría
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        attraction.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Información textual
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attraction.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place, size: 13, color: attraction.color),
                      const SizedBox(width: 3),
                      Text(
                        attraction.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: attraction.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    attraction.description,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _showAttractionDetail(context, attraction),
                        icon: const Icon(Icons.explore, size: 16),
                        label: const Text('Explorar'),
                        style: TextButton.styleFrom(
                          foregroundColor: attraction.color,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttractionDetail(
      BuildContext context, TouristAttraction attraction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      attraction.color,
                      attraction.color.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                          painter: _PatternPainter(attraction.color)),
                    ),
                    Center(
                      child: Icon(attraction.icon,
                          size: 60, color: Colors.white.withOpacity(0.9)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: attraction.color),
                        const SizedBox(width: 4),
                        Text(
                          attraction.location,
                          style: TextStyle(
                            color: attraction.color,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: attraction.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            attraction.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: attraction.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      attraction.description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '¡${attraction.name} agregada a tus favoritos! ❤️'),
                            backgroundColor: attraction.color,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Guardar en favoritos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: attraction.color,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CUSTOM PAINTER: Patrón decorativo para las tarjetas
// ============================================================
class _PatternPainter extends CustomPainter {
  final Color baseColor;
  _PatternPainter(this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    // Círculos decorativos
    final random = Random(baseColor.value);
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 30 + 10;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// FIN DEL ARCHIVO main.dart
// Colombia Explorer — Flutter App completa en un solo archivo
// ============================================================