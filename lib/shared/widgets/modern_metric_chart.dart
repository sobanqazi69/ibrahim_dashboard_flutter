import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../features/dashboard/domain/models/metric_data.dart';
import 'dart:math' as math;

class ModernMetricChart extends StatefulWidget {
  final List<MetricData> data;
  final String title;
  final String? unit;
  final double minValue;
  final double maxValue;
  final Color? primaryColor;

  const ModernMetricChart({
    Key? key,
    required this.data,
    required this.title,
    this.unit,
    required this.minValue,
    required this.maxValue,
    this.primaryColor,
  }) : super(key: key);

  @override
  State<ModernMetricChart> createState() => _ModernMetricChartState();
}

class _ModernMetricChartState extends State<ModernMetricChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  int? _touchedIndex;
  double _zoomLevel = 24.0; // Hours to show (1-24)
  int _dataStartIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuart,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.primaryColor ?? const Color(0xFF00D2FF);

  List<MetricData> get _visibleData {
    if (widget.data.isEmpty) return [];
    
    final filteredData = widget.data;
    
    // Calculate how many data points to show based on zoom level
    final pointsPerHour = filteredData.length / 24; // Assuming 24 hours of data
    final visiblePointCount = (pointsPerHour * _zoomLevel).round();
    
    // Ensure we don't exceed available data
    final actualCount = math.min(visiblePointCount, filteredData.length);
    final endIndex = math.min(_dataStartIndex + actualCount, filteredData.length);
    final startIndex = math.max(0, endIndex - actualCount);
    
    return filteredData.sublist(startIndex, endIndex);
  }

  double _calculateActualMaxValue() {
    final visibleData = _visibleData;
    if (visibleData.isEmpty) return 100;
    
    if (widget.maxValue == double.infinity) {
      double maxInData = visibleData.fold(0.0, (max, item) => math.max(max, item.value));
      if (maxInData == 0) return 1.0; // Avoid zero range
      return maxInData * 1.02; // 2% padding for minimal look
    }
    return widget.maxValue;
  }

  double _calculateActualMinValue() {
    final visibleData = _visibleData;
    if (visibleData.isEmpty) return 0;
    
    double minInData = visibleData.fold(double.infinity, (min, item) => math.min(min, item.value));
    return math.max(0, minInData * 0.98); // 2% padding below, but not below 0
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyChart();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildMinimalHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: _buildChart(),
            ),
          ),
          _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildMinimalHeader() {
    final stats = _calculateStats();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              _buildCompactStat('Current', stats['current']!, _primaryColor),
              const SizedBox(width: 16),
              _buildCompactStat('Peak', stats['peak']!, Colors.green.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, double value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.unit != null) ...[
          const SizedBox(width: 2),
          Text(
            widget.unit!,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChart() {
    final visibleData = _visibleData;
    if (visibleData.isEmpty) return _buildEmptyChart();
    
    final double effectiveMinValue = _calculateActualMinValue();
    final double effectiveMaxValue = _calculateActualMaxValue();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              _handleMouseScroll(pointerSignal.scrollDelta.dy);
            }
          },
          child: LineChart(
            LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: math.max(1, (effectiveMaxValue - effectiveMinValue) / 3),
              verticalInterval: math.max(1, visibleData.length / 8),
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.08),
                strokeWidth: 0.5,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.05),
                strokeWidth: 0.5,
              ),
            ),
            titlesData: _buildTitlesData(effectiveMinValue, effectiveMaxValue),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (visibleData.length - 1).toDouble(),
            minY: effectiveMinValue,
            maxY: effectiveMaxValue,
            lineBarsData: [
              LineChartBarData(
                spots: _buildAnimatedSpots(effectiveMinValue),
                isCurved: false, // Straight lines for better minute detail
                color: _primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false), // Remove dots as requested
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _primaryColor.withOpacity(0.15),
                      _primaryColor.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                setState(() {
                  if (touchResponse != null && touchResponse.lineBarSpots != null) {
                    _touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
                  } else {
                    _touchedIndex = null;
                  }
                });
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => _primaryColor.withOpacity(0.95),
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 12,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    if (spot.x >= 0 && spot.x < visibleData.length) {
                      final item = visibleData[spot.x.toInt()];
                      return LineTooltipItem(
                        '${item.value.toStringAsFixed(2)} ${widget.unit ?? ''}\n${_formatDateTime(item.timestamp)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        ));
      },
    );
  }

  void _handleMouseScroll(double scrollDelta) {
    setState(() {
      // Scroll up (negative delta) = zoom in (decrease zoom level)
      // Scroll down (positive delta) = zoom out (increase zoom level)
      const double zoomSensitivity = 0.5;
      double newZoomLevel = _zoomLevel + (scrollDelta > 0 ? zoomSensitivity : -zoomSensitivity);
      
      // Clamp between min and max values
      _zoomLevel = newZoomLevel.clamp(1.0, 24.0);
      
      // Auto-scroll to latest data when zooming
      if (widget.data.isNotEmpty) {
        _dataStartIndex = math.max(0, widget.data.length - (widget.data.length * _zoomLevel / 24).round());
      }
    });
  }

  List<FlSpot> _buildAnimatedSpots(double minValue) {
    final visibleData = _visibleData;
    return List.generate(visibleData.length, (index) {
      final actualValue = visibleData[index].value;
      final animatedValue = minValue + (actualValue - minValue) * _animation.value;
      return FlSpot(index.toDouble(), animatedValue);
    });
  }

  FlTitlesData _buildTitlesData(double minValue, double maxValue) {
    final visibleData = _visibleData;
    
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: _calculateTimeInterval(),
          getTitlesWidget: (value, meta) {
            if (value < 0 || value >= visibleData.length) return const SizedBox();
            final date = visibleData[value.toInt()].timestamp;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: math.max(1, (maxValue - minValue) / 3),
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              color: _primaryColor.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(
                color: _primaryColor.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateStats() {
    final visibleData = _visibleData;
    if (visibleData.isEmpty) {
      return {
        'current': 0.0,
        'average': 0.0,
        'peak': 0.0,
        'low': 0.0,
      };
    }

    final values = visibleData.map((e) => e.value).toList();
    return {
      'current': values.last,
      'average': values.reduce((a, b) => a + b) / values.length,
      'peak': values.reduce(math.max),
      'low': values.reduce(math.min),
    };
  }

  double _calculateTimeInterval() {
    final visibleData = _visibleData;
    if (visibleData.length <= 8) return 1;
    return (visibleData.length / 8).ceil().toDouble();
  }

  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.zoom_in,
            color: _primaryColor.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _primaryColor,
                inactiveTrackColor: _primaryColor.withOpacity(0.2),
                thumbColor: _primaryColor,
                overlayColor: _primaryColor.withOpacity(0.1),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: _zoomLevel,
                min: 1.0,
                max: 24.0,
                divisions: 23,
                onChanged: (value) {
                  setState(() {
                    _zoomLevel = value;
                    // Auto-scroll to latest data when zooming
                    if (widget.data.isNotEmpty) {
                      _dataStartIndex = math.max(0, widget.data.length - (widget.data.length * _zoomLevel / 24).round());
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_zoomLevel.toInt()}h',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.zoom_out,
            color: _primaryColor.withOpacity(0.7),
            size: 16,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}';
  }
}
