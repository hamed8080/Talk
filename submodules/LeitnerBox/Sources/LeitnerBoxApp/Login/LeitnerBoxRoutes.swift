//
//  LeitnerBoxRoutes.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 5/7/25.
//

import Foundation

class LeitnerBoxRoutes {
    static let api = "http://188.132.192.166:5000"
    static let register = api + "/register"
    static let login = api + "/login"
    static let suggest = api + "/suggest"
    static let suggestions = api + "/suggestions"
    static let deleteAccount = api + "/deleteaccount"
    static let forgot = api + "/forgot-password"
    static let check = api + "/check"
}
