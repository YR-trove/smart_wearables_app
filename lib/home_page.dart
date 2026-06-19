import 'package:flutter/material.dart';
import 'package:smart_wearables_app/data/sensor_buffer.dart';
import 'package:smart_wearables_app/connection/stream.dart';

class HomePage extends StatefulWidget {
  final String title;
  final SensorBuffer buffer;
  final MyStream? stream;

  const HomePage({super.key, required this.title, required this.buffer, this.stream});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isRawMode = false;

  void _toggleMode() {
    setState(() => _isRawMode = !_isRawMode);
    widget.stream?.setMcuMode(_isRawMode);
    widget.buffer.clear(); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text('Developer Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: widget.buffer, 
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: _isRawMode ? _buildRawCharts(isDark) : _buildMetricsCharts(isDark),
          );
        },
      ),
      // Replace your existing floatingActionButton with this:
      floatingActionButton: widget.stream != null
          ? FloatingActionButton.extended(
              onPressed: _toggleMode,
              icon: Icon(_isRawMode ? Icons.analytics : Icons.speed),
              label: Text(_isRawMode ? 'Switch to Metrics' : 'Switch to Raw Data'),
              backgroundColor: _isRawMode ? const Color(0xFFEF4444) : theme.colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null, floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat 
          // Hides the button entirely if disconnected!,
    );
  }

  // --- View 1: Unified Metrics ---
  List<Widget> _buildMetricsCharts(bool isDark) {
    return [
      _ChartCard(
        title: 'Step Count (Cumulative)', 
        multiData: [widget.buffer.stepCountHistory], 
        colors: [const Color(0xFFF472B6)], // Pink
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Activity State (0=Idle, 1=Walk, 2=Run)', 
        multiData: [widget.buffer.activityHistory], 
        colors: [const Color(0xFF8B5CF6)], // Purple
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Step Cadence (Steps/min)', 
        multiData: [widget.buffer.cadenceHistory], 
        colors: [const Color(0xFF10B981)], // Green
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Illuminance Proxy (Clear Channel)', 
        multiData: [widget.buffer.luxHistory], 
        colors: [const Color(0xFFFFCA28)], // Yellow
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'UV Risk Index', 
        multiData: [widget.buffer.uvRiskHistory], 
        colors: [const Color(0xFFEF4444)], // Red
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Blue Light Intensity', 
        multiData: [widget.buffer.blueIntensityHistory], 
        colors: [const Color(0xFF2563EB)], // Deep Blue
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Blue Light Ratio (Q15)', 
        multiData: [widget.buffer.blueRatioHistory], 
        colors: [const Color(0xFF06B6D4)], // Cyan
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'SunLike Index (Q15)', 
        multiData: [widget.buffer.sunLikeHistory], 
        colors: [const Color(0xFFF59E0B)], // Amber
        isDark: isDark,
      ),
      const SizedBox(height: 80), // Padding so the FAB doesn't cover the bottom chart
    ];
  }

  // --- View 2: Multi-Axis & Spectral Raw Data ---
  List<Widget> _buildRawCharts(bool isDark) {
    return [
      _ChartCard(
        title: 'Accelerometer (X=Red, Y=Green, Z=Blue)',
        multiData: [widget.buffer.accelX, widget.buffer.accelY, widget.buffer.accelZ],
        colors: [const Color(0xFFEF4444), const Color(0xFF10B981), const Color(0xFF3B82F6)],
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(
        title: 'Gyroscope (X=Red, Y=Green, Z=Blue)',
        multiData: [widget.buffer.gyroX, widget.buffer.gyroY, widget.buffer.gyroZ],
        colors: [const Color(0xFFEF4444), const Color(0xFF10B981), const Color(0xFF3B82F6)],
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      _ChartCard(title: 'F1 - Violet (415nm)', multiData: [widget.buffer.f1], colors: [const Color(0xFF8B5CF6)], isDark: isDark),
      const SizedBox(height: 12),
      _ChartCard(title: 'F2 - Deep Blue (445nm)', multiData: [widget.buffer.f2], colors: [const Color(0xFF2563EB)], isDark: isDark),
      const SizedBox(height: 12),
      _ChartCard(title: 'F3 - Cyan (480nm)', multiData: [widget.buffer.f3], colors: [const Color(0xFF06B6D4)], isDark: isDark),
      const SizedBox(height: 12),
      _ChartCard(title: 'F4 - Teal/Green (515nm)', multiData: [widget.buffer.f4], colors: [const Color(0xFF10B981)], isDark: isDark),
      const SizedBox(height: 12),
      _ChartCard(title: 'F5 - Lime (555nm)', multiData: [widget.buffer.f5], colors: [const Color(0xFF84CC16)], isDark: isDark),
      const SizedBox(height: 12),
      _ChartCard(title: 'F6 - Amber (590nm)', multiData: [widget.buffer.f6], colors: [const Color(0xFFF59E0B)], isDark: isDark),
      const SizedBox(height: 12),
      _ChartCard(title: 'F7 - Red (630nm)', multiData: [widget.buffer.f7], colors: [const Color(0xFFEF4444)], isDark: isDark),
      const SizedBox(height: 12),
      _ChartCard(title: 'F8 - Deep Red (680nm)', multiData: [widget.buffer.f8], colors: [const Color(0xFF991B1B)], isDark: isDark),
      const SizedBox(height: 80), // Padding for the floating button
    ];
  }
}

// ============================================================================
// High-Performance Multi-Line Custom Painter
// ============================================================================

class _ChartCard extends StatelessWidget {
  final String title;
  final List<List<double>> multiData;
  final List<Color> colors;
  final bool isDark;

  const _ChartCard({required this.title, required this.multiData, required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRect(
              child: CustomPaint(
                size: Size.infinite,
                painter: _MultiOscilloscopePainter(
                  multiData: multiData,
                  colors: colors,
                  gridColor: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiOscilloscopePainter extends CustomPainter {
  final List<List<double>> multiData;
  final List<Color> colors;
  final Color gridColor;

  _MultiOscilloscopePainter({required this.multiData, required this.colors, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Grid
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (multiData.isEmpty || multiData[0].isEmpty) return;

    // 2. Find global min and max across all lines for unified scaling
    double maxVal = -double.infinity;
    double minVal = double.infinity;
    
    for (var series in multiData) {
      if (series.isEmpty) continue;
      final sMax = series.reduce((a, b) => a > b ? a : b);
      final sMin = series.reduce((a, b) => a < b ? a : b);
      if (sMax > maxVal) maxVal = sMax;
      if (sMin < minVal) minVal = sMin;
    }

    // Add 10% padding so peaks don't hit the ceiling/floor of the box
    if (maxVal == minVal) {
      maxVal += 1; minVal -= 1;
    } else {
      final padding = (maxVal - minVal) * 0.1;
      maxVal += padding;
      minVal -= padding;
    }
    
    final range = maxVal - minVal;
    final stepX = size.width / (multiData[0].length > 1 ? multiData[0].length - 1 : 1);

    // 3. Draw each line
    for (int lineIdx = 0; lineIdx < multiData.length; lineIdx++) {
      final data = multiData[lineIdx];
      if (data.isEmpty) continue;

      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = i * stepX;
        final normalizedY = (data[i] - minVal) / range;
        final y = size.height - (normalizedY * size.height);
        
        if (i == 0) 
        {
          path.moveTo(x, y);
        }
        else 
        {
          path.lineTo(x, y);
        }
      }

      final linePaint = Paint()
        ..color = colors[lineIdx % colors.length]
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MultiOscilloscopePainter oldDelegate) => true;
}