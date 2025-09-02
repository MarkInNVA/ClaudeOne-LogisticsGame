# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeOne is a SwiftUI logistics simulation game that runs on iOS, macOS, and visionOS. The app is a cross-platform game where players manage a logistics network by coordinating warehouses, vehicles, and orders to maximize efficiency and profits.

## Development Commands

### Building and Running
- Build: `xcodebuild -project ClaudeOne.xcodeproj -scheme ClaudeOne build`
- Run in Xcode: Open `ClaudeOne.xcodeproj` and run on desired simulator/device
- The project supports iOS 17.0+, macOS 14.0+, and visionOS 26.0+

### Project Configuration
- Bundle ID: `com.focus.futher.ClaudeOne`
- Swift Version: 5.0
- Deployment Targets: iOS 17.0, macOS 14.0, visionOS 26.0
- Supported Platforms: iPhone, iPad, Mac, Apple Vision Pro

## Architecture

### Event-Driven Architecture
The game uses a centralized event bus (`EventBus`) with the publisher/subscriber pattern for decoupled communication:
- **EventBus**: Core event system using Combine's `PassthroughSubject`
- **GameEvent**: Protocol for all events; `LogisticsEvent` enum implements game-specific events
- All managers subscribe to relevant events and publish state changes

### Core Components

1. **GameEngine** (`ClaudeOne/Game/GameEngine.swift`): Main game loop orchestrator
   - Manages game lifecycle (start/pause/end)
   - Coordinates all subsystem managers
   - Handles auto-assignment logic for orders
   - Updates performance metrics and budget

2. **GameState** (`ClaudeOne/Game/GameState.swift`): Central state management
   - Published properties for reactive UI updates
   - Manages warehouses, vehicles, orders, budget, and score
   - Handles event-based state transitions

3. **Manager Systems** (in `ClaudeOne/Systems/`):
   - **OrderManager**: Order lifecycle and fulfillment tracking
   - **VehicleManager**: Fleet management and dispatch logic
   - **WarehouseManager**: Inventory and warehouse operations
   - **WeatherManager**: Weather simulation affecting operations
   - **AchievementManager**: Player achievement tracking
   - **FeedbackManager**: User feedback and notifications

4. **Models** (in `ClaudeOne/Models/`):
   - **Vehicle**: Fleet vehicles with different types (truck, van, drone)
   - **Warehouse**: Storage facilities with inventory management
   - **Order**: Customer orders with destinations and requirements
   - **Route**: Delivery routes connecting locations and orders
   - **Product**: Items that can be stored and delivered
   - **Location**: 2D coordinate system for positioning
   - **PerformanceMetrics**: KPI tracking for game scoring

### UI Architecture

- **ContentView**: App entry point, sets up dependency injection
- **LogisticsGameView**: Main game interface
- Views organized by function: `MapView`, `DashboardView`, `FleetView`, `OrdersView`, `ControlsView`
- Overlay views for feedback, weather, and achievements
- Uses SwiftUI's `@EnvironmentObject` for dependency injection

### Key Patterns

1. **Dependency Injection**: Core objects (EventBus, GameState, GameEngine) injected via SwiftUI environment
2. **Observer Pattern**: Extensive use of `@Published` properties and Combine for reactive updates  
3. **Command Pattern**: Events represent commands that trigger state changes across the system
4. **Manager Pattern**: Separate managers handle distinct game subsystems
5. **Cross-Platform**: Uses `Color+CrossPlatform` extension for platform-specific styling

## Development Guidelines

- Events should be published through `EventBus` rather than direct method calls between managers
- UI state updates happen automatically through `@Published` properties
- New managers should subscribe to relevant events in their initializers
- Game logic updates occur in the main game loop via `GameEngine`
- Use the existing `Location` coordinate system for positioning (0.0 to 1.0 range)