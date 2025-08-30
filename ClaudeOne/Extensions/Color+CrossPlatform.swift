import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

extension Color {
    static var systemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    static var secondarySystemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemBackground)
        #else
        return Color(NSColor.controlBackgroundColor.blended(withFraction: 0.1, of: NSColor.controlAccentColor) ?? NSColor.controlBackgroundColor)
        #endif
    }
    
    static var systemGray6: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGray6)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}