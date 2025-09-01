import SwiftUI

struct WeatherOverlay: View {
    @ObservedObject var weatherManager: WeatherManager
    
    var body: some View {
        ZStack {
            // Weather effects overlay
            if weatherManager.currentWeather != .clear {
                weatherEffectsView
                    .allowsHitTesting(false)
            }
            
            // Weather info in top-right corner
            VStack {
                HStack {
                    Spacer()
                    
                    WeatherInfoCard(weatherManager: weatherManager)
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var weatherEffectsView: some View {
        switch weatherManager.currentWeather {
        case .rain:
            RainEffect(intensity: weatherManager.weatherIntensity)
        case .snow:
            SnowEffect(intensity: weatherManager.weatherIntensity)
        case .fog:
            FogEffect(intensity: weatherManager.weatherIntensity)
        case .clear:
            EmptyView()
        }
    }
}

struct WeatherInfoCard: View {
    @ObservedObject var weatherManager: WeatherManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: weatherManager.currentWeather.icon)
                    .foregroundColor(weatherManager.currentWeather.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(weatherManager.currentWeather.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(weatherManager.currentWeather.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            if weatherManager.timeUntilWeatherChange > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Changes in \(timeString(weatherManager.timeUntilWeatherChange))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .stroke(weatherManager.currentWeather.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func timeString(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct RainEffect: View {
    let intensity: Double
    @State private var raindrops: [Raindrop] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Darkened overlay
                Color.black.opacity(0.1 * intensity)
                
                // Raindrops
                ForEach(raindrops, id: \.id) { raindrop in
                    RaindropView(raindrop: raindrop)
                }
            }
            .onAppear {
                generateRaindrops(in: geometry.size)
            }
        }
    }
    
    private func generateRaindrops(in size: CGSize) {
        let count = Int(intensity * 50)
        raindrops = (0..<count).map { _ in
            Raindrop(
                x: Double.random(in: -50...Double(size.width + 50)),
                y: Double.random(in: -50...Double(size.height + 50)),
                speed: Double.random(in: 2...4),
                length: Double.random(in: 10...20)
            )
        }
    }
}

struct SnowEffect: View {
    let intensity: Double
    @State private var snowflakes: [Snowflake] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Whitened overlay
                Color.white.opacity(0.05 * intensity)
                
                // Snowflakes
                ForEach(snowflakes, id: \.id) { snowflake in
                    SnowflakeView(snowflake: snowflake)
                }
            }
            .onAppear {
                generateSnowflakes(in: geometry.size)
            }
        }
    }
    
    private func generateSnowflakes(in size: CGSize) {
        let count = Int(intensity * 30)
        snowflakes = (0..<count).map { _ in
            Snowflake(
                x: Double.random(in: -50...Double(size.width + 50)),
                y: Double.random(in: -50...Double(size.height + 50)),
                speed: Double.random(in: 0.5...1.5),
                size: Double.random(in: 3...8)
            )
        }
    }
}

struct FogEffect: View {
    let intensity: Double
    
    var body: some View {
        ZStack {
            // Gray overlay with reduced visibility
            Color.gray.opacity(0.2 * intensity)
                .blur(radius: 10 * intensity)
            
            // Additional fog layers
            ForEach(0..<3, id: \.self) { index in
                Color.white.opacity(0.05 * intensity)
                    .blur(radius: 5 * intensity)
                    .animation(
                        .easeInOut(duration: 3 + Double(index))
                        .repeatForever(autoreverses: true),
                        value: intensity
                    )
            }
        }
    }
}

// MARK: - Weather Particle Models

struct Raindrop: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let speed: Double
    let length: Double
}

struct Snowflake: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let speed: Double
    let size: Double
}

struct RaindropView: View {
    let raindrop: Raindrop
    @State private var yOffset: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: 1, height: raindrop.length)
            .position(x: raindrop.x, y: raindrop.y + yOffset)
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    yOffset = 800
                }
            }
    }
}

struct SnowflakeView: View {
    let snowflake: Snowflake
    @State private var yOffset: Double = 0
    @State private var xOffset: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.8))
            .frame(width: snowflake.size, height: snowflake.size)
            .position(
                x: snowflake.x + xOffset,
                y: snowflake.y + yOffset
            )
            .onAppear {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    yOffset = 800
                }
                
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    xOffset = Double.random(in: -20...20)
                }
            }
    }
}