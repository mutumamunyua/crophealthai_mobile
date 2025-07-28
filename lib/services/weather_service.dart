// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Holds the basic weather metrics
class WeatherData {
  final double temperature;
  final double windspeed;
  final int rain;
  final int humidity;

  WeatherData({
    required this.temperature,
    required this.windspeed,
    required this.rain,
    required this.humidity,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['tmax'] as num).toDouble(),
      windspeed: (json['wind'] as num).toDouble(),
      rain: (json['rain'] as num).toInt(),
      humidity: (json['rh_max'] as num).toInt(),
    );
  }
}

class WeatherService {
  /// Fetch tomorrow’s weather summary
  Future<WeatherData?> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse('$backendBaseURL/alerts');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'latitude': lat, 'longitude': lon}),
    );
    if (resp.statusCode != 200) return null;
    final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
    return WeatherData.fromJson(jsonBody);
  }

  /// Fetch actionable alerts (or empty list)
  Future<List<String>?> fetchAlerts(double lat, double lon) async {
    final uri = Uri.parse('$backendBaseURL/alerts');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'latitude': lat, 'longitude': lon}),
    );
    if (resp.statusCode != 200) return null;
    final jsonBody = json.decode(resp.body) as Map<String, dynamic>;
    return List<String>.from(jsonBody['alerts'] ?? []);
  }
}