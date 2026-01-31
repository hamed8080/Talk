//
//  SSOTokenResponse+.swift
//  TalkExtensions
//
//  Created by Hamed Hosseini on 1/24/26.
//

import Foundation
import TalkModels

public extension SSOTokenResponse {
    init(token: String) {
        self = SSOTokenResponse(
            accessToken: token,
            expiresIn: Int.max,
            idToken: nil,
            refreshToken: nil,
            scope: nil,
            tokenType: nil,
            deviceUID: UUID().uuidString,
            codeVerifier: nil
        )
    }
}
