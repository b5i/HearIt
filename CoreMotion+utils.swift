//
//  CoreMotion+utils.swift
//  WWDC24
//
//  Created by Antoine Bollengier on 24.02.2024.
//

import Foundation
import CoreMotion
import SceneKit

extension simd_float4x4 {
    init(position: simd_float3) {
        self = matrix_identity_float4x4
        self.columns.3 = simd_float4(position, 1)
    }
}

extension CMRotationMatrix {
    func toSIMDMatrix() -> simd_float4x4 {
        var returnMatrix = matrix_identity_float4x4
        returnMatrix.columns.0 = .init(Float(self.m11), Float(self.m12), Float(self.m13), 0)
        returnMatrix.columns.1 = .init(Float(self.m21), Float(self.m22), Float(self.m23), 0)
        returnMatrix.columns.2 = .init(Float(self.m31), Float(self.m32), Float(self.m33), 0)
        return returnMatrix
    }
}

extension CMHeadphoneMotionManager {
    static func requestAuthorizationStatus() -> CMAuthorizationStatus {
        // little hacky but it works as expected
        
        var tempManager: CMHeadphoneMotionManager? = .init()
        
        CMHeadphoneMotionManager.authorizationStatus()
        tempManager?.startDeviceMotionUpdates()
        tempManager?.stopDeviceMotionUpdates()
        tempManager = nil
        
        while CMHeadphoneMotionManager.authorizationStatus() == .notDetermined {
            sleep(1)
        }
        
        return CMHeadphoneMotionManager.authorizationStatus()
    }
}
