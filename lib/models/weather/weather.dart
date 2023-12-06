import 'current.dart';
import 'daily.dart';

class Weather {
  double? lat;
  double? lon;
  String? timezone;
  int? timezoneOffset;
  Current? current;
  List<Daily>? daily;

  Weather({
    this.lat,
    this.lon,
    this.timezone,
    this.timezoneOffset,
    this.current,
    this.daily,
  });

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        lat: (json['lat'] as num?)?.toDouble(),
        lon: (json['lon'] as num?)?.toDouble(),
        timezone: json['timezone'] as String?,
        timezoneOffset: json['timezone_offset'] as int?,
        current: json['current'] == null
            ? null
            : Current.fromJson(json['current'] as Map<String, dynamic>),
        daily: (json['daily'] as List<dynamic>?)
            ?.map((e) => Daily.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'timezone': timezone,
        'timezone_offset': timezoneOffset,
        'current': current?.toJson(),
        'daily': daily?.map((e) => e.toJson()).toList(),
      };
}
