// Weather Data Model and Service
// Demonstrates Dart classes, mixins, and async methods

/// Weather condition enum
enum WeatherCondition {
  sunny,
  cloudy,
  rainy,
  snowy,
  stormy
}

/// Base weather data model
class WeatherData {
  final String location;
  final double temperature;
  final WeatherCondition condition;
  final DateTime timestamp;
  
  const WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    required this.timestamp,
  });
  
  /// Creates weather data from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      condition: WeatherCondition.values[json['condition'] as int],
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  /// Converts to JSON format
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'condition': condition.index,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// Gets temperature in Fahrenheit
  double get temperatureFahrenheit => temperature * 9/5 + 32;
}

/// Extended weather data with additional metrics
class ExtendedWeatherData extends WeatherData {
  final double humidity;
  final double windSpeed;
  final int pressure;
  
  const ExtendedWeatherData({
    required String location,
    required double temperature,
    required WeatherCondition condition,
    required DateTime timestamp,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
  }) : super(
          location: location,
          temperature: temperature,
          condition: condition,
          timestamp: timestamp,
        );
}

/// Weather service with API integration
class WeatherService {
  static const String _baseUrl = 'https://api.weather.com/v1';
  final Duration timeout;
  
  WeatherService({this.timeout = const Duration(seconds: 10)});
  
  /// Fetches current weather for a location
  /// @param location City or location name
  /// @returns Future containing weather data
  Future<WeatherData> getCurrentWeather(String location) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));
    
    return WeatherData(
      location: location,
      temperature: 20.0 + (location.hashCode % 15), // Simulate varying temperatures
      condition: WeatherCondition.values[location.hashCode % WeatherCondition.values.length],
      timestamp: DateTime.now(),
    );
  }
  
  /// Fetches extended weather forecast
  /// @param location Location to get forecast for
  /// @returns Future containing extended weather data
  Future<List<ExtendedWeatherData>> getForecast(String location) async {
    await Future.delayed(Duration(milliseconds: 800));
    
    final List<ExtendedWeatherData> forecast = [];
    final baseTemp = 20.0 + (location.hashCode % 15);
    
    for (int i = 0; i < 5; i++) {
      forecast.add(ExtendedWeatherData(
        location: location,
        temperature: baseTemp + (i * 2 - 4), // Varying temperatures
        condition: WeatherCondition.values[(location.hashCode + i) % WeatherCondition.values.length],
        timestamp: DateTime.now().add(Duration(days: i)),
        humidity: 60.0 + (i * 5), // 60-80% humidity
        windSpeed: 10.0 + (i * 3), // 10-22 m/s wind
        pressure: 1013 + (i * 2 - 4), // Varying pressure
      ));
    }
    
    return forecast;
  }
  
  /// Validates location string
  /// @param location Location to validate
  /// @returns true if location is valid
  bool validateLocation(String location) {
    return location.trim().isNotEmpty && location.length >= 2;
  }
}

/// Weather data repository for local storage
class WeatherRepository {
  static WeatherRepository? _instance;
  static WeatherRepository get instance => _instance ??= WeatherRepository._();
  
  WeatherRepository._();
  
  final Map<String, List<WeatherData>> _cache = {};
  
  /// Stores weather data in cache
  /// @param location Location key
  /// @param data Weather data to store
  void cacheWeatherData(String location, WeatherData data) {
    final list = _cache[location] ??= [];
    list.add(data);
    
    // Keep only last 10 entries per location
    if (list.length > 10) {
      list.removeAt(0);
    }
  }
  
  /// Retrieves cached weather data
  /// @param location Location to get cached data for
  /// @returns List of cached weather data, empty if none found
  List<WeatherData> getCachedData(String location) {
    return _cache[location] ?? [];
  }
  
  /// Clears cache for specific location
  /// @param location Location to clear cache for
  void clearCache(String location) {
    _cache.remove(location);
  }
}

/// Weather calculation utility methods
class WeatherUtils {
  WeatherUtils._();
  
  /// Converts temperature between units
  /// @param value Temperature value
  /// @param from Source unit ('C' for Celsius, 'F' for Fahrenheit)
  /// @param to Target unit
  /// @returns Converted temperature
  static double convertTemperature(double value, String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return value;
    
    if (from.toUpperCase() == 'C' && to.toUpperCase() == 'F') {
      return value * 9/5 + 32;
    } else if (from.toUpperCase() == 'F' && to.toUpperCase() == 'C') {
      return (value - 32) * 5/9;
    }
    
    throw ArgumentError('Unsupported temperature unit: $to');
  }
  
  /// Gets weather condition description
  /// @param condition Weather condition enum
  /// @returns Human readable description
  static String getConditionDescription(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Clear and sunny';
      case WeatherCondition.cloudy:
        return 'Partly cloudy';
      case WeatherCondition.rainy:
        return 'Rain expected';
      case WeatherCondition.snowy:
        return 'Snow expected';
      case WeatherCondition.stormy:
        return 'Thunderstorm possible';
    }
  }
}