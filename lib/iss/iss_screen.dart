// ============================================================
// RASTREADOR ISS EN TIEMPO REAL - Flutter App
// Curso RogerCorp | Desarrollado con buenas prácticas Dart/Flutter
// ============================================================

import 'dart:async';           // Para usar Timer en tiempo real
import 'dart:convert';         // Para jsonDecode de la respuesta HTTP
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Peticiones asíncronas HTTP


// ────────────────────────────────────────────────────────────
// WIDGET PRINCIPAL (StatefulWidget) — maneja cambios de coordenadas
// ────────────────────────────────────────────────────────────
class ISSLocationApp extends StatefulWidget {
  const ISSLocationApp({super.key});

  @override
  State<ISSLocationApp> createState() => _ISSLocationAppState();
}

class _ISSLocationAppState extends State<ISSLocationApp> {

  // ── Variables de estado ──────────────────────────────────
  String latitude  = 'Cargando...'; // Latitud actual de la ISS
  String longitude = 'Cargando...'; // Longitud actual de la ISS
  String timestamp = '';            // Marca de tiempo del último refresco
  bool   isLoading = true;          // Indicador de carga inicial
  bool   hasError  = false;         // Bandera de error HTTP
  Timer? _timer;                    // Referencia al Timer periódico

  // URL base de la API Open Notify (ISS position)
  static const String _apiUrl = 'https://api.wheretheiss.at/v1/satellites/25544';

  // ────────────────────────────────────────────────────────
  // initState — Se ejecuta al montar el widget
  // ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // 1. Primera llamada inmediata al montar el widget
    fetchISSLocation();

    // 2. Timer periódico: refresca la posición cada 5 segundos
    //    usando dart:async — sin bloquear el hilo principal.
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (Timer t) => fetchISSLocation(),
    );
  }

  // ────────────────────────────────────────────────────────
  // dispose — Cancela el Timer al destruir el widget
  //           para evitar memory leaks
  // ────────────────────────────────────────────────────────
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────
  // fetchISSLocation — Función asíncrona principal
  //   • Realiza http.get con await
  //   • Verifica statusCode == 200
  //   • Extrae latitude/longitude con jsonDecode
  //   • Actualiza el estado con setState
  // ────────────────────────────────────────────────────────
  Future<void> fetchISSLocation() async {
    try {
      // Petición GET asíncrona — await suspende sin bloquear la UI
      final http.Response response = await http.get(Uri.parse(_apiUrl));

      // Manejo de errores: verificar que la respuesta sea exitosa
      if (response.statusCode == 200) {

        // jsonDecode convierte el JSON en un Map<String, dynamic>
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Extraer las coordenadas del objeto anidado 'iss_position'
        final String latValue = data['latitude'].toString();
final String lonValue = data['longitude'].toString();

        // Marca de tiempo legible del último refresco
        final String now = DateTime.now().toLocal().toString().substring(0, 19);

        // setState notifica al framework que el estado cambió → rebuild
        setState(() {
          latitude  = latValue;
          longitude = lonValue;
          timestamp = now;
          isLoading = false;
          hasError  = false;
        });

      } else {
        // El servidor respondió con un código de error HTTP
        setState(() {
          hasError  = true;
          isLoading = false;
        });
      }

    } catch (e) {
      // Error de red o parsing (sin conexión, timeout, JSON malformado, etc.)
      setState(() {
        hasError  = true;
        isLoading = false;
      });
    }
  }

  // ────────────────────────────────────────────────────────
  // build — Construye la interfaz de usuario
  // ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── AppBar ──────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          tooltip: 'Volver al menú',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.satellite_alt, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Rastreador ISS Real-Time',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Botón de refresco manual
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refrescar ahora',
            onPressed: fetchISSLocation,
          ),
        ],
      ),

      // ── Fondo degradado espacial ─────────────────────────
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B3A5C), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : hasError
                ? _buildErrorView()
                : _buildContentView(),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // _buildContentView — Vista principal con coordenadas
  // ────────────────────────────────────────────────────────
  Widget _buildContentView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        const SizedBox(height: 16),

        // ── Encabezado ilustrativo ───────────────────────
        Center(
          child: Column(
            children: [
              const Icon(Icons.public, size: 80, color: Colors.cyanAccent),
              const SizedBox(height: 8),
              const Text(
                '🛸 Posición Actual de la ISS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Actualizado: $timestamp',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Card: Latitud ────────────────────────────────
        _buildCoordCard(
          icon: Icons.location_on,
          iconColor: Colors.redAccent,
          label: 'Latitud',
          value: latitude,
          description: 'Posición Norte/Sur respecto al Ecuador',
        ),

        const SizedBox(height: 16),

        // ── Card: Longitud ───────────────────────────────
        _buildCoordCard(
          icon: Icons.explore,
          iconColor: Colors.cyanAccent,
          label: 'Longitud',
          value: longitude,
          description: 'Posición Este/Oeste respecto al Meridiano',
        ),

        const SizedBox(height: 24),

        // ── Card: Información extra ──────────────────────
        Card(
          elevation: 10,
          color: const Color(0xFF1A2F45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.blueAccent, size: 30),
                const SizedBox(height: 8),
                const Text(
                  'Datos de la Estación',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white24),
                _infoRow('Altitud promedio', '~408 km'),
                _infoRow('Velocidad orbital', '~27,600 km/h'),
                _infoRow('Órbitas por día', '~15.5'),
                _infoRow('Fuente de datos', 'open-notify.org'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Indicador de actualización automática ─────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 10),
                SizedBox(width: 6),
                Text(
                  'Actualizando cada 5 segundos',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // _buildCoordCard — Card reutilizable para coordenadas
  // ────────────────────────────────────────────────────────
  Widget _buildCoordCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String description,
  }) {
    return Card(
      elevation: 10,
      color: const Color(0xFF1A2F45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          radius: 28,
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            letterSpacing: 1.1,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              description,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // _infoRow — Fila de información clave/valor
  // ────────────────────────────────────────────────────────
  Widget _infoRow(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(val,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // _buildErrorView — Vista de error HTTP / conexión
  // ────────────────────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Error de conexión',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se pudo obtener la posición de la ISS.\nVerifica tu conexión a internet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchISSLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}