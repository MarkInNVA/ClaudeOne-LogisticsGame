import SwiftUI
import Combine

enum WeatherCondition: String, CaseIterable {
    case clear = "clear"
    case rain = "rain"
    case snow = "snow"
    case fog = "fog"
    
    var title: String {
        switch self {
        case .clear: return "Clear"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .fog: return "Fog"
        }
    }
    
    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .fog: return "cloud.fog.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .clear: return .yellow
        case .rain: return .blue
        case .snow: return .cyan
        case .fog: return .gray
        }
    }
    
    var speedMultiplier: Double {
        switch self {
        case .clear: return 1.0
        case .rain: return 0.8
        case .snow: return 0.7
        case .fog: return 0.9
        }
    }
    
    var customerSatisfactionMultiplier: Double {
        switch self {
        case .clear: return 1.1  // 10% bonus
        case .rain: return 0.95  // 5% penalty
        case .snow: return 0.85  // 15% penalty
        case .fog: return 0.90   // 10% penalty
        }
    }
    
    var description: String {
        switch self {
        case .clear: return "Perfect delivery conditions"
        case .rain: return "Slower speeds, reduced satisfaction"
        case .snow: return "Significantly reduced performance"
        case .fog: return "Limited visibility affects deliveries"
        }
    }
}

class WeatherManager: ObservableObject {
    @Published var currentWeather: WeatherCondition = .clear
    @Published var weatherIntensity: Double = 0.0
    @Published var timeUntilWeatherChange: TimeInterval = 0
    
    private var weatherTimer: Timer?
    private var weatherChangeDuration: TimeInterval = 0
    
    init() {
        scheduleNextWeatherChange()
    }
    
    func startWeatherSystem() {
        scheduleNextWeatherChange()
    }
    
    func stopWeatherSystem() {
        weatherTimer?.invalidate()
        weatherTimer = nil
    }
    
    private func scheduleNextWeatherChange() {
        // Weather changes every 2-5 minutes
        let changeInterval = TimeInterval.random(in: 120...300)
        timeUntilWeatherChange = changeInterval
        
        weatherTimer?.invalidate()
        weatherTimer = Timer.scheduledTimer(withTimeInterval: changeInterval, repeats: false) { [weak self] _ in
            self?.changeWeather()
        }
        
        // Update countdown timer every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.timeUntilWeatherChange > 0 {
                self.timeUntilWeatherChange -= 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func changeWeather() {
        let previousWeather = currentWeather
        
        // 40% chance of clear weather, 20% each for others
        let weatherProbabilities: [(WeatherCondition, Double)] = [
            (.clear, 0.4),
            (.rain, 0.2),
            (.snow, 0.2),
            (.fog, 0.2)
        ]
        
        let random = Double.random(in: 0...1)
        var cumulativeProbability = 0.0
        
        for (weather, probability) in weatherProbabilities {
            cumulativeProbability += probability
            if random <= cumulativeProbability && weather != previousWeather {
                changeToWeather(weather)
                break
            }
        }
        
        // If we ended up with the same weather, force a different one
        if currentWeather == previousWeather {
            let availableWeathers = WeatherCondition.allCases.filter { $0 != previousWeather }
            if let newWeather = availableWeathers.randomElement() {
                changeToWeather(newWeather)
            }
        }
    }
    
    private func changeToWeather(_ newWeather: WeatherCondition) {
        withAnimation(.easeInOut(duration: 2.0)) {
            currentWeather = newWeather
            weatherIntensity = newWeather == .clear ? 0.0 : Double.random(in: 0.3...0.8)
        }
        
        // Weather lasts for 1-3 minutes
        weatherChangeDuration = TimeInterval.random(in: 60...180)
        
        // Schedule next weather change
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.scheduleNextWeatherChange()
        }
    }
    
    deinit {
        stopWeatherSystem()
    }
}