//
//  Notification-Name+notifications.swift
//  Hear it!
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation

extension Notification.Name {
    static let shouldStopEveryEngineNotification: Notification.Name = .init("ShouldStopEveryEngineNotification")
    
    static let shouldStopAREngine: Notification.Name = .init("ShouldStopAREngine")
}
