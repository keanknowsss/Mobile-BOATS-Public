import 'package:boats_mobile_app/models/current_weather_data.dart';
import 'package:boats_mobile_app/models/daily_weather_data.dart';

class WeatherData {
  final CurrentWeatherData? current;
  final DailyWeatherData? daily;

  WeatherData([this.current, this.daily]);

  // fetch the values
  CurrentWeatherData getCurrentWeatherData() => current!;
  DailyWeatherData getDailyWeatherData() => daily!;
}
