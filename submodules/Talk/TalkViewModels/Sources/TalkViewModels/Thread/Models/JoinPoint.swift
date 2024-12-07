//
//  JoinPoint.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation

enum JoinPoint {
    case bottom(bottomVMBeforeJoin: MessageRowViewModel?)
    case top(topVMBeforeJoin: MessageRowViewModel?)
}
