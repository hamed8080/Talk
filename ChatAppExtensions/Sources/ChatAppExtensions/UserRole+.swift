//
//  UserRole+.swift
//  ChatApplication
//
//  Created by hamed on 3/14/23.
//
import Foundation
import ChatModels

public extension UserRole {
    var isAdminRolesChanged: Bool { roles?.sorted(by: {$0.rawValue <  $1.rawValue}) ?? [] == Roles.adminRoles.sorted(by: {$0.rawValue < $1.rawValue}) }
}
