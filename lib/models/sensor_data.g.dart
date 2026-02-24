// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SensorData _$SensorDataFromJson(Map<String, dynamic> json) => SensorData(
  airiTemp: (json['airi_temp'] as num?)?.toDouble(),
  airoTemp: (json['airo_temp'] as num?)?.toDouble(),
  boosterStatus: (json['booster_status'] as num?)?.toInt(),
  boostoTemp: (json['boosto_temp'] as num?)?.toDouble(),
  compOnStatus: (json['comp_on_status'] as num?)?.toInt(),
  drypdpTemp: (json['drypdp_temp'] as num?)?.toDouble(),
  oxygen: (json['oxygen'] as num?)?.toDouble(),
  airOutletp: (json['air_outletp'] as num?)?.toDouble(),
  boosterHour: (json['booster_hour'] as num?)?.toDouble(),
  compLoad: (json['comp_load'] as num?)?.toDouble(),
  compRunningHour: (json['comp_running_hour'] as num?)?.toDouble(),
  oxyFlow: (json['oxy_flow'] as num?)?.toDouble(),
  oxyPressure: (json['oxy_pressure'] as num?)?.toDouble(),
  pressure: (json['pressure'] as num?)?.toDouble(),
  trh: (json['trh'] as num?)?.toDouble(),
  trhOnLoad: (json['trh_on_load'] as num?)?.toDouble(),
  i1: (json['i1'] as num?)?.toDouble(),
  i2: (json['i2'] as num?)?.toDouble(),
  i3: (json['i3'] as num?)?.toDouble(),
  contMode: (json['cont_mode'] as num?)?.toInt(),
  mh1: (json['mh_1'] as num?)?.toDouble(),
  mh2: (json['mh_2'] as num?)?.toDouble(),
  mh3: (json['mh_3'] as num?)?.toDouble(),
  mh4: (json['mh_4'] as num?)?.toDouble(),
  mh5: (json['mh_5'] as num?)?.toDouble(),
  volts: (json['volts'] as num?)?.toDouble(),
  power: (json['power'] as num?)?.toDouble(),
  tableSource: json['table_source'] as String?,
  oxyPurity: (json['oxy_purity'] as num?)?.toDouble(),
  bedaPress: (json['beda_press'] as num?)?.toDouble(),
  bedbPress: (json['bedb_press'] as num?)?.toDouble(),
  recPress: (json['rec_press'] as num?)?.toDouble(),
  ga1: (json['ga_1'] as num?)?.toDouble(),
  ga2: (json['ga_2'] as num?)?.toDouble(),
  ga3: (json['ga_3'] as num?)?.toDouble(),
  ga4: (json['ga_4'] as num?)?.toDouble(),
  timestamp: json['timestamp'] as String?,
  id: (json['id'] as num).toInt(),
);

Map<String, dynamic> _$SensorDataToJson(SensorData instance) =>
    <String, dynamic>{
      'airi_temp': instance.airiTemp,
      'airo_temp': instance.airoTemp,
      'booster_status': instance.boosterStatus,
      'boosto_temp': instance.boostoTemp,
      'comp_on_status': instance.compOnStatus,
      'drypdp_temp': instance.drypdpTemp,
      'oxygen': instance.oxygen,
      'air_outletp': instance.airOutletp,
      'booster_hour': instance.boosterHour,
      'comp_load': instance.compLoad,
      'comp_running_hour': instance.compRunningHour,
      'oxy_flow': instance.oxyFlow,
      'oxy_pressure': instance.oxyPressure,
      'pressure': instance.pressure,
      'trh': instance.trh,
      'trh_on_load': instance.trhOnLoad,
      'i1': instance.i1,
      'i2': instance.i2,
      'i3': instance.i3,
      'cont_mode': instance.contMode,
      'mh_1': instance.mh1,
      'mh_2': instance.mh2,
      'mh_3': instance.mh3,
      'mh_4': instance.mh4,
      'mh_5': instance.mh5,
      'volts': instance.volts,
      'power': instance.power,
      'table_source': instance.tableSource,
      'oxy_purity': instance.oxyPurity,
      'beda_press': instance.bedaPress,
      'bedb_press': instance.bedbPress,
      'rec_press': instance.recPress,
      'ga_1': instance.ga1,
      'ga_2': instance.ga2,
      'ga_3': instance.ga3,
      'ga_4': instance.ga4,
      'timestamp': instance.timestamp,
      'id': instance.id,
    };

SensorDataResponse _$SensorDataResponseFromJson(Map<String, dynamic> json) =>
    SensorDataResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => SensorData.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
      pagination: SensorDataPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
      warning: json['warning'] as String?,
    );

Map<String, dynamic> _$SensorDataResponseToJson(SensorDataResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'count': instance.count,
      'pagination': instance.pagination,
      'warning': instance.warning,
    };

SensorDataPagination _$SensorDataPaginationFromJson(
  Map<String, dynamic> json,
) => SensorDataPagination(
  totalRecords: (json['total_records'] as num).toInt(),
  totalPages: (json['total_pages'] as num).toInt(),
  currentPage: (json['current_page'] as num).toInt(),
  recordsPerPage: (json['records_per_page'] as num).toInt(),
  hasNext: json['has_next'] as bool,
  hasPrevious: json['has_previous'] as bool,
  nextPage: (json['next_page'] as num?)?.toInt(),
  previousPage: (json['previous_page'] as num?)?.toInt(),
  pageStartRecord: (json['page_start_record'] as num).toInt(),
  pageEndRecord: (json['page_end_record'] as num).toInt(),
);

Map<String, dynamic> _$SensorDataPaginationToJson(
  SensorDataPagination instance,
) => <String, dynamic>{
  'total_records': instance.totalRecords,
  'total_pages': instance.totalPages,
  'current_page': instance.currentPage,
  'records_per_page': instance.recordsPerPage,
  'has_next': instance.hasNext,
  'has_previous': instance.hasPrevious,
  'next_page': instance.nextPage,
  'previous_page': instance.previousPage,
  'page_start_record': instance.pageStartRecord,
  'page_end_record': instance.pageEndRecord,
};
