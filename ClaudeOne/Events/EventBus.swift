import Foundation
import Combine

class EventBus: ObservableObject {
    private let eventSubject = PassthroughSubject<GameEvent, Never>()
    
    var eventPublisher: AnyPublisher<GameEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    func publish(_ event: GameEvent) {
        eventSubject.send(event)
    }
    
    func subscribe<T: GameEvent>(to eventType: T.Type, handler: @escaping (T) -> Void) -> AnyCancellable {
        eventPublisher
            .compactMap { $0 as? T }
            .sink(receiveValue: handler)
    }
}