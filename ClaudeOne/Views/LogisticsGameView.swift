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
                case .tutorial:
                    TutorialGameplayView()
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
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Supply Chain Manager")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Optimize your logistics network")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if gameState.levelSystem != nil {
                LevelProgressIndicator(playerLevel: gameState.levelSystem.currentLevel)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 15) {
                Button("Start Game") {
                    eventBus.publish(LogisticsEvent.gameStarted)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                if UserDefaults.standard.bool(forKey: "tutorial_completed") {
                    Button("Restart Tutorial") {
                        gameState.tutorialSystem?.resetTutorial()
                        eventBus.publish(LogisticsEvent.gameStarted)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
}

struct TutorialGameplayView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
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
            
            if let tutorialSystem = gameState.tutorialSystem {
                TutorialOverlay(tutorialSystem: tutorialSystem)
            }
        }
    }
}

struct GameplayView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
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
            
            // Achievement overlay
            AchievementOverlay(achievementManager: gameEngine.achievements)
            
            // Level up notification overlay
            if let levelSystem = gameState.levelSystem,
               let levelUpNotification = levelSystem.showLevelUpNotification {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                LevelUpNotification(levelRequirements: levelUpNotification) {
                    levelSystem.showLevelUpNotification = nil
                }
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