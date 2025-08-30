//
//  ContentView.swift
//  ClaudeOne
//
//  Created by Mark Reidy on 8/30/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var eventBus = EventBus()
    @StateObject private var gameState: GameState
    @StateObject private var gameEngine: GameEngine
    
    init() {
        let eventBus = EventBus()
        let gameState = GameState(eventBus: eventBus)
        let gameEngine = GameEngine(eventBus: eventBus, gameState: gameState)
        
        self._eventBus = StateObject(wrappedValue: eventBus)
        self._gameState = StateObject(wrappedValue: gameState)
        self._gameEngine = StateObject(wrappedValue: gameEngine)
    }
    
    var body: some View {
        LogisticsGameView()
            .environmentObject(eventBus)
            .environmentObject(gameState)
            .environmentObject(gameEngine)
    }
}

#Preview {
    ContentView()
}
