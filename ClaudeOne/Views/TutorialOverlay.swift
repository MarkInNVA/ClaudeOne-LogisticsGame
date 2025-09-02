import SwiftUI

struct TutorialOverlay: View {
    @ObservedObject var tutorialSystem: TutorialSystem
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        ZStack {
            if tutorialSystem.showTutorialOverlay {
                
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if tutorialSystem.currentStep.canAutoAdvance {
                            tutorialSystem.nextStep()
                        }
                    }
                
                VStack(spacing: 0) {
                    
                    if let highlightArea = tutorialSystem.currentStep.highlightArea {
                        HighlightRegion(area: highlightArea)
                    }
                    
                    Spacer()
                    
                    TutorialPopup(
                        step: tutorialSystem.currentStep,
                        onNext: {
                            tutorialSystem.nextStep()
                        },
                        onSkip: {
                            tutorialSystem.skipTutorial()
                        }
                    )
                    .padding(.bottom, 50)
                    .padding(.horizontal, 20)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: tutorialSystem.showTutorialOverlay)
    }
}

struct HighlightRegion: View {
    let area: TutorialHighlight
    
    var body: some View {
        GeometryReader { geometry in
            let highlightRect = getHighlightRect(for: area, in: geometry)
            
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: highlightRect.width, height: highlightRect.height)
                        .position(x: highlightRect.midX, y: highlightRect.midY)
                        .shadow(color: .blue, radius: 10)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
                )
        }
    }
    
    private func getHighlightRect(for area: TutorialHighlight, in geometry: GeometryProxy) -> CGRect {
        switch area {
        case .dashboard:
            return CGRect(x: 10, y: 10, width: geometry.size.width - 20, height: 120)
        case .map:
            return CGRect(x: 10, y: 140, width: geometry.size.width * 0.7 - 20, height: geometry.size.height - 250)
        case .ordersPanel:
            return CGRect(x: geometry.size.width * 0.7, y: 140, width: geometry.size.width * 0.3, height: (geometry.size.height - 250) * 0.5)
        case .fleetPanel:
            return CGRect(x: geometry.size.width * 0.7, y: 140 + (geometry.size.height - 250) * 0.5, width: geometry.size.width * 0.3, height: (geometry.size.height - 250) * 0.5)
        case .controls:
            return CGRect(x: 10, y: geometry.size.height - 100, width: geometry.size.width * 0.7 - 20, height: 90)
        }
    }
}

struct TutorialPopup: View {
    let step: TutorialStep
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    Text(step.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(step.rawValue + 1)/\(TutorialStep.allCases.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(step.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .shadow(radius: 10)
            )
            
            HStack(spacing: 15) {
                if step != .completed {
                    Button("Skip Tutorial") {
                        onSkip()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if step.canAutoAdvance || step == .completed {
                    Button(step == .completed ? "Start Playing!" : "Continue") {
                        onNext()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text(getWaitingMessage())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thickMaterial)
                .shadow(radius: 20)
        )
    }
    
    private func getWaitingMessage() -> String {
        switch step {
        case .assignVehicle:
            return "Complete the action to continue..."
        case .watchDelivery:
            return "Wait for delivery to complete..."
        case .checkPerformance:
            return "Performance metrics updating..."
        default:
            return ""
        }
    }
}

struct LevelUpNotification: View {
    let levelRequirements: LevelRequirements
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title)
                
                Text("LEVEL UP!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title)
            }
            
            Text("Level \(levelRequirements.level)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(levelRequirements.title)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(levelRequirements.description)
                .font(.body)
                .multilineTextAlignment(.center)
            
            if !levelRequirements.unlocks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Unlocks:")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    ForEach(Array(levelRequirements.unlocks.enumerated()), id: \.offset) { _, unlock in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(unlock.displayName)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.green.opacity(0.1))
                )
            }
            
            Button("Continue") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 20)
        )
        .scaleEffect(1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
    }
}

struct LevelProgressIndicator: View {
    let playerLevel: PlayerLevel
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Level \(playerLevel.level)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if !playerLevel.isMaxLevel {
                        Text("\(playerLevel.experienceToNext) XP to next")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !playerLevel.isMaxLevel {
                    ProgressView(value: playerLevel.progressToNext)
                        .progressViewStyle(.linear)
                        .scaleEffect(y: 0.8)
                }
            }
        }
    }
}

#Preview {
    TutorialOverlay(tutorialSystem: TutorialSystem(eventBus: EventBus(), gameState: GameState(eventBus: EventBus())))
        .environmentObject(GameState(eventBus: EventBus()))
}