import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/metric_gauge.dart';
import '../../../../services/sensor_api_service.dart';
import '../../../../models/sensor_data.dart';
import 'metric_detail_page.dart';
import '../../../selection/presentation/pages/selection_page.dart';
import 'dart:developer' as developer;

class DashboardPage extends StatefulWidget {
  final String systemType; // 'RIC' or 'SCC'
  
  const DashboardPage({
    super.key,
    this.systemType = 'RIC',
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SensorApiService _apiService = SensorApiService();
  late Stream<SensorData?> _sensorDataStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    developer.log('DashboardPage initialized for ${widget.systemType}');
    _sensorDataStream = widget.systemType == 'SCC'
        ? _apiService.getLatestSCCDataWithFallbackStream()
        : _apiService.getLatestSensorDataStream();
  }

  void _scrollDown() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.position.pixels;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double targetPosition = (currentPosition + 200).clamp(0.0, maxScroll);

      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollUp() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.position.pixels;
      final double targetPosition = (currentPosition - 200).clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToSelection() {
    try {
      developer.log('Navigating back to System Selection');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SelectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0),
            ));

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (error) {
      developer.log('Error navigating to selection: $error');
    }
  }

  void _navigateToMetricDetail(SensorMetric metric, double currentValue) {
    try {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MetricDetailPage(
            metric: metric,
            currentValue: currentValue,
            systemType: widget.systemType,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.3, 1.0),
            ));

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (error) {
      developer.log('Error navigating to metric detail: $error');
    }
  }

  Future<void> _launchTroubleshooter() async {
    final Uri url = Uri.parse('https://www.psatroubleshooter.com/');
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank'
      );
      if (!launched) {
        developer.log('Could not launch $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open troubleshooter. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (error) {
      developer.log('Error launching troubleshooter: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening troubleshooter: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPlantStatusIndicator(SensorData? sensorData) {
    try {
      final isDeactivated = _apiService.isPlantDeactivated(sensorData);
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDeactivated ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDeactivated ? Colors.red : Colors.green,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDeactivated ? Colors.red : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isDeactivated ? 'Plant Deactivated' : 'Plant Active',
              style: TextStyle(
                color: isDeactivated ? Colors.red : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      developer.log('Error building plant status indicator: $e');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Status Unknown',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTroubleshootButton() {
    return InkWell(
      onTap: _launchTroubleshooter,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.build_circle,
              color: Color(0xFF3B82F6),
              size: 14,
            ),
            const SizedBox(width: 6),
            const Text(
              'Troubleshoot',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMetricData(SensorMetric metric, SensorData sensorData) {
    try {
      switch (metric) {
        case SensorMetric.pressure:
          return sensorData.pressure != null;
        case SensorMetric.trh:
          return sensorData.trh != null;
        case SensorMetric.trhOnLoad:
          return sensorData.trhOnLoad != null;
        case SensorMetric.i1:
          return sensorData.i1 != null;
        case SensorMetric.i2:
          return sensorData.i2 != null;
        case SensorMetric.i3:
          return sensorData.i3 != null;
        case SensorMetric.contMode:
          return sensorData.contMode != null;
        case SensorMetric.mh1:
          return sensorData.mh1 != null;
        case SensorMetric.mh2:
          return sensorData.mh2 != null;
        case SensorMetric.mh3:
          return sensorData.mh3 != null;
        case SensorMetric.mh4:
          return sensorData.mh4 != null;
        case SensorMetric.mh5:
          return sensorData.mh5 != null;
        case SensorMetric.volts:
          return sensorData.volts != null;
        case SensorMetric.power:
          return sensorData.power != null;
        case SensorMetric.oxyPurity:
          return sensorData.oxyPurity != null;
        case SensorMetric.oxyFlow:
          return sensorData.oxyFlow != null;
        case SensorMetric.bedaPress:
          return sensorData.bedaPress != null;
        case SensorMetric.bedbPress:
          return sensorData.bedbPress != null;
        case SensorMetric.recPress:
          return sensorData.recPress != null;
        case SensorMetric.pdpTemp:
          return sensorData.oxygen != null;
        case SensorMetric.boosterTemp:
          return sensorData.drypdpTemp != null;
        case SensorMetric.boosterRunningHours:
          return sensorData.boosterHour != null;
        default:
          return true;
      }
    } catch (e) {
      developer.log('Error checking metric data for ${metric.key}: $e');
      return false;
    }
  }

  Widget _buildNoDataGauge(SensorMetric metric, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.signal_cellular_off,
                  color: color.withOpacity(0.3),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Data',
                  style: TextStyle(
                    color: color.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.unit,
                  style: TextStyle(
                    color: color.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGauge() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<SensorData?>(
        stream: _sensorDataStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            developer.log('Error in StreamBuilder: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }

          final sensorData = snapshot.data;
          
          return Container(
            color: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _navigateToSelection(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
                          ),
                          tooltip: 'Back to System Selection',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(widget.systemType == 'SCC' ? 'Bahawalpur Site\nModbus' : 'RIC\nAnalog')} ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildPlantStatusIndicator(sensorData),
                        const SizedBox(width: 8),
                        _buildTroubleshootButton(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildMetricsGrid(sensorData, !snapshot.hasData),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(SensorData? sensorData, bool isLoading) {
    // For SCC (Bahawalpur) system, create distinct sections
    if (widget.systemType == 'SCC') {
      return _buildSCCSections(sensorData, isLoading);
    }

    // For RIC system, use sectioned layout
    return _buildRICSections(sensorData, isLoading);
  }

  Widget _buildRICSections(SensorData? sensorData, bool isLoading) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PSA Oxygen Generator's Parameters Section
              _buildSectionHeader('PSA Oxygen Generator\'s Parameters'),
              const SizedBox(height: 16),
              _buildMetricsSection([
                SensorMetric.oxygen,
                SensorMetric.oxyPressure,
              ], sensorData, isLoading),

              const SizedBox(height: 32),

              // MedGas Analyzer's Parameters Section
              _buildSectionHeader('MedGas Analyzer\'s Parameters'),
              const SizedBox(height: 16),
              _buildMetricsSection([
                SensorMetric.ga1,
                SensorMetric.ga2,
                SensorMetric.ga3,
                SensorMetric.ga4,
              ], sensorData, isLoading),

              const SizedBox(height: 32),

              // Compressor's Parameters Section
              _buildSectionHeader('Compressor\'s Parameters'),
              const SizedBox(height: 16),
              _buildMetricsSection([
                SensorMetric.compLoad,
                SensorMetric.compOnStatus,
                SensorMetric.airiTemp,
                SensorMetric.dischargePressure,
                SensorMetric.airoTemp,
                SensorMetric.compRunningHour,
              ], sensorData, isLoading),

              const SizedBox(height: 32),

              // Dryer's Parameters Section
              _buildSectionHeader('Dryer\'s Parameters'),
              const SizedBox(height: 16),
              _buildMetricsSection([
                SensorMetric.drypdpTemp,
              ], sensorData, isLoading),

              const SizedBox(height: 32),

              // Booster's Parameters Section
              _buildSectionHeader('Booster\'s Parameters'),
              const SizedBox(height: 16),
              _buildMetricsSection([
                SensorMetric.boosterStatus,
                SensorMetric.boostoTemp,
                SensorMetric.boosterPressure,
                SensorMetric.boosterHour,
              ], sensorData, isLoading),
            ],
          ),
        ),
        // Scroll buttons
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScrollButton(Icons.keyboard_arrow_up, _scrollUp),
              const SizedBox(height: 8),
              _buildScrollButton(Icons.keyboard_arrow_down, _scrollDown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSCCSections(SensorData? sensorData, bool isLoading) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compressor's Parameters Section
              _buildSectionHeader('Compressor\'s Parameters'),
              const SizedBox(height: 16),
              _buildCompressorMetricsGrid(sensorData, isLoading),

              const SizedBox(height: 32),

              // PSA Oxygen Generator's Parameters Section
              _buildSectionHeader('PSA Oxygen Generator\'s Parameters'),
              const SizedBox(height: 16),
              _buildPSAMetricsGrid(sensorData, isLoading),

              const SizedBox(height: 32),

              // Dryer's Parameters Section
              _buildSectionHeader('Dryer\'s Parameters'),
              const SizedBox(height: 16),
              _buildDryerMetricsGrid(sensorData, isLoading),

              const SizedBox(height: 32),

              // Booster's Parameters Section
              _buildSectionHeader('Booster\'s Parameters'),
              const SizedBox(height: 16),
              _buildBoosterMetricsGrid(sensorData, isLoading),
            ],
          ),
        ),
        // Scroll buttons
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScrollButton(Icons.keyboard_arrow_up, _scrollUp),
              const SizedBox(height: 8),
              _buildScrollButton(Icons.keyboard_arrow_down, _scrollDown),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: Colors.blue.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressorMetricsGrid(SensorData? sensorData, bool isLoading) {
    // Compressor parameters: ambient temperature, discharge temperature, pressure, current, voltage, power, maintenance hours, total running hours, total running hours on load
    final compressorMetrics = [
      SensorMetric.sccAmbientTemp,
      SensorMetric.mh5,
      SensorMetric.pressure,
      SensorMetric.i1,
      SensorMetric.volts,
      SensorMetric.power,
      SensorMetric.mh1,
      SensorMetric.trh,
      SensorMetric.trhOnLoad,
    ];

    return Column(
      children: [
        _buildMetricsSection(compressorMetrics, sensorData, isLoading),
        const SizedBox(height: 16),
        _buildCompressorStatusSection(sensorData, isLoading),
      ],
    );
  }

  Widget _buildCompressorStatusSection(SensorData? sensorData, bool isLoading) {
    if (isLoading || sensorData == null) {
      return Row(
        children: [
          Expanded(child: _buildShimmerGauge()),
          const SizedBox(width: 8),
          Expanded(child: _buildShimmerGauge()),
          const SizedBox(width: 8),
          Expanded(child: _buildShimmerGauge()),
        ],
      );
    }

    final preAlarmValue = (sensorData.i2 ?? 0).round();
    final runStateValue = (sensorData.mh4 ?? 0).round();
    final faultValue = (sensorData.mh3 ?? 0).round();

    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Pre Alarming',
            status: _getPreAlarmText(preAlarmValue),
            color: preAlarmValue == 0 ? Colors.green : Colors.orange,
            icon: preAlarmValue == 0 ? Icons.check_circle : Icons.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusCard(
            title: 'Run State',
            status: _getRunStateText(runStateValue),
            color: Colors.blue,
            icon: Icons.play_circle_filled,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusCard(
            title: 'Fault',
            status: _getFaultText(faultValue),
            color: faultValue == 0 ? Colors.green : Colors.red,
            icon: faultValue == 0 ? Icons.check_circle : Icons.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getPreAlarmText(int value) {
    switch (value) {
      case 1:
        return 'Air Exhaust Temperature High Pre-alarm';
      case 2:
        return 'System Temperature High';
      case 3:
        return 'High Temperature 3';
      case 8:
        return 'Oil Filter Time Up';
      case 9:
        return 'Oil Separators Time Up';
      case 10:
        return 'Air Filter Time Up';
      case 11:
        return 'Lube Oil Time Up';
      case 12:
        return 'Lube Grease Time Up';
      case 13:
        return 'Oil Filter Blocked';
      case 14:
        return 'Oil Separator Blocked';
      case 15:
        return 'Air Filter Blocked';
      case 16:
        return 'Host Inverter Receives Stop Instruction';
      case 17:
        return 'Fan Inverter Receives Stop Instruction';
      case 18:
        return 'Differential Pressure Warning';
      default:
        return 'No Alarm';
    }
  }

  String _getRunStateText(int value) {
    switch (value) {
      case 1:
        return 'Abnormal Stop';
      case 2:
        return 'Emergency Stop';
      case 3:
        return 'Stop Delay';
      case 4:
        return 'Variable Frequency Starting';
      case 5:
        return 'Star Delta';
      case 6:
        return 'Star Delta Run';
      case 7:
        return 'Auto-Unloading';
      case 8:
        return 'Auto-Loading';
      case 9:
        return 'Unload Long Time to Stop';
      case 10:
        return 'Machine Stopped';
      case 11:
        return 'Soft Start';
      case 12:
        return 'Pre-Open Host Inverter';
      case 16:
        return 'Ready for Start';
      case 17:
        return 'Manually Unloading';
      case 18:
        return 'Manually Loading';
      case 19:
        return 'Host Inverter Receives Run Instruction';
      case 21:
        return 'Fan Inverter Receives Run Instruction';
      case 22:
        return 'Inverter in Operation';
      case 23:
        return 'Low Temperature';
      case 24:
        return 'Power Off to Restart';
      case 25:
        return 'System Discharge';
      default:
        return 'Normal';
    }
  }

  String _getFaultText(int value) {
    switch (value) {
      case 1:
        return 'Host Overload';
      case 2:
        return 'Host Imbalance';
      case 3:
        return 'Host Lacking Phase';
      case 4:
        return 'Fan Overload';
      case 6:
        return 'Temperature 1 Sensor Failure';
      case 7:
        return 'High Temperature 1';
      case 10:
        return 'Pressure 1 Sensor Failure';
      case 11:
        return 'Pressure 1 High';
      case 12:
        return 'Pressure 2 Sensor Failure';
      case 13:
        return 'Pressure 2 High';
      case 14:
        return 'Differential Pressure Stop';
      case 16:
        return 'Use Error';
      case 17:
        return 'Warning Too Long to Stop';
      case 18:
        return 'Low Voltage';
      case 19:
        return 'High Voltage';
      case 20:
        return 'Phase-Sequence Fault (Out of Phase)';
      case 21:
        return 'Phase-Sequence Fault (Lacking Phase)';
      case 22:
        return 'Water Lacking';
      case 23:
        return 'Tank Temperature High';
      case 24:
        return 'Coil Temperature High';
      case 25:
        return 'Bearing Temperature High';
      case 26:
        return 'Electrical Fault';
      case 27:
        return 'Host Overload';
      case 28:
        return 'Fan Overload';
      case 29:
        return 'Air End Failure';
      case 30:
        return 'Dryer Fault';
      case 31:
        return 'Host Inverter Failure I/O';
      case 32:
        return 'Fan Inverter Failure I/O';
      case 33:
        return 'Read Host Inverter Failure';
      case 34:
        return 'Close Host Inverter Failure';
      case 35:
        return 'Host Inverter Failure';
      case 36:
        return 'Read Fan Inverter Failure';
      case 37:
        return 'Soft Starters Failure';
      case 38:
        return 'Fan Inverter Failure';
      case 39:
        return 'Temperature 2 Sensor Failure';
      case 40:
        return 'Temperature 2 High';
      case 41:
        return 'Temperature 3 Sensor Failure';
      case 42:
        return 'Temperature 3 High';
      default:
        return 'No Fault';
    }
  }

  Widget _buildPSAMetricsGrid(SensorData? sensorData, bool isLoading) {
    // PSA Oxygen Generator parameters: oxygen purity, oxygen flow, bed A pressure, bed B pressure, receiver pressure
    final psaMetrics = [
      SensorMetric.oxyPurity,
      SensorMetric.airOutletp,
      SensorMetric.bedaPress,
      SensorMetric.bedbPress,
      SensorMetric.recPress,
    ];

    return _buildMetricsSection(psaMetrics, sensorData, isLoading);
  }

  Widget _buildDryerMetricsGrid(SensorData? sensorData, bool isLoading) {
    // Dryer parameters: PDP Temperature
    final dryerMetrics = [
      SensorMetric.pdpTemp,
    ];

    return _buildMetricsSection(dryerMetrics, sensorData, isLoading);
  }

  Widget _buildBoosterMetricsGrid(SensorData? sensorData, bool isLoading) {
    // Booster parameters: Booster Temperature, Booster Running Hours
    final boosterMetrics = [
      SensorMetric.boosterTemp,
      SensorMetric.boosterRunningHours,
    ];

    return _buildMetricsSection(boosterMetrics, sensorData, isLoading);
  }

  Widget _buildMetricsSection(List<SensorMetric> metrics, SensorData? sensorData, bool isLoading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid layout based on screen size
        int crossAxisCount;
        double childAspectRatio;
        
        if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.0;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.1;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.2;
        } else {
          crossAxisCount = 5;
          childAspectRatio = 1.3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            
            if (isLoading || sensorData == null) {
              return _buildShimmerGauge();
            }

            final value = metric.getValue(sensorData);
            final maxValue = _getMaxValueForMetric(metric);
            final color = _getColorForMetric(metric);
            final hasData = _hasMetricData(metric, sensorData);

            // Dynamic unit for status metrics
            final unit = metric == SensorMetric.compOnStatus
                ? (value == 1.0 ? 'ON' : value == 0.0 ? 'OFF' : '')
                : metric.unit;

            return Hero(
              tag: 'metric-${metric.key}',
              child: Material(
                type: MaterialType.transparency,
                child: GestureDetector(
                  onTap: hasData ? () => _navigateToMetricDetail(metric, value) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasData ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: hasData
                          ? MetricGauge(
                              title: metric.displayName,
                              value: value,
                              unit: unit,
                              maxValue: maxValue,
                              color: color,
                            )
                          : _buildNoDataGauge(metric, color),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _getMaxValueForMetric(SensorMetric metric) {
    switch (metric) {
      // RIC metrics
      case SensorMetric.oxygen:
        return 100;
      case SensorMetric.oxyFlow:
        return 50;
      case SensorMetric.oxyPressure:
        return 10;
      case SensorMetric.compLoad:
        return 100;
      case SensorMetric.compRunningHour:
        return 1000;
      case SensorMetric.airiTemp:
      case SensorMetric.airoTemp:
      case SensorMetric.boostoTemp:
      case SensorMetric.drypdpTemp:
        return 100;
      case SensorMetric.airOutletp:
        return 15;
      case SensorMetric.boosterHour:
        return 1000;
      case SensorMetric.compOnStatus:
        return 100;
      case SensorMetric.boosterStatus:
        return 1;
      
      // SCC metrics
      case SensorMetric.pressure:
        return 200;
      case SensorMetric.trh:
      case SensorMetric.trhOnLoad:
        return 30000;
      case SensorMetric.i1:
        return 1000;
      case SensorMetric.i2:
      case SensorMetric.i3:
        return 1000;
      case SensorMetric.contMode:
        return 5;
      case SensorMetric.mh1:
        return 2000;
      case SensorMetric.mh2:
      case SensorMetric.mh3:
      case SensorMetric.mh4:
      case SensorMetric.mh5:
        return 150;
      case SensorMetric.volts:
        return 500;
      case SensorMetric.power:
        return 1000;
      
      // Additional merged SCC metrics
      case SensorMetric.oxyPurity:
        return 100;
      case SensorMetric.oxyFlow:
        return 50;
      case SensorMetric.bedaPress:
      case SensorMetric.bedbPress:
      case SensorMetric.recPress:
        return 100;

      // SCC-specific display names for Dryer and Booster sections
      case SensorMetric.pdpTemp:
        return 150;
      case SensorMetric.boosterTemp:
        return 150;
      case SensorMetric.boosterRunningHours:
        return 1000;
      case SensorMetric.boosterPressure:
        return 50;
      case SensorMetric.dischargePressure:
        return 15;
      case SensorMetric.sccAmbientTemp:
        return 100;
      case SensorMetric.ga1:
        return 100;
      case SensorMetric.ga2:
        return 100;
      case SensorMetric.ga3:
        return 100;
      case SensorMetric.ga4:
        return 100;
    }
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
        return const Color(0xFF06B6D4); // Cyan for ambient temperature
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

      // SCC-specific display names for Dryer and Booster sections
      case SensorMetric.pdpTemp:
        return const Color(0xFFEC4899); // Pink for PDP temperature
      case SensorMetric.boosterTemp:
        return const Color(0xFFF97316); // Orange for booster temperature
      case SensorMetric.boosterRunningHours:
        return const Color(0xFF64748B); // Slate for booster hours
      case SensorMetric.boosterPressure:
        return const Color(0xFF3B82F6); // Blue for booster pressure
      case SensorMetric.dischargePressure:
        return const Color(0xFF8B5CF6); // Purple for discharge pressure
      case SensorMetric.sccAmbientTemp:
        return const Color(0xFF06B6D4); // Cyan for ambient temperature
      case SensorMetric.ga1:
        return const Color(0xFFF59E0B); // Amber for SO2
      case SensorMetric.ga2:
        return const Color(0xFFEF4444); // Red for NO2
      case SensorMetric.ga3:
        return const Color(0xFF10B981); // Green for CO2
      case SensorMetric.ga4:
        return const Color(0xFF8B5CF6); // Purple for CO
    }
  }

  @override
  void dispose() {
    try {
      developer.log('Disposing DashboardPage');
      _scrollController.dispose();
      // Don't dispose the service here as it might be used by other widgets
      // The service will be disposed when the app is closed
    } catch (e) {
      developer.log('Error disposing DashboardPage: $e');
    }
    super.dispose();
  }
} 