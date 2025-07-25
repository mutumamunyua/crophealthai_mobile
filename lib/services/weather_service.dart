// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final String _baseUrl = 'https://YOUR_DEPLOYED_BACKEND_URL'; // ← point to your Flask `/alerts` route

  Future<WeatherData?> fetchWeather(double lat, double lon) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/alerts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': lat, 'longitude': lon}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return WeatherData.fromJson(data);
    }
    return null;
  }

  Future<List<String>?> fetchAlerts(double lat, double lon) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/alerts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'latitude': lat, 'longitude': lon}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final List<dynamic> alerts = data['alerts'] as List<dynamic>;
      return alerts.map((a) => a.toString()).toList();
    }
    return null;
  }
}