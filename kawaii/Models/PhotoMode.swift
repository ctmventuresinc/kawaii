//
//  PhotoMode.swift
//  kawaii
//
//  Created by Los Mayers on 6/25/25.
//

import Foundation

enum PhotoMode: CaseIterable {
    case mixed     // 50/50 face detection + any photo
    case faceOnly  // only face detection
    case anyPhoto  // only random photos
    
    var icon: String {
        switch self {
        case .mixed: return "photo.stack"
        case .faceOnly: return "face.smiling"
        case .anyPhoto: return "photo.on.rectangle"
        }
    }
    
    var description: String {
        switch self {
        case .mixed: return "Mixed mode"
        case .faceOnly: return "Face detection"
        case .anyPhoto: return "Any photo"
        }
    }
}
