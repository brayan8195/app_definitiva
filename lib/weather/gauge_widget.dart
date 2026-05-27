import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget de medidor tipo arco (gauge) implementado con CustomPainter.
/// Muestra un indicador semicircular con zonas de color codificadas:
/// - Verde (óptimo), Amarillo (precaución), Rojo (extremo/crítico).
class GaugeWidget extends StatefulWidget {
  final String label;
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;
  final List<GaugeZone> zones;
  final IconData icon;

  const GaugeWidget({
    super.key,
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.zones,
    required this.icon,
  });

  @override
  State<GaugeWidget> createState() => _GaugeWidgetState();
}

class _GaugeWidgetState extends State<GaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Animación de entrada del puntero del gauge
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(GaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-animar si el valor cambia (por ejemplo, al refrescar)
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Obtiene el color actual basado en el valor y las zonas configuradas
  Color _getValueColor() {
    for (final zone in widget.zones) {
      if (widget.value >= zone.min && widget.value <= zone.max) {
        return zone.color;
      }
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E2A3A),
            const Color(0xFF0F1923),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado con ícono y etiqueta
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                widget.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // El medidor animado con CustomPainter
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                height: 90,
                width: double.infinity,
                child: CustomPaint(
                  painter: _GaugePainter(
                    value: widget.value,
                    minValue: widget.minValue,
                    maxValue: widget.maxValue,
                    zones: widget.zones,
                    animationProgress: _animation.value,
                    valueColor: _getValueColor(),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 44),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatValue(widget.value),
                            style: TextStyle(
                              color: _getValueColor(),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          Text(
                            widget.unit,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // Leyenda de zonas de color
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.zones.map((zone) {
              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: zone.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    zone.label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatValue(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

/// Painter personalizado para el arco del medidor
class _GaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final List<GaugeZone> zones;
  final double animationProgress;
  final Color valueColor;

  const _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.zones,
    required this.animationProgress,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.78);
    final radius = (size.width * 0.36).clamp(0.0, size.height * 0.72);
    final strokeWidth = 8.0;

    // El arco va de 210° a 330° (semicírculo inferior abierto)
    const startAngle = math.pi * 0.75;     // 135° en radianes
    const sweepAngle = math.pi * 1.5;      // 270° en radianes

    // --- Fondo del arco (track) ---
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // --- Zonas de color del arco ---
    for (final zone in zones) {
      final zoneStart = _valueToAngle(zone.min);
      final zoneEnd = _valueToAngle(zone.max);
      final zoneSweep = zoneEnd - zoneStart;

      if (zoneSweep <= 0) continue;

      final zonePaint = Paint()
        ..color = zone.color.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        zoneStart,
        zoneSweep,
        false,
        zonePaint,
      );
    }

    // --- Arco de progreso animado ---
    final clampedValue = value.clamp(minValue, maxValue);
    final targetAngle = _valueToAngle(clampedValue);
    final animatedSweep = (targetAngle - startAngle) * animationProgress;

    if (animatedSweep > 0) {
      final progressPaint = Paint()
        ..color = valueColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        animatedSweep,
        false,
        progressPaint,
      );
    }

    // --- Puntero (aguja) animado ---
    final needleAngle = startAngle + (targetAngle - startAngle) * animationProgress;
    final needleLength = radius - 4;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    // Sombra de la aguja
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + const Offset(1, 1),
      needleEnd + const Offset(1, 1),
      shadowPaint,
    );

    // Aguja principal
    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Punto central de la aguja
    canvas.drawCircle(
      center,
      6,
      Paint()..color = valueColor,
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.white,
    );

    // --- Marcas de los valores mínimo y máximo ---
    _drawLabel(canvas, center, radius + 14, startAngle, minValue.toStringAsFixed(0));
    _drawLabel(canvas, center, radius + 14, startAngle + sweepAngle, maxValue.toStringAsFixed(0));
  }

  /// Convierte un valor numérico a su ángulo correspondiente en el arco
  double _valueToAngle(double v) {
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;
    final ratio = (v - minValue) / (maxValue - minValue);
    return startAngle + ratio.clamp(0.0, 1.0) * sweepAngle;
  }

  void _drawLabel(Canvas canvas, Offset center, double r, double angle, String text) {
    final pos = Offset(
      center.dx + r * math.cos(angle),
      center.dy + r * math.sin(angle),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.animationProgress != animationProgress;
}

/// Define una zona de color en el medidor con su rango y etiqueta
class GaugeZone {
  final double min;
  final double max;
  final Color color;
  final String label;

  const GaugeZone({
    required this.min,
    required this.max,
    required this.color,
    required this.label,
  });
}
