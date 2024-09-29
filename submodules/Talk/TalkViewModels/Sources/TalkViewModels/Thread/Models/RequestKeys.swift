//
//  RequestKeys.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation

struct RequestKeys {
    public var objectId: String
    public let MORE_TOP_KEY: String
    public let MORE_BOTTOM_KEY: String
    public let MORE_TOP_FIRST_SCENARIO_KEY: String
    public let MORE_BOTTOM_FIRST_SCENARIO_KEY: String
    public let MORE_TOP_SECOND_SCENARIO_KEY: String
    public let MORE_BOTTOM_FIFTH_SCENARIO_KEY: String
    public let FETCH_BY_OFFSET_KEY: String

    init() {
        let objectId = UUID().uuidString
        MORE_TOP_KEY = "MORE-TOP-\(objectId)"
        MORE_BOTTOM_KEY = "MORE-BOTTOM-\(objectId)"
        MORE_TOP_FIRST_SCENARIO_KEY = "MORE-TOP-FIRST-SCENARIO-\(objectId)"
        MORE_BOTTOM_FIRST_SCENARIO_KEY = "MORE-BOTTOM-FIRST-SCENARIO-\(objectId)"
        MORE_TOP_SECOND_SCENARIO_KEY = "MORE-TOP-SECOND-SCENARIO-\(objectId)"
        MORE_BOTTOM_FIFTH_SCENARIO_KEY = "MORE-BOTTOM-FIFTH-SCENARIO-\(objectId)"
        FETCH_BY_OFFSET_KEY = "FETCH-BY-OFFSET-\(objectId)"
        self.objectId = objectId
    }
}
