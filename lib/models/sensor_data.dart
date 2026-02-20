import 'package:json_annotation/json_annotation.dart';

part 'sensor_data.g.dart';

@JsonSerializable()
class SensorData {
  @JsonKey(name: 'airi_temp')
  final double? airiTemp;
  
  @JsonKey(name: 'airo_temp')
  final double? airoTemp;
  
  @JsonKey(name: 'booster_status')
  final int? boosterStatus;
  
  @JsonKey(name: 'boosto_temp')
  final double? boostoTemp;
  
  @JsonKey(name: 'comp_on_status')
  final int? compOnStatus;
  
  @JsonKey(name: 'drypdp_temp')
  final double? drypdpTemp;
  
  final double? oxygen;
  
  @JsonKey(name: 'air_outletp')
  final double? airOutletp;
  
  @JsonKey(name: 'booster_hour')
  final double? boosterHour;
  
  @JsonKey(name: 'comp_load')
  final double? compLoad;
  
  @JsonKey(name: 'comp_running_hour')
  final double? compRunningHour;
  
  @JsonKey(name: 'oxy_flow')
  final double? oxyFlow;
  
  @JsonKey(name: 'oxy_pressure')
  final double? oxyPressure;
  
  // SCC specific fields
  final double? pressure;
  final double? trh;
  @JsonKey(name: 'trh_on_load')
  final double? trhOnLoad;
  final double? i1;
  final double? i2;
  final double? i3;
  @JsonKey(name: 'cont_mode')
  final int? contMode;
  @JsonKey(name: 'mh_1')
  final double? mh1;
  @JsonKey(name: 'mh_2')
  final double? mh2;
  @JsonKey(name: 'mh_3')
  final double? mh3;
  @JsonKey(name: 'mh_4')
  final double? mh4;
  @JsonKey(name: 'mh_5')
  final double? mh5;
  final double? volts;
  final double? power;
  @JsonKey(name: 'table_source')
  final String? tableSource;
  
  // Additional merged fields from cloud_table
  @JsonKey(name: 'oxy_purity')
  final double? oxyPurity;
  @JsonKey(name: 'beda_press')
  final double? bedaPress;
  @JsonKey(name: 'bedb_press')
  final double? bedbPress;
  @JsonKey(name: 'rec_press')
  final double? recPress;
  
  final String? timestamp;
  final int id;

  const SensorData({
    this.airiTemp,
    this.airoTemp,
    this.boosterStatus,
    this.boostoTemp,
    this.compOnStatus,
    this.drypdpTemp,
    this.oxygen,
    this.airOutletp,
    this.boosterHour,
    this.compLoad,
    this.compRunningHour,
    this.oxyFlow,
    this.oxyPressure,
    this.pressure,
    this.trh,
    this.trhOnLoad,
    this.i1,
    this.i2,
    this.i3,
    this.contMode,
    this.mh1,
    this.mh2,
    this.mh3,
    this.mh4,
    this.mh5,
    this.volts,
    this.power,
    this.tableSource,
    this.oxyPurity,
    this.bedaPress,
    this.bedbPress,
    this.recPress,
    this.timestamp,
    required this.id,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) => _$SensorDataFromJson(json);
  Map<String, dynamic> toJson() => _$SensorDataToJson(this);

  DateTime get parsedTimestamp {
    try {
      if (timestamp == null || timestamp!.isEmpty) {
        return DateTime.now();
      }
      return DateTime.parse(timestamp!);
    } catch (e) {
      return DateTime.now();
    }
  }
}

@JsonSerializable()
class SensorDataResponse {
  final bool success;
  final String message;
  final List<SensorData> data;
  final int count;
  final SensorDataPagination pagination;
  final String? warning;

  const SensorDataResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.count,
    required this.pagination,
    this.warning,
  });

  factory SensorDataResponse.fromJson(Map<String, dynamic> json) => _$SensorDataResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SensorDataResponseToJson(this);
}

@JsonSerializable()
class SensorDataPagination {
  @JsonKey(name: 'total_records')
  final int totalRecords;
  
  @JsonKey(name: 'total_pages')
  final int totalPages;
  
  @JsonKey(name: 'current_page')
  final int currentPage;
  
  @JsonKey(name: 'records_per_page')
  final int recordsPerPage;
  
  @JsonKey(name: 'has_next')
  final bool hasNext;
  
  @JsonKey(name: 'has_previous')
  final bool hasPrevious;
  
  @JsonKey(name: 'next_page')
  final int? nextPage;
  
  @JsonKey(name: 'previous_page')
  final int? previousPage;
  
  @JsonKey(name: 'page_start_record')
  final int pageStartRecord;
  
  @JsonKey(name: 'page_end_record')
  final int pageEndRecord;

  const SensorDataPagination({
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.recordsPerPage,
    required this.hasNext,
    required this.hasPrevious,
    this.nextPage,
    this.previousPage,
    required this.pageStartRecord,
    required this.pageEndRecord,
  });

  factory SensorDataPagination.fromJson(Map<String, dynamic> json) => _$SensorDataPaginationFromJson(json);
  Map<String, dynamic> toJson() => _$SensorDataPaginationToJson(this);
}

// Enum to define all available sensor metrics
enum SensorMetric {
  // RIC metrics
  airiTemp('airi_temp', 'Air Inlet Temperature', '°C'),
  airoTemp('airo_temp', 'Air Outlet Temperature', '°C'),
  boosterStatus('booster_status', 'Booster Status', ''),
  boostoTemp('boosto_temp', 'Booster Temperature', '°C'),
  compOnStatus('comp_on_status', 'Status', ''),
  drypdpTemp('drypdp_temp', 'Dryer Temperature', '°C'),
  oxygen('oxygen', 'Oxygen Purity', '%'),
  airOutletp('air_outletp', 'Oxygen Flow', 'm³/hr'),
  boosterHour('booster_hour', 'Booster Hours', 'hrs'),
  compLoad('comp_load', 'Compressor Load', 'kW'),
  compRunningHour('comp_running_hour', 'Compressor Running Hours', 'hrs'),
  oxyFlow('oxy_flow', 'Oxygen Flow', 'm³/hr'),
  oxyPressure('oxy_pressure', 'Oxygen Pressure', 'Bar'),
  
  // SCC metrics
  pressure('pressure', 'Pressure', 'Bar'),
  trh('trh', 'Total Running Hours', 'hrs'),
  trhOnLoad('trh_on_load', 'Total Running Hours On Load', 'hrs'),
  i1('i1', 'Current', 'A'),
  i2('i2', 'Current I2', 'A'),
  i3('i3', 'Current I3', 'A'),
  contMode('cont_mode', 'Control Mode', ''),
  mh1('mh_1', 'Maintenance Hours', 'hrs'),
  mh2('mh_2', 'MH 2', ''),
  mh3('mh_3', 'MH 3', ''),
  mh4('mh_4', 'MH 4', ''),
  mh5('mh_5', 'Discharge Temperature', '°C'),
  volts('volts', 'Voltage', 'V'),
  power('power', 'Power', 'kW'),
  
  // Additional merged SCC metrics
  oxyPurity('oxy_purity', 'Oxygen Purity', '%'),
  bedaPress('beda_press', 'Bed A Pressure', 'PSI'),
  bedbPress('bedb_press', 'Bed B Pressure', 'PSI'),
  recPress('rec_press', 'Reciever Pressure', 'PSI'),
  

  // SCC-specific display names for Dryer and Booster sections
  pdpTemp('oxygen', 'PDP Temperature', '°C'),
  boosterTemp('drypdp_temp', 'Booster Temperature', '°C'),
  boosterRunningHours('booster_hour', 'Booster Running Hours', 'hrs'),
  boosterPressure('oxy_flow', 'Pressure', 'Bar');

  const SensorMetric(this.key, this.displayName, this.unit);

  final String key;
  final String displayName;
  final String unit;

  double getValue(SensorData data) {
    try {
      switch (this) {
        // RIC metrics
        case SensorMetric.airiTemp:
          return data.airiTemp ?? 0.0;
        case SensorMetric.airoTemp:
          return data.airoTemp ?? 0.0;
        case SensorMetric.boosterStatus:
          return (data.boosterStatus ?? 0).toDouble();
        case SensorMetric.boostoTemp:
          return data.boostoTemp ?? 0.0;
        case SensorMetric.compOnStatus:
          return (data.compOnStatus ?? 0).toDouble();
        case SensorMetric.drypdpTemp:
          return data.drypdpTemp ?? 0.0;
        case SensorMetric.oxygen:
          return data.oxygen ?? 0.0;
        case SensorMetric.airOutletp:
          return data.airOutletp ?? 0.0;
        case SensorMetric.boosterHour:
          return data.boosterHour ?? 0.0;
        case SensorMetric.compLoad:
          return data.compLoad ?? 0.0;
        case SensorMetric.compRunningHour:
          return data.compRunningHour ?? 0.0;
        case SensorMetric.oxyFlow:
          return data.oxyFlow ?? 0.0;
        case SensorMetric.oxyPressure:
          return data.oxyPressure ?? 0.0;
        
        // SCC metrics
        case SensorMetric.pressure:
          return data.pressure ?? 0.0;
        case SensorMetric.trh:
          return data.trh ?? 0.0;
        case SensorMetric.trhOnLoad:
          return data.trhOnLoad ?? 0.0;
        case SensorMetric.i1:
          return data.i1 ?? 0.0;
        case SensorMetric.i2:
          return data.i2 ?? 0.0;
        case SensorMetric.i3:
          return data.i3 ?? 0.0;
        case SensorMetric.contMode:
          return (data.contMode ?? 0).toDouble();
        case SensorMetric.mh1:
          return data.mh1 ?? 0.0;
        case SensorMetric.mh2:
          return data.mh2 ?? 0.0;
        case SensorMetric.mh3:
          return data.mh3 ?? 0.0;
        case SensorMetric.mh4:
          return data.mh4 ?? 0.0;
        case SensorMetric.mh5:
          return data.mh5 ?? 0.0;
        case SensorMetric.volts:
          return data.volts ?? 0.0;
        case SensorMetric.power:
          return data.power ?? 0.0;
        
        // Additional merged SCC metrics
        case SensorMetric.oxyPurity:
          return data.oxyPurity ?? 0.0;
        case SensorMetric.bedaPress:
          return data.bedaPress ?? 0.0;
        case SensorMetric.bedbPress:
          return data.bedbPress ?? 0.0;
        case SensorMetric.recPress:
          return data.recPress ?? 0.0;

        // SCC-specific display names for Dryer and Booster sections
        case SensorMetric.pdpTemp:
          return data.oxygen ?? 0.0;
        case SensorMetric.boosterTemp:
          return data.drypdpTemp ?? 0.0;
        case SensorMetric.boosterRunningHours:
          return data.boosterHour ?? 0.0;
        case SensorMetric.boosterPressure:
          return data.oxyFlow ?? 0.0;
      }
    } catch (e) {
      return 0.0;
    }
  }
}
