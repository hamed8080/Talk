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
    public let TOP_FIRST_SCENARIO_KEY: String
    public let BOTTOM_FIRST_SCENARIO_KEY: String
    public let MORE_BOTTOM_FIRST_SCENARIO_KEY: String
    public let MORE_TOP_SECOND_SCENARIO_KEY: String
    public let MORE_BOTTOM_FIFTH_SCENARIO_KEY: String
    public let FETCH_BY_OFFSET_KEY: String
    public let SAVE_SCROOL_POSITION_KEY: String

    init() {
        let objectId = UUID().uuidString
        MORE_TOP_KEY = "MORE-TOP-\(objectId)"
        MORE_BOTTOM_KEY = "MORE-BOTTOM-\(objectId)"
        TOP_FIRST_SCENARIO_KEY = "TOP-FIRST-SCENARIO-\(objectId)"
        BOTTOM_FIRST_SCENARIO_KEY = "BOTTOM-FIRST-SCENARIO-\(objectId)"
        MORE_BOTTOM_FIRST_SCENARIO_KEY = "MORE-BOTTOM-FIRST-SCENARIO-\(objectId)"
        MORE_TOP_SECOND_SCENARIO_KEY = "MORE-TOP-SECOND-SCENARIO-\(objectId)"
        MORE_BOTTOM_FIFTH_SCENARIO_KEY = "MORE-BOTTOM-FIFTH-SCENARIO-\(objectId)"
        FETCH_BY_OFFSET_KEY = "FETCH-BY-OFFSET-\(objectId)"
        SAVE_SCROOL_POSITION_KEY = "SAVE-SCROOL-POSITION-\(objectId)"
        self.objectId = objectId
    }
}
