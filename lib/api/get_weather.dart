import 'dart:convert';

import 'package:boats_mobile_app/constants/api_url.dart';
import 'package:boats_mobile_app/models/current_weather_data.dart';
import 'package:boats_mobile_app/models/daily_weather_data.dart';
import 'package:boats_mobile_app/models/weather_data.dart';
import 'package:http/http.dart' as http;

class GetWeatherApi {
  WeatherData? weatherData;

  // processing the data from response to JSON
  Future<WeatherData> processData(latitude, longitude) async {
    var response =
        await http.get(Uri.parse(weatherApiUrl(latitude, longitude)));
    var jsonString = jsonDecode(response.body);
    weatherData = WeatherData(
      CurrentWeatherData.fromJson(jsonString),
      DailyWeatherData.fromJson(jsonString),
    );
    return weatherData!;
  }
}
