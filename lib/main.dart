import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'weather/weather_screen.dart';
import 'colombia/colombia_screen.dart';
import 'iss/iss_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const WeatherProApp());
}

class WeatherProApp extends StatelessWidget {
  const WeatherProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Pro Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6B9A),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeMenuScreen(),
    );
  }
}

// ─── Menú principal ──────────────────────────────────────────────────────────
class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));

    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _cardFades = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _cardsCtrl,
        curve: Interval(i * 0.18, 0.55 + i * 0.15, curve: Curves.easeOut),
      ));
    });
    _cardSlides = List.generate(3, (i) {
      return Tween<Offset>(
        begin: const Offset(0.12, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardsCtrl,
        curve: Interval(i * 0.18, 0.55 + i * 0.15, curve: Curves.easeOutCubic),
      ));
    });

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 250), () => _cardsCtrl.forward());
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  void _navigateTo(int index) {
    // Navega a cada app real sin modificar sus widgets originales
    final pages = <Widget>[
      const WeatherScreen(),   // Tu app del clima original
      const MainScaffold(),    // Tu app Colombia original
      const ISSLocationApp(),  // Tu app ISS original
    ];
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => pages[index],
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Glow decorativo azul marino (consistente con WeatherScreen)
          Positioned(
            right: -60,
            top: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF1A6B9A).withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(opacity: _headerFade, child: _buildHeader()),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      _animCard(0, _buildAppCard(
                        index: 0,
                        icon: Icons.wb_sunny_rounded,
                        bgIcon: Icons.cloud_rounded,
                        title: 'App del Clima',
                        description:
                            'Temperatura, humedad, viento y presión\nen tiempo real con gauges animados.',
                        gradColors: const [Color(0xFF0D2137), Color(0xFF1A4B6E)],
                        accent: const Color(0xFF5BC8F5),
                        tag: 'OpenWeatherMap',
                      )),
                      _animCard(1, _buildAppCard(
                        index: 1,
                        icon: Icons.map_rounded,
                        bgIcon: Icons.location_city_rounded,
                        title: 'Explora Colombia',
                        description:
                            'Departamentos, regiones y atracciones\nturísticas con datos reales de la API.',
                        gradColors: const [Color(0xFF1A1A2E), Color(0xFF2A200E)],
                        accent: const Color(0xFFFCD116),
                        tag: 'API Colombia',
                      )),
                      _animCard(2, _buildAppCard(
                        index: 2,
                        icon: Icons.satellite_alt_rounded,
                        bgIcon: Icons.public_rounded,
                        title: 'Rastreador ISS',
                        description:
                            'Posición de la Estación Espacial\nInternacional actualizada cada 5 s.',
                        gradColors: const [Color(0xFF0D1B2A), Color(0xFF1B3A5C)],
                        accent: Colors.cyanAccent,
                        tag: 'Open Notify',
                      )),
                    ],
                  ),
                ),
                FadeTransition(opacity: _headerFade, child: _buildFooter()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animCard(int i, Widget child) => SlideTransition(
        position: _cardSlides[i],
        child: FadeTransition(opacity: _cardFades[i], child: child),
      );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A6B9A), Color(0xFF5BC8F5)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5BC8F5).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(Icons.dashboard_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('WEATHER PRO',
                  style: TextStyle(
                      color: Color(0xFF5BC8F5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3)),
              Text('Suite de aplicaciones',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 22),
          const Text('Panel de\nControl',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Selecciona una aplicación para comenzar',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAppCard({
    required int index,
    required IconData icon,
    required IconData bgIcon,
    required String title,
    required String description,
    required List<Color> gradColors,
    required Color accent,
    required String tag,
  }) {
    return GestureDetector(
      onTap: () => _navigateTo(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            Container(
              height: 132,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradColors),
              ),
            ),
            Container(
              height: 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: accent.withOpacity(0.18), width: 0.8),
              ),
            ),
            Positioned(
              right: -8,
              top: -8,
              child: Icon(bgIcon, size: 100, color: accent.withOpacity(0.055)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withOpacity(0.28),
                        accent.withOpacity(0.08)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: accent.withOpacity(0.3), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: accent.withOpacity(0.25), width: 0.5),
                        ),
                        child: Text(tag,
                            style: TextStyle(
                                color: accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 7),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text(description,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.48),
                              fontSize: 11,
                              height: 1.45)),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border:
                        Border.all(color: accent.withOpacity(0.2), width: 0.5),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      color: accent, size: 13),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: Center(
        child: Text(
          'Weather Pro Suite · Flutter',
          style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 11,
              letterSpacing: 0.3),
        ),
      ),
    );
  }
}
