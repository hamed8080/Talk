//
//  MessageSection.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation

public struct MessageSection: Identifiable, Hashable, Equatable {
    public var id: Int64 { date.millisecondsSince1970 }
    public let date: Date
    public var vms: ContiguousArray<MessageRowViewModel>
    public let sectionText: String

    public init(date: Date, vms: ContiguousArray<MessageRowViewModel>) {
        self.date = date
        self.vms = vms
        self.sectionText = date.yearDateMonthName ?? ""
    }
}
