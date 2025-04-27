//
//  Colors.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/23/25.
//

import UIKit

enum Colors: CaseIterable {
    case clear
    case red
    case green
    case blue
    case black
    case white
    
    var name: String {
        switch self {
        case .clear:
            "Clear"
        case .red:
            "Red"
        case .green:
            "Green"
        case .blue:
            "Blue"
        case .black:
            "Black"
        case .white:
            "White"
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .clear:
            .clear
        case .red:
            .red
        case .green:
            .green
        case .blue:
            .blue
        case .black:
            .black
        case .white:
            .white
        }
    }
}
