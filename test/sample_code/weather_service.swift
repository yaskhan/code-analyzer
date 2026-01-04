// Core Data Manager
// Demonstrates Swift classes, structs, protocols, extensions, and error handling

import Foundation

// MARK: - Data Models

/// Weather condition enum
enum WeatherCondition: String, CaseIterable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case stormy = "stormy"
    
    var icon: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .snowy: return "❄️"
        case .stormy: return "⛈️"
        }
    }
    
    var description: String {
        switch self {
        case .sunny: return "Clear and sunny"
        case .cloudy: return "Partly cloudy"
        case .rainy: return "Rain expected"
        case .snowy: return "Snow expected"
        case .stormy: return "Thunderstorm possible"
        }
    }
}

/// Weather data structure
struct WeatherData: Codable, Identifiable {
    let id = UUID()
    let location: String
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Double
    let windSpeed: Double
    let timestamp: Date
    let feelsLike: Double
    
    init(location: String, temperature: Double, condition: WeatherCondition, humidity: Double, windSpeed: Double) {
        self.location = location
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.timestamp = Date()
        self.feelsLike = temperature - (windSpeed * 0.5) // Simple wind chill calculation
    }
}

/// Weather forecast data
struct WeatherForecast: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let high: Double
    let low: Double
    let condition: WeatherCondition
    let precipitation: Double
    
    init(date: Date, high: Double, low: Double, condition: WeatherCondition, precipitation: Double) {
        self.date = date
        self.high = high
        self.low = low
        self.condition = condition
        self.precipitation = precipitation
    }
}

// MARK: - Protocols

/// Protocol for data persistence
protocol DataPersistable {
    func save<T: Codable>(_ data: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T
}

/// Protocol for network operations
protocol NetworkServiceable {
    func fetchWeatherData(for location: String) async throws -> WeatherData
    func fetchForecast(for location: String) async throws -> [WeatherForecast]
}

/// Protocol for weather calculations
protocol WeatherCalculatable {
    func calculateHeatIndex(temperature: Double, humidity: Double) -> Double
    func calculateWindChill(temperature: Double, windSpeed: Double) -> Double
    func convertTemperature(_ value: Double, from unit: TemperatureUnit, to target: TemperatureUnit) -> Double
}

/// Temperature unit enumeration
enum TemperatureUnit: String, CaseIterable {
    case celsius = "C"
    case fahrenheit = "F"
    case kelvin = "K"
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        case .kelvin: return "K"
        }
    }
}

// MARK: - Service Classes

/// Local data persistence service
class LocalDataService: DataPersistable {
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func save<T: Codable>(_ data: T, forKey key: String) throws {
        do {
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: key)
        } catch {
            throw DataError.encodingFailed
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T {
        guard let data = userDefaults.data(forKey: key) else {
            throw DataError.noDataFound
        }
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw DataError.decodingFailed
        }
    }
}

/// Network service for weather API
class WeatherNetworkService: NetworkServiceable {
    private let baseURL = "https://api.weather.com/v1"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetchWeatherData(for location: String) async throws -> WeatherData {
        // Simulate API call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock data generation
        let conditions = WeatherCondition.allCases
        let randomCondition = conditions.randomElement() ?? .sunny
        
        return WeatherData(
            location: location,
            temperature: Double.random(in: -10...35),
            condition: randomCondition,
            humidity: Double.random(in: 30...90),
            windSpeed: Double.random(in: 0...25)
        )
    }
    
    func fetchForecast(for location: String) async throws -> [WeatherForecast] {
        // Simulate API call
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        var forecast: [WeatherForecast] = []
        let conditions = WeatherCondition.allCases
        let calendar = Calendar.current
        
        for i in 1...7 {
            let date = calendar.date(byAdding: .day, value: i, to: Date())!
            let condition = conditions.randomElement() ?? .sunny
            
            forecast.append(WeatherForecast(
                date: date,
                high: Double.random(in: 15...30),
                low: Double.random(in: 5...20),
                condition: condition,
                precipitation: Double.random(in: 0...10)
            ))
        }
        
        return forecast
    }
}

/// Weather calculation service
class WeatherCalculationService: WeatherCalculatable {
    
    func calculateHeatIndex(temperature: Double, humidity: Double) -> Double {
        // Simplified heat index calculation
        let t = temperature * 9/5 + 32 // Convert to Fahrenheit
        let h = humidity
        
        if t < 80 {
            return temperature
        }
        
        let hi = -42.379 + (2.04901523 * t) + (10.14333127 * h) -
                (0.22475541 * t * h) - (0.00683783 * t * t) -
                (0.05481717 * h * h) + (0.00122874 * t * t * h) +
                (0.00085282 * t * h * h) - (0.00000199 * t * t * h * h)
        
        return (hi - 32) * 5/9 // Convert back to Celsius
    }
    
    func calculateWindChill(temperature: Double, windSpeed: Double) -> Double {
        // Wind chill calculation for Celsius
        if temperature > 10 || windSpeed < 4.8 {
            return temperature
        }
        
        let t = temperature
        let v = windSpeed * 3.6 // Convert m/s to km/h
        
        let wc = 13.12 + (0.6215 * t) - (11.37 * pow(v, 0.16)) +
                (0.3965 * t * pow(v, 0.16))
        
        return wc
    }
    
    func convertTemperature(_ value: Double, from unit: TemperatureUnit, to target: TemperatureUnit) -> Double {
        if unit == target {
            return value
        }
        
        // Convert to Celsius first
        var celsius: Double
        switch unit {
        case .celsius:
            celsius = value
        case .fahrenheit:
            celsius = (value - 32) * 5/9
        case .kelvin:
            celsius = value - 273.15
        }
        
        // Convert from Celsius to target unit
        switch target {
        case .celsius:
            return celsius
        case .fahrenheit:
            return celsius * 9/5 + 32
        case .kelvin:
            return celsius + 273.15
        }
    }
}

// MARK: - Data Errors

/// Custom error types for data operations
enum DataError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case noDataFound
    case invalidURL
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .noDataFound:
            return "No data found for the specified key"
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network operation failed"
        }
    }
}

/// Weather service manager that combines multiple services
class WeatherServiceManager {
    private let networkService: NetworkServiceable
    private let dataService: DataPersistable
    private let calculationService: WeatherCalculatable
    
    init(networkService: NetworkServiceable = WeatherNetworkService(),
         dataService: DataPersistable = LocalDataService(),
         calculationService: WeatherCalculatable = WeatherCalculationService()) {
        self.networkService = networkService
        self.dataService = dataService
        self.calculationService = calculationService
    }
    
    /// Fetches current weather with caching
    /// - Parameters:
    ///   - location: Location name
    ///   - useCache: Whether to use cached data if available
    /// - Returns: Weather data
    func getCurrentWeather(for location: String, useCache: Bool = true) async throws -> WeatherData {
        let cacheKey = "current_weather_\(location.lowercased())"
        
        // Try to load from cache first
        if useCache {
            do {
                let cachedData: WeatherData = try dataService.load(WeatherData.self, forKey: cacheKey)
                
                // Check if cache is still valid (less than 30 minutes old)
                let timeInterval = Date().timeIntervalSince(cachedData.timestamp)
                if timeInterval < 1800 { // 30 minutes
                    return cachedData
                }
            } catch {
                // Cache miss or invalid, continue with network request
            }
        }
        
        // Fetch from network
        let weatherData = try await networkService.fetchWeatherData(for: location)
        
        // Save to cache
        do {
            try dataService.save(weatherData, forKey: cacheKey)
        } catch {
            // Log warning but don't fail the operation
            print("Warning: Failed to cache weather data: \(error)")
        }
        
        return weatherData
    }
    
    /// Gets weather forecast
    /// - Parameter location: Location name
    /// - Returns: Array of weather forecasts
    func getForecast(for location: String) async throws -> [WeatherForecast] {
        return try await networkService.fetchForecast(for: location)
    }
    
    /// Calculates apparent temperature (feels like)
    /// - Parameters:
    ///   - temperature: Actual temperature
    ///   - humidity: Humidity percentage
    ///   - windSpeed: Wind speed in m/s
    /// - Returns: Apparent temperature
    func calculateApparentTemperature(temperature: Double, humidity: Double, windSpeed: Double) -> Double {
        let heatIndex = calculationService.calculateHeatIndex(temperature: temperature, humidity: humidity)
        let windChill = calculationService.calculateWindChill(temperature: temperature, windSpeed: windSpeed)
        
        // Return the more appropriate value based on conditions
        if temperature > 25 {
            return heatIndex
        } else if temperature < 10 {
            return windChill
        } else {
            return temperature
        }
    }
}

// MARK: - Utility Extensions

/// Extension for WeatherData to add computed properties
extension WeatherData {
    var isComfortable: Bool {
        return temperature >= 18 && temperature <= 26 && humidity >= 40 && humidity <= 60
    }
    
    var weatherIcon: String {
        return condition.icon
    }
    
    var description: String {
        return condition.description
    }
    
    /// Converts temperature to specified unit
    func temperatureInUnit(_ unit: TemperatureUnit) -> Double {
        return WeatherCalculationService().convertTemperature(temperature, from: .celsius, to: unit)
    }
}

/// Extension for Date to add useful formatting
extension Date {
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: self)
    }
}

/// Extension for Array where Element is WeatherForecast
extension Array where Element == WeatherForecast {
    var averageHigh: Double {
        guard !isEmpty else { return 0 }
        return reduce(0) { $0 + $1.high } / Double(count)
    }
    
    var averageLow: Double {
        guard !isEmpty else { return 0 }
        return reduce(0) { $0 + $1.low } / Double(count)
    }
    
    var totalPrecipitation: Double {
        return reduce(0) { $0 + $1.precipitation }
    }
}

// MARK: - View Model

/// Weather view model for SwiftUI
class WeatherViewModel: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var forecast: [WeatherForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let weatherService: WeatherServiceManager
    
    init(weatherService: WeatherServiceManager = WeatherServiceManager()) {
        self.weatherService = weatherService
    }
    
    /// Loads weather data for a location
    /// - Parameter location: Location name
    func loadWeather(for location: String) {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            
            do {
                let weather = try await weatherService.getCurrentWeather(for: location)
                let forecast = try await weatherService.getForecast(for: location)
                
                await MainActor.run {
                    self.currentWeather = weather
                    self.forecast = forecast
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Refreshes weather data
    func refreshWeather() {
        guard let location = currentWeather?.location else { return }
        loadWeather(for: location)
    }
}

// MARK: - Example Usage

/// Example function demonstrating the weather system
func demonstrateWeatherSystem() {
    let weatherService = WeatherServiceManager()
    let viewModel = WeatherViewModel(weatherService: weatherService)
    
    Task {
        do {
            // Fetch weather for London
            let weather = try await weatherService.getCurrentWeather(for: "London")
            print("Current weather for \(weather.location):")
            print("  Temperature: \(String(format: "%.1f", weather.temperature))°C")
            print("  Condition: \(weather.description)")
            print("  Humidity: \(Int(weather.humidity))%")
            print("  Wind Speed: \(String(format: "%.1f", weather.windSpeed)) m/s")
            print("  Feels like: \(String(format: "%.1f", weatherService.calculateApparentTemperature(
                temperature: weather.temperature,
                humidity: weather.humidity,
                windSpeed: weather.windSpeed
            )))°C")
            
            // Get forecast
            let forecast = try await weatherService.getForecast(for: "London")
            print("\nForecast summary:")
            print("  Average high: \(String(format: "%.1f", forecast.averageHigh))°C")
            print("  Average low: \(String(format: "%.1f", forecast.averageLow))°C")
            print("  Total precipitation: \(String(format: "%.1f", forecast.totalPrecipitation))mm")
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

// Demo execution
demonstrateWeatherSystem()