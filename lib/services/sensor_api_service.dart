import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';

class SensorApiService {
  static const String _baseUrl = 'https://cloud-dashboard-git-main-sobans-projects-af793893.vercel.app/api';
  static const String _sensorDataEndpoint = '/sensor-data';
  static const String _sccEndpoint = '/scc/all';
  
  // Singleton instance
  static SensorApiService? _instance;
  final http.Client _client;
  bool _isDisposed = false;

  SensorApiService._({http.Client? client}) : _client = client ?? http.Client();

  // Factory constructor for singleton
  factory SensorApiService({http.Client? client}) {
    _instance ??= SensorApiService._(client: client);
    return _instance!;
  }

  /// Fetches sensor data from the Railway API
  Future<SensorDataResponse> getSensorData({
    int page = 1,
    int limit = 1000,
  }) async {
    try {
      if (_isDisposed) {
        developer.log('SensorApiService is disposed, cannot fetch data');
        throw Exception('Service is disposed');
      }
      
      developer.log('Fetching sensor data from API - Page: $page, Limit: $limit');
      
      final uri = Uri.parse('$_baseUrl$_sensorDataEndpoint')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - API took too long to respond');
        },
      );

      developer.log('API Response Status: ${response.statusCode}');
      developer.log('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final sensorResponse = SensorDataResponse.fromJson(jsonData);

        developer.log('Successfully fetched ${sensorResponse.data.length} sensor records');
        return sensorResponse;
      } else {
        developer.log('API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch sensor data: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching sensor data: $e');
      rethrow;
    }
  }

  /// Fetches SCC data from the API
  Future<SensorDataResponse> getSCCData({
    int page = 1,
    int limit = 1000,
  }) async {
    try {
      if (_isDisposed) {
        developer.log('SensorApiService is disposed, cannot fetch SCC data');
        throw Exception('Service is disposed');
      }
      
      developer.log('Fetching SCC data from API - Page: $page, Limit: $limit');
      
      final uri = Uri.parse('$_baseUrl$_sccEndpoint');

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - API took too long to respond');
        },
      );

      developer.log('SCC API Response Status: ${response.statusCode}');
      developer.log('SCC API Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body) as Map<String, dynamic>;
          
          // SCC API has a different response format
          if (jsonData.containsKey('success') && jsonData.containsKey('data')) {
            // SCC API format: {"success": true, "message": "...", "data": [...]}
            final List<dynamic> dataList = jsonData['data'] as List<dynamic>;
            final List<SensorData> sensorDataList = dataList
                .map((item) => SensorData.fromJson(item as Map<String, dynamic>))
                .toList();
            
            final sensorResponse = SensorDataResponse(
              success: true,
              message: 'SCC data fetched successfully',
              data: sensorDataList,
              count: sensorDataList.length,
              pagination: SensorDataPagination(
                totalRecords: sensorDataList.length,
                totalPages: 1,
                currentPage: 1,
                recordsPerPage: sensorDataList.length,
                hasNext: false,
                hasPrevious: false,
                pageStartRecord: 1,
                pageEndRecord: sensorDataList.length,
              ),
            );
            
            developer.log('Successfully fetched ${sensorResponse.data.length} SCC records');
            return sensorResponse;
          } else {
            // Fallback to standard format
            final sensorResponse = SensorDataResponse.fromJson(jsonData);
            developer.log('Successfully fetched ${sensorResponse.data.length} SCC records');
            return sensorResponse;
          }
        } catch (jsonError) {
          developer.log('Error parsing SCC JSON response: $jsonError');
          developer.log('Raw response body: ${response.body}');
          throw Exception('Failed to parse SCC API response: $jsonError');
        }
      } else {
        developer.log('SCC API Error: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch SCC data: HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching SCC data: $e');
      rethrow;
    }
  }

  /// Gets the latest sensor data (first record from the API)
  Future<SensorData?> getLatestSensorData() async {
    try {
      final response = await getSensorData(page: 1, limit: 1);
      return response.data.isNotEmpty ? response.data.first : null;
    } catch (e) {
      developer.log('Error fetching latest sensor data: $e');
      rethrow;
    }
  }

  /// Gets the latest non-null value for a specific metric by checking previous records
  Future<double?> getLatestNonNullValueForMetric(SensorMetric metric, {int maxRecords = 50}) async {
    try {
      developer.log('Looking for latest non-null value for metric: ${metric.key}');
      
      final response = await getSensorData(page: 1, limit: maxRecords);
      
      for (final data in response.data) {
        final value = metric.getValue(data);
        final hasData = _hasMetricData(metric, data);
        
        if (hasData && value != 0.0) {
          developer.log('Found non-null value for ${metric.key}: $value');
          return value;
        }
      }
      
      developer.log('No non-null value found for ${metric.key} in $maxRecords records');
      return null;
    } catch (e) {
      developer.log('Error getting latest non-null value for ${metric.key}: $e');
      return null;
    }
  }

  /// Gets the latest non-null value for a specific SCC metric by checking previous records
  Future<double?> getLatestNonNullSCCValueForMetric(SensorMetric metric, {int maxRecords = 50}) async {
    try {
      developer.log('Looking for latest non-null SCC value for metric: ${metric.key}');
      
      final response = await getSCCData(page: 1, limit: maxRecords);
      
      for (final data in response.data) {
        final value = metric.getValue(data);
        final hasData = _hasMetricData(metric, data);
        
        if (hasData && value != 0.0) {
          developer.log('Found non-null SCC value for ${metric.key}: $value');
          return value;
        }
      }
      
      developer.log('No non-null SCC value found for ${metric.key} in $maxRecords records');
      return null;
    } catch (e) {
      developer.log('Error getting latest non-null SCC value for ${metric.key}: $e');
      return null;
    }
  }

  /// Helper method to check if a metric has data in a sensor data record
  bool _hasMetricData(SensorMetric metric, SensorData data) {
    try {
      switch (metric) {
        case SensorMetric.pressure:
          return data.pressure != null;
        case SensorMetric.trh:
          return data.trh != null;
        case SensorMetric.trhOnLoad:
          return data.trhOnLoad != null;
        case SensorMetric.i1:
          return data.i1 != null;
        case SensorMetric.i2:
          return data.i2 != null;
        case SensorMetric.i3:
          return data.i3 != null;
        case SensorMetric.contMode:
          return data.contMode != null;
        case SensorMetric.mh1:
          return data.mh1 != null;
        case SensorMetric.mh2:
          return data.mh2 != null;
        case SensorMetric.mh3:
          return data.mh3 != null;
        case SensorMetric.mh4:
          return data.mh4 != null;
        case SensorMetric.mh5:
          return data.mh5 != null;
        case SensorMetric.i2:
          return data.i2 != null;
        case SensorMetric.volts:
          return data.volts != null;
        case SensorMetric.power:
          return data.power != null;
        case SensorMetric.oxyPurity:
          return data.oxyPurity != null;
        case SensorMetric.bedaPress:
          return data.bedaPress != null;
        case SensorMetric.bedbPress:
          return data.bedbPress != null;
        case SensorMetric.recPress:
          return data.recPress != null;
        case SensorMetric.pdpTemp:
          return data.oxygen != null;
        case SensorMetric.boosterTemp:
          return data.drypdpTemp != null;
        case SensorMetric.boosterRunningHours:
          return data.boosterHour != null;
        default:
          return true;
      }
    } catch (e) {
      developer.log('Error checking metric data for ${metric.key}: $e');
      return false;
    }
  }

  /// Gets the latest SCC data (first record from the API)
  Future<SensorData?> getLatestSCCData() async {
    try {
      final response = await getSCCData(page: 1, limit: 1);
      return response.data.isNotEmpty ? response.data.first : null;
    } catch (e) {
      developer.log('Error fetching latest SCC data: $e');
      rethrow;
    }
  }

  /// Gets the latest SCC data with fallback values for null metrics
  /// Falls back to most recent non-null values within the last 1 minute
  Future<SensorData?> getLatestSCCDataWithFallback() async {
    try {
      // Fetch multiple records to have fallback data available
      final response = await getSCCData(page: 1, limit: 100);
      if (response.data.isEmpty) return null;

      final latestData = response.data.first;
      final now = DateTime.now();

      // Create a map to store fallback values for null metrics
      final Map<String, double?> fallbackValues = {};

      // Define all metrics to check for fallback values
      final allMetrics = [
        SensorMetric.mh5,
        SensorMetric.pressure,
        SensorMetric.trh,
        SensorMetric.trhOnLoad,
        SensorMetric.i1,
        SensorMetric.i2,
        SensorMetric.mh1,
        SensorMetric.mh3,
        SensorMetric.mh4,
        SensorMetric.volts,
        SensorMetric.power,
        SensorMetric.oxyPurity,
        SensorMetric.bedaPress,
        SensorMetric.bedbPress,
        SensorMetric.recPress,
        SensorMetric.pdpTemp,
        SensorMetric.boosterTemp,
        SensorMetric.boosterRunningHours,
      ];

      // For each metric, if it's null in the latest data, find the most recent non-null value
      for (final metric in allMetrics) {
        if (!_hasMetricData(metric, latestData)) {
          // Search through recent records (within 1 minute) for a non-null value
          for (final data in response.data) {
            final dataTime = data.parsedTimestamp;
            final timeDifference = now.difference(dataTime);

            // Only use data from the last 1 minute
            if (timeDifference.inMinutes > 1) break;

            if (_hasMetricData(metric, data)) {
              final value = metric.getValue(data);
              if (value != 0.0) {
                fallbackValues[metric.key] = value;
                developer.log('Using fallback value for ${metric.key}: $value (${timeDifference.inSeconds}s old)');
                break;
              }
            }
          }
        }
      }

      // If no fallback values are needed, return the original data
      if (fallbackValues.isEmpty) {
        return latestData;
      }

      // Create a new SensorData object with fallback values
      return SensorData(
        airiTemp: latestData.airiTemp,
        airoTemp: latestData.airoTemp,
        boosterStatus: latestData.boosterStatus,
        boostoTemp: latestData.boostoTemp,
        compOnStatus: latestData.compOnStatus,
        drypdpTemp: latestData.drypdpTemp,
        oxygen: latestData.oxygen,
        airOutletp: latestData.airOutletp,
        boosterHour: latestData.boosterHour,
        compLoad: latestData.compLoad,
        compRunningHour: latestData.compRunningHour,
        oxyFlow: latestData.oxyFlow,
        oxyPressure: latestData.oxyPressure,
        pressure: fallbackValues['pressure'] ?? latestData.pressure,
        trh: fallbackValues['trh'] ?? latestData.trh,
        trhOnLoad: fallbackValues['trh_on_load'] ?? latestData.trhOnLoad,
        i1: fallbackValues['i1'] ?? latestData.i1,
        i2: fallbackValues['i2'] ?? latestData.i2,
        i3: fallbackValues['i3'] ?? latestData.i3,
        contMode: fallbackValues['cont_mode']?.round() ?? latestData.contMode,
        mh1: fallbackValues['mh_1'] ?? latestData.mh1,
        mh2: fallbackValues['mh_2'] ?? latestData.mh2,
        mh3: fallbackValues['mh_3'] ?? latestData.mh3,
        mh4: fallbackValues['mh_4'] ?? latestData.mh4,
        mh5: fallbackValues['mh_5'] ?? latestData.mh5,
        volts: fallbackValues['volts'] ?? latestData.volts,
        power: fallbackValues['power'] ?? latestData.power,
        tableSource: latestData.tableSource,
        oxyPurity: fallbackValues['oxy_purity'] ?? latestData.oxyPurity,
        bedaPress: fallbackValues['beda_press'] ?? latestData.bedaPress,
        bedbPress: fallbackValues['bedb_press'] ?? latestData.bedbPress,
        recPress: fallbackValues['rec_press'] ?? latestData.recPress,
        timestamp: latestData.timestamp,
        id: latestData.id,
      );
    } catch (e) {
      developer.log('Error getting SCC data with fallback: $e');
      return await getLatestSCCData(); // Fallback to regular method
    }
  }

  /// Checks if the plant is deactivated based on the latest sensor data
  /// Returns true if the latest value is more than 5 minutes old
  bool isPlantDeactivated(SensorData? latestData) {
    try {
      if (latestData == null) {
        developer.log('No sensor data available - plant considered deactivated');
        return true;
      }

      final now = DateTime.now();
      final dataTime = latestData.parsedTimestamp;
      final timeDifference = now.difference(dataTime);
      
      final isDeactivated = timeDifference.inMinutes > 5;
      
      if (isDeactivated) {
        developer.log('Plant is deactivated - latest data is ${timeDifference.inMinutes} minutes old');
      } else {
        developer.log('Plant is active - latest data is ${timeDifference.inMinutes} minutes old');
      }
      
      return isDeactivated;
    } catch (e) {
      developer.log('Error checking plant deactivation status: $e');
      return true; // Consider deactivated if there's an error
    }
  }

  /// Gets historical sensor data for a specific time range
  /// If no data exists within the specified time range, returns older available data
  Future<List<SensorData>> getHistoricalData({
    int hours = 24,
    int maxRecords = 1000,
  }) async {
    try {
      developer.log('Fetching historical data for last $hours hours');
      
      // Since the API returns data in reverse chronological order,
      // we'll fetch more records and filter by time
      final response = await getSensorData(page: 1, limit: maxRecords);
      
      final now = DateTime.now();
      final cutoffTime = now.subtract(Duration(hours: hours));
      
      // Filter data within the specified time range
      final filteredData = response.data.where((data) {
        final dataTime = data.parsedTimestamp;
        return dataTime.isAfter(cutoffTime);
      }).toList();
      
      // If no data within the specified time range, return older available data
      if (filteredData.isEmpty && response.data.isNotEmpty) {
        developer.log('No data within $hours hours, showing older available data');
        
        // Take the most recent records available (up to 100 for performance)
        final fallbackData = response.data.take(100).toList();
        
        // Sort by timestamp (oldest first for charting)
        fallbackData.sort((a, b) => a.parsedTimestamp.compareTo(b.parsedTimestamp));
        
        developer.log('Showing ${fallbackData.length} older records as fallback');
        return fallbackData;
      }
      
      // Sort by timestamp (oldest first for charting)
      filteredData.sort((a, b) => a.parsedTimestamp.compareTo(b.parsedTimestamp));
      
      developer.log('Filtered ${filteredData.length} records within $hours hours');
      return filteredData;
    } catch (e) {
      developer.log('Error fetching historical data: $e');
      rethrow;
    }
  }

  /// Gets historical SCC data for a specific time range
  /// If no data exists within the specified time range, returns older available data
  Future<List<SensorData>> getHistoricalSCCData({
    int hours = 24,
    int maxRecords = 1000,
  }) async {
    try {
      developer.log('Fetching historical SCC data for last $hours hours');
      
      // Since the API returns data in reverse chronological order,
      // we'll fetch more records and filter by time
      final response = await getSCCData(page: 1, limit: maxRecords);
      
      final now = DateTime.now();
      final cutoffTime = now.subtract(Duration(hours: hours));
      
      // Filter data within the specified time range
      final filteredData = response.data.where((data) {
        final dataTime = data.parsedTimestamp;
        return dataTime.isAfter(cutoffTime);
      }).toList();
      
      // If no data within the specified time range, return older available data
      if (filteredData.isEmpty && response.data.isNotEmpty) {
        developer.log('No SCC data within $hours hours, showing older available data');
        
        // Take the most recent records available (up to 100 for performance)
        final fallbackData = response.data.take(100).toList();
        
        // Sort by timestamp (oldest first for charting)
        fallbackData.sort((a, b) => a.parsedTimestamp.compareTo(b.parsedTimestamp));
        
        developer.log('Showing ${fallbackData.length} older SCC records as fallback');
        return fallbackData;
      }
      
      // Sort by timestamp (oldest first for charting)
      filteredData.sort((a, b) => a.parsedTimestamp.compareTo(b.parsedTimestamp));
      
      developer.log('Filtered ${filteredData.length} SCC records within $hours hours');
      return filteredData;
    } catch (e) {
      developer.log('Error fetching historical SCC data: $e');
      rethrow;
    }
  }

  /// Gets historical sensor data for a custom date range
  Future<List<SensorData>> getHistoricalDataByDateRange({
    required DateTime fromDate,
    required DateTime toDate,
    int maxRecords = 1000,
  }) async {
    try {
      developer.log('Fetching historical data from ${fromDate.toIso8601String()} to ${toDate.toIso8601String()}');
      
      // Since the API returns data in reverse chronological order,
      // we'll fetch more records and filter by date range
      final response = await getSensorData(page: 1, limit: maxRecords);
      
      // Filter data within the specified date range
      final filteredData = response.data.where((data) {
        final dataTime = data.parsedTimestamp;
        return dataTime.isAfter(fromDate) && dataTime.isBefore(toDate);
      }).toList();
      
      // Sort by timestamp (oldest first for charting)
      filteredData.sort((a, b) => a.parsedTimestamp.compareTo(b.parsedTimestamp));
      
      developer.log('Filtered ${filteredData.length} records within date range');
      return filteredData;
    } catch (e) {
      developer.log('Error fetching historical data by date range: $e');
      rethrow;
    }
  }

  /// Stream that periodically fetches the latest sensor data
  Stream<SensorData?> getLatestSensorDataStream({
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (!_isDisposed) {
      try {
        if (_isDisposed) break;
        
        final latestData = await getLatestSensorData();
        if (!_isDisposed) {
          yield latestData;
        }
      } catch (e) {
        if (!_isDisposed) {
          developer.log('Error in sensor data stream: $e');
          yield null;
        }
      }
      
      if (!_isDisposed) {
        await Future.delayed(interval);
      }
    }
  }

  /// Stream that periodically fetches the latest SCC data
  Stream<SensorData?> getLatestSCCDataStream({
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (!_isDisposed) {
      try {
        if (_isDisposed) break;
        
        final latestData = await getLatestSCCData();
        if (!_isDisposed) {
          yield latestData;
        }
      } catch (e) {
        if (!_isDisposed) {
          developer.log('Error in SCC data stream: $e');
          yield null;
        }
      }
      
      if (!_isDisposed) {
        await Future.delayed(interval);
      }
    }
  }

  /// Stream that periodically fetches the latest SCC data with fallback values
  Stream<SensorData?> getLatestSCCDataWithFallbackStream({
    Duration interval = const Duration(seconds: 30),
  }) async* {
    while (!_isDisposed) {
      try {
        if (_isDisposed) break;
        
        final latestData = await getLatestSCCDataWithFallback();
        if (!_isDisposed) {
          yield latestData;
        }
      } catch (e) {
        if (!_isDisposed) {
          developer.log('Error in SCC data with fallback stream: $e');
          yield null;
        }
      }
      
      if (!_isDisposed) {
        await Future.delayed(interval);
      }
    }
  }

  /// Stream that periodically fetches historical data for charts
  Stream<List<SensorData>> getHistoricalDataStream({
    int hours = 24,
    Duration interval = const Duration(minutes: 1),
  }) async* {
    while (!_isDisposed) {
      try {
        if (_isDisposed) break;
        
        final historicalData = await getHistoricalData(hours: hours);
        if (!_isDisposed) {
          yield historicalData;
        }
      } catch (e) {
        if (!_isDisposed) {
          developer.log('Error in historical data stream: $e');
          yield [];
        }
      }
      
      if (!_isDisposed) {
        await Future.delayed(interval);
      }
    }
  }

  /// Stream that periodically fetches historical SCC data for charts
  Stream<List<SensorData>> getHistoricalSCCDataStream({
    int hours = 24,
    Duration interval = const Duration(minutes: 1),
  }) async* {
    while (!_isDisposed) {
      try {
        if (_isDisposed) break;
        
        final historicalData = await getHistoricalSCCData(hours: hours);
        if (!_isDisposed) {
          yield historicalData;
        }
      } catch (e) {
        if (!_isDisposed) {
          developer.log('Error in historical SCC data stream: $e');
          yield [];
        }
      }
      
      if (!_isDisposed) {
        await Future.delayed(interval);
      }
    }
  }

  /// Stream that fetches historical data for a custom date range
  Stream<List<SensorData>> getHistoricalDataByDateRangeStream({
    required DateTime fromDate,
    required DateTime toDate,
    Duration interval = const Duration(minutes: 1),
  }) async* {
    while (!_isDisposed) {
      try {
        if (_isDisposed) break;
        
        final historicalData = await getHistoricalDataByDateRange(
          fromDate: fromDate,
          toDate: toDate,
        );
        if (!_isDisposed) {
          yield historicalData;
        }
      } catch (e) {
        if (!_isDisposed) {
          developer.log('Error in historical data by date range stream: $e');
          yield [];
        }
      }
      
      if (!_isDisposed) {
        await Future.delayed(interval);
      }
    }
  }

  /// Gets sensor data for a specific metric type
  List<MetricDataPoint> getMetricDataPoints(
    List<SensorData> sensorDataList, 
    SensorMetric metric,
  ) {
    try {
      return sensorDataList.map((data) {
        return MetricDataPoint(
          timestamp: data.parsedTimestamp,
          value: metric.getValue(data),
        );
      }).toList();
    } catch (e) {
      developer.log('Error converting sensor data to metric points: $e');
      return [];
    }
  }

  void dispose() {
    try {
      developer.log('Disposing SensorApiService');
      _isDisposed = true;
      _client.close();
    } catch (e) {
      developer.log('Error disposing SensorApiService: $e');
    }
  }

  /// Static method to dispose the singleton instance
  static void disposeInstance() {
    try {
      if (_instance != null) {
        developer.log('Disposing SensorApiService singleton');
        _instance!._isDisposed = true;
        _instance!._client.close();
        _instance = null;
      }
    } catch (e) {
      developer.log('Error disposing SensorApiService singleton: $e');
    }
  }
}

/// Data point for charting
class MetricDataPoint {
  final DateTime timestamp;
  final double value;

  const MetricDataPoint({
    required this.timestamp,
    required this.value,
  });
}
