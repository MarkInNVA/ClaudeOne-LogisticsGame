import SwiftUI

struct LogisticsGameView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var eventBus: EventBus
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                switch gameState.status {
                case .menu:
                    MenuView()
                case .playing:
                    GameplayView()
                case .paused:
                    PausedView()
                case .gameOver:
                    GameOverView()
                }
            }
            .navigationTitle("Supply Chain Manager")
        }
    }
}

struct MenuView: View {
    @EnvironmentObject var eventBus: EventBus
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Supply Chain Manager")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Optimize your logistics network")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("Start Game") {
                eventBus.publish(LogisticsEvent.gameStarted)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct GameplayView: View {
    var body: some View {
        VStack(spacing: 0) {
            DashboardView()
                .frame(height: 120)
            
            Divider()
            
            HStack(spacing: 0) {
                VStack {
                    MapView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Divider()
                    
                    ControlsView()
                        .frame(height: 100)
                }
                
                Divider()
                
                VStack {
                    OrdersView()
                        .frame(maxHeight: .infinity)
                    
                    Divider()
                    
                    FleetView()
                        .frame(maxHeight: .infinity)
                }
                .frame(width: 300)
            }
        }
    }
}

struct PausedView: View {
    @EnvironmentObject var eventBus: EventBus
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Paused")
                .font(.largeTitle)
            
            Button("Resume") {
                eventBus.publish(LogisticsEvent.gameStarted)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct GameOverView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var eventBus: EventBus
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over")
                .font(.largeTitle)
            
            Text("Final Score: \(gameState.score)")
                .font(.title2)
            
            Text("Orders Completed: \(gameState.completedOrders.count)")
                .font(.headline)
            
            Button("Play Again") {
                eventBus.publish(LogisticsEvent.gameStarted)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}