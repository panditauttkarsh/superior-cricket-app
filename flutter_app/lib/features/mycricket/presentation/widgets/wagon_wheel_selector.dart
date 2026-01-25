import 'dart:math' as math;
import 'package:flutter/material.dart';

class WagonWheelSelector extends StatefulWidget {
  final double size;
  final Function(String region) onRegionSelected;
  final String? initialRegion;

  const WagonWheelSelector({
    super.key,
    required this.size,
    required this.onRegionSelected,
    this.initialRegion,
  });

  @override
  State<WagonWheelSelector> createState() => _WagonWheelSelectorState();
}

class _WagonWheelSelectorState extends State<WagonWheelSelector> {
  String? _selectedRegion;

  // Regions configuration
  // Maps angle ranges (in degrees) to region names
  // 0 degrees is 3 o'clock (East), going clockwise
  // Standard Flutter Canvas coordinates: 0 is Right, 90 is Down, 180 is Left, 270 is Up.
  final List<WagonWheelRegion> _regions = [
    WagonWheelRegion('Third Man', 247.5, 292.5),    // Top-Leftish (Up-Left)
    WagonWheelRegion('Deep Point', 202.5, 247.5),   // Left
    WagonWheelRegion('Deep Cover', 157.5, 202.5),   // Down-Left
    WagonWheelRegion('Long Off', 112.5, 157.5),     // Down-Right (Straightish)
    WagonWheelRegion('Long On', 67.5, 112.5),       // Down-Right
    WagonWheelRegion('Deep Mid-Wicket', 22.5, 67.5), // Right (Leg side)
    WagonWheelRegion('Deep Square Leg', 337.5, 360.0), // Up-Right -> handled by split check or special case
    WagonWheelRegion('Deep Fine Leg', 292.5, 337.5),   // Top-Right
  ];

  // Special handling for region crossing 0/360
  // Deep Square Leg: 337.5 to 22.5 (~360/0)

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
  }

  void _handleTap(TapUpDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final center = Offset(widget.size / 2, widget.size / 2);
    
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    
    final distance = math.sqrt(dx * dx + dy * dy);
    final radius = widget.size / 2;
    
    // Check for "Straight" (center circle)
    if (distance < radius * 0.3) {
      _selectRegion('Straight');
      return;
    }
    
    // Calculate angle in degrees (0-360)
    // atan2 returns -pi to +pi. 0 is Right. Positive is clockwise (screen coords).
    double angle = (math.atan2(dy, dx) * 180 / math.pi);
    if (angle < 0) angle += 360;

    String? regionName;
    
    // Special check for Deep Square Leg (wrapping around 0)
    if (angle >= 337.5 || angle < 22.5) {
      regionName = 'Deep Square Leg';
    } else {
      for (final region in _regions) {
        if (angle >= region.startAngle && angle < region.endAngle) {
          regionName = region.name;
          break;
        }
      }
    }

    if (regionName != null) {
      _selectRegion(regionName);
    }
  }

  void _selectRegion(String region) {
    setState(() {
      _selectedRegion = region;
    });
    widget.onRegionSelected(region);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: WagonWheelPainter(
          selectedRegion: _selectedRegion,
        ),
      ),
    );
  }
}

class WagonWheelRegion {
  final String name;
  final double startAngle;
  final double endAngle;

  WagonWheelRegion(this.name, this.startAngle, this.endAngle);
}

class WagonWheelPainter extends CustomPainter {
  final String? selectedRegion;

  WagonWheelPainter({this.selectedRegion});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw Field (Grass)
    final fieldPaint = Paint()
      ..color = const Color(0xFF4CAF50) // Cricket Green
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, fieldPaint);
    
    // 1.5 Draw Boundary Ring
    final boundaryPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 2, boundaryPaint);

    // 2. Draw Sectors
    final linePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Define sectors matching the logic
    // 0 is Right (Deep Mid Wicket / Square Leg boundary approx)
    final angles = [
      22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5
    ];

    for (var angle in angles) {
      final rad = angle * math.pi / 180;
      final endPoint = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );
      // Start from inner circle outline (radius * 0.3)
      final startPoint = Offset(
        center.dx + (radius * 0.3) * math.cos(rad),
        center.dy + (radius * 0.3) * math.sin(rad),
      );
      canvas.drawLine(startPoint, endPoint, linePaint);
    }

    // 3. Highlight Selected Region
    if (selectedRegion != null) {
      final highlightPaint = Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      
      if (selectedRegion == 'Straight') {
        canvas.drawCircle(center, radius * 0.3, highlightPaint);
      } else {
        double? start, end;
        
        switch (selectedRegion) {
          case 'Deep Square Leg':
            start = 337.5; end = 22.5 + 360; // Use >360 for sweep logic
            break;
          case 'Deep Mid-Wicket':
            start = 22.5; end = 67.5;
            break;
          case 'Long On':
            start = 67.5; end = 112.5;
            break;
          case 'Long Off':
            start = 112.5; end = 157.5;
            break;
          case 'Deep Cover':
            start = 157.5; end = 202.5;
            break;
          case 'Deep Point':
            start = 202.5; end = 247.5;
            break;
          case 'Third Man':
            start = 247.5; end = 292.5;
            break;
           case 'Deep Fine Leg':
            start = 292.5; end = 337.5;
            break;
        }

        if (start != null && end != null) {
          final startRad = start * math.pi / 180;
          final sweepRad = (end - start) * math.pi / 180;
          
          final path = Path();
          path.arcTo(
             Rect.fromCircle(center: center, radius: radius),
             startRad,
             sweepRad,
             false
          );
          path.arcTo(
             Rect.fromCircle(center: center, radius: radius * 0.3),
             startRad + sweepRad,
             -sweepRad,
             false
          );
          path.close();
          canvas.drawPath(path, highlightPaint);
        }
      }
    }

    // 4. Draw Inner Circle (Box/Straight area)
    final innerCirclePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.3, innerCirclePaint);
    
    // Border for inner circle
    canvas.drawCircle(center, radius * 0.3, linePaint);

    // 5. Draw Pitch
    final pitchWidth = radius * 0.12;
    final pitchHeight = radius * 0.4; // 22 yards scale relative to field
    final pitchRect = Rect.fromCenter(
      center: center,
      width: pitchWidth,
      height: pitchHeight,
    );
    final pitchPaint = Paint()
      ..color = const Color(0xFFE4C49F) // Pitch color
      ..style = PaintingStyle.fill;
    canvas.drawRect(pitchRect, pitchPaint);
    
    // Draw stumps markers
    final stumpPaint = Paint()
      ..color = Colors.black45
      ..strokeWidth = 2;
      
    // Top stumps
    canvas.drawLine(
      Offset(center.dx - pitchWidth/3, center.dy - pitchHeight/2 + 2),
      Offset(center.dx + pitchWidth/3, center.dy - pitchHeight/2 + 2),
      stumpPaint
    );
     // Bottom stumps
    canvas.drawLine(
      Offset(center.dx - pitchWidth/3, center.dy + pitchHeight/2 - 2),
      Offset(center.dx + pitchWidth/3, center.dy + pitchHeight/2 - 2),
      stumpPaint
    );

    // 6. Draw Region Labels
    _drawText(canvas, size, 'Straight', center, isCenter: true);
    
    // Labels map
    final labels = {
      0.0: 'Sq Leg', // 0 degrees
      45.0: 'Mid Wkt',
      90.0: 'Long On',
      135.0: 'Long Off',
      180.0: 'Cover',
      225.0: 'Point',
      270.0: '3rd Man',
      315.0: 'Fine Leg',
    };

    final textRadius = radius * 0.65;
    labels.forEach((angle, text) {
      final rad = angle * math.pi / 180;
      final offset = Offset(
        center.dx + textRadius * math.cos(rad),
        center.dy + textRadius * math.sin(rad),
      );
      _drawText(canvas, size, text, offset);
    });
  }

  void _drawText(Canvas canvas, Size size, String text, Offset position, {bool isCenter = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: isCenter ? 12 : 10,
        fontWeight: FontWeight.bold,
        shadows: const [
           Shadow(blurRadius: 2.0, color: Colors.black, offset: Offset(1,1)),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    
    textPainter.paint(
      canvas, 
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant WagonWheelPainter oldDelegate) {
    return oldDelegate.selectedRegion != selectedRegion;
  }
}
