//
//  Extensions.swift
//  fitVital
//
//  Created by Nick Conoplia on 30/5/2025.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Format date for display
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    /// Format time for display
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is in current week
    var isThisWeek: Bool {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        return self >= startOfWeek && self <= endOfWeek
    }
}

// MARK: - View Extensions

extension View {
    /// Apply focus modifier for text fields
    func focused() -> some View {
        self
    }
}

// MARK: - Font Extensions

extension Font {
    /// Button large font
    static var buttonLarge: Font {
        return .system(size: 18, weight: .semibold)
    }
    
    /// Numeric large font for stats
    static var numericLarge: Font {
        return .system(size: 20, weight: .bold, design: .rounded)
    }
} 