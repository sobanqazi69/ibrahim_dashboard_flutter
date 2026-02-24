import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/modern_metric_chart.dart';
import '../../../../shared/widgets/paginated_data_list.dart';
import '../../../../services/sensor_api_service.dart';
import '../../../../models/sensor_data.dart';
import '../../domain/models/metric_data.dart';
import 'dart:developer' as developer;

class MetricDetailPage extends StatefulWidget {
  final SensorMetric metric;
  final double currentValue;
  final String systemType; // 'RIC' or 'SCC'

  const MetricDetailPage({
    super.key,
    required this.metric,
    required this.currentValue,
    this.systemType = 'RIC',
  });

  @override
  State<MetricDetailPage> createState() => _MetricDetailPageState();
}

class _MetricDetailPageState extends State<MetricDetailPage> {
  final SensorApiService _apiService = SensorApiService();
  int _selectedHours = 24;
  late Stream<List<SensorData>> _historicalDataStream;

  @override
  void initState() {
    super.initState();
    developer.log('MetricDetailPage initialized for ${widget.metric.displayName} (${widget.systemType})');
    _historicalDataStream = widget.systemType == 'SCC' 
        ? _apiService.getHistoricalSCCDataStream(hours: _selectedHours)
        : _apiService.getHistoricalDataStream(hours: _selectedHours);
  }



  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            widget.metric.displayName,
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              try {
                Navigator.of(context).pop();
              } catch (error) {
                developer.log('Error navigating back: $error');
              }
            },
          ),
          actions: [
            StreamBuilder<SensorData?>(
              stream: widget.systemType == 'SCC' 
                  ? _apiService.getLatestSCCDataWithFallbackStream()
                  : _apiService.getLatestSensorDataStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _buildPlantStatusIndicator(snapshot.data);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            
            if (isMobile) {
              return Container(
                color: const Color(0xFF0A0A0A),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top Box - Metric Name
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Hero(
                          tag: 'metric-${widget.metric.key}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    widget.metric.displayName,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.currentValue.toStringAsFixed(2),
                                        style: const TextStyle(
                                          color: Color(0xFF4169E1),
                                          fontSize: 72,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 2,
                                          shadows: [
                                            Shadow(
                                              color: Color(0xFF4169E1),
                                              blurRadius: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        widget.metric.unit,
                                        style: TextStyle(
                                          color: Colors.grey.withOpacity(0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Main Chart
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          height: 400,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: StreamBuilder<List<SensorData>>(
                            stream: _historicalDataStream,
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return _buildErrorWidget(snapshot.error.toString());
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return _buildLoadingWidget();
                              }

                              final metricDataPoints = _apiService.getMetricDataPoints(
                                snapshot.data!,
                                widget.metric,
                              );

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: ModernMetricChart(
                                  data: metricDataPoints.map((point) => MetricData(
                                    timestamp: point.timestamp,
                                    value: point.value,
                                    metricType: widget.metric.key,
                                    unit: widget.metric.unit,
                                  )).toList(),
                                  title: widget.metric.displayName,
                                  unit: widget.metric.unit,
                                  minValue: 0,
                                  maxValue: double.infinity,
                                  primaryColor: _getColorForMetric(widget.metric),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Desktop layout
            return Container(
              color: const Color(0xFF0A0A0A),
              child: Row(
                children: [
                  // Left Column - Stacked Boxes
                  Flexible(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Top Box - Metric Name
                          Hero(
                            tag: 'metric-${widget.metric.key}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      widget.metric.displayName,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          widget.currentValue.toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Color(0xFF4169E1),
                                            fontSize: 72,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 2,
                                            shadows: [
                                              Shadow(
                                                color: Color(0xFF4169E1),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          widget.metric.unit,
                                          style: TextStyle(
                                            color: Colors.grey.withOpacity(0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Mini Chart Box
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: StreamBuilder<List<SensorData>>(
                                stream: widget.systemType == 'SCC' 
                                    ? _apiService.getHistoricalSCCDataStream(hours: 1)
                                    : _apiService.getHistoricalDataStream(hours: 1),
                                builder: (context, snapshot) {
                                  return PaginatedDataList(
                                    data: snapshot.data ?? [],
                                    metric: widget.metric,
                                    primaryColor: _getColorForMetric(widget.metric),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Right Column - Main Chart
                  Flexible(
                    flex: 7,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: StreamBuilder<List<SensorData>>(
                        stream: _historicalDataStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildErrorWidget(snapshot.error.toString());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildLoadingWidget();
                          }

                          final metricDataPoints = _apiService.getMetricDataPoints(
                            snapshot.data!,
                            widget.metric,
                          );

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ModernMetricChart(
                              data: metricDataPoints.map((point) => MetricData(
                                timestamp: point.timestamp,
                                value: point.value,
                                metricType: widget.metric.key,
                                unit: widget.metric.unit,
                              )).toList(),
                              title: widget.metric.displayName,
                              unit: widget.metric.unit,
                              minValue: 0,
                              maxValue: double.infinity,
                              primaryColor: _getColorForMetric(widget.metric),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (error) {
      developer.log('Error building MetricDetailPage: $error');
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error loading metric details',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading historical data',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPlantStatusIndicator(SensorData? sensorData) {
    try {
      final isDeactivated = _apiService.isPlantDeactivated(sensorData);
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDeactivated ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDeactivated ? Colors.red : Colors.green,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDeactivated ? Colors.red : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isDeactivated ? 'Deactivated' : 'Active',
              style: TextStyle(
                color: isDeactivated ? Colors.red : Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      developer.log('Error building plant status indicator: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: const Color(0xFF1A1A1A),
            highlightColor: const Color(0xFF2A2A2A),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading chart data...',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'If no recent data is available, older records will be shown',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorForMetric(SensorMetric metric) {
    switch (metric) {
      // RIC metrics
      case SensorMetric.oxygen:
        return const Color(0xFF10B981); // Green for oxygen purity
      case SensorMetric.oxyFlow:
        return const Color(0xFF3B82F6); // Blue for flow
      case SensorMetric.oxyPressure:
        return const Color(0xFF6366F1); // Indigo for pressure
      case SensorMetric.compLoad:
        return const Color(0xFFF59E0B); // Amber for load
      case SensorMetric.compRunningHour:
        return const Color(0xFF8B5CF6); // Purple for hours
      case SensorMetric.airiTemp:
        return const Color(0xFFEF4444); // Red for inlet temp
      case SensorMetric.airoTemp:
        return const Color(0xFFEC4899); // Pink for outlet temp
      case SensorMetric.airOutletp:
        return const Color(0xFF06B6D4); // Cyan for air pressure
      case SensorMetric.drypdpTemp:
        return const Color(0xFF84CC16); // Lime for dryer temp
      case SensorMetric.boostoTemp:
        return const Color(0xFFF97316); // Orange for booster temp
      case SensorMetric.boosterHour:
        return const Color(0xFF64748B); // Slate for booster hours
      case SensorMetric.compOnStatus:
        return const Color(0xFF22C55E); // Green for compressor status
      case SensorMetric.boosterStatus:
        return const Color(0xFF0EA5E9); // Sky for booster status
      
      // SCC metrics
      case SensorMetric.pressure:
        return const Color(0xFF8B5CF6); // Purple for pressure
      case SensorMetric.trh:
        return const Color(0xFF10B981); // Green for Total Running Hours
      case SensorMetric.trhOnLoad:
        return const Color(0xFF3B82F6); // Blue for Total Running Hours On Load
      case SensorMetric.i1:
        return const Color(0xFFEF4444); // Red for I1
      case SensorMetric.i2:
        return const Color(0xFFEC4899); // Pink for I2
      case SensorMetric.i3:
        return const Color(0xFFF97316); // Orange for I3
      case SensorMetric.contMode:
        return const Color(0xFF84CC16); // Lime for control mode
      case SensorMetric.mh1:
        return const Color(0xFF06B6D4); // Cyan for Maintenance Hours
      case SensorMetric.mh2:
        return const Color(0xFF64748B); // Slate for MH2
      case SensorMetric.mh3:
        return const Color(0xFF22C55E); // Green for MH3
      case SensorMetric.mh4:
        return const Color(0xFF0EA5E9); // Sky for MH4
      case SensorMetric.mh5:
        return const Color(0xFFF59E0B); // Amber for MH5
      case SensorMetric.volts:
        return const Color(0xFF6366F1); // Indigo for voltage
      case SensorMetric.power:
        return const Color(0xFFEF4444); // Red for power
      
      // Additional merged SCC metrics
      case SensorMetric.oxyPurity:
        return const Color(0xFF10B981); // Green for oxygen purity
      case SensorMetric.oxyFlow:
        return const Color(0xFF06B6D4); // Cyan for oxygen flow
      case SensorMetric.bedaPress:
        return const Color(0xFF3B82F6); // Blue for bed A pressure
      case SensorMetric.bedbPress:
        return const Color(0xFF8B5CF6); // Purple for bed B pressure
      case SensorMetric.recPress:
        return const Color(0xFFF59E0B); // Amber for recovery pressure

        //add default
        default:
          return const Color(0xFF64748B); // Slate for default
    }
  }

  @override
  void dispose() {
    try {
      developer.log('Disposing MetricDetailPage');
      // Don't dispose the service here as it might be used by other widgets
      // The service will be disposed when the app is closed
    } catch (e) {
      developer.log('Error disposing MetricDetailPage: $e');
    }
    super.dispose();
  }
}
