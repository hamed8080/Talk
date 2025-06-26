//
//  Logger+.swift
//  
//
//  Created by hamed on 12/13/23.
//

import Foundation
import Logger

public extension Logger {
    static func makeLog(prefix: String, request: URLRequest, response: (Data, URLResponse)) -> String {
        var output = "Start Of Request====\n"
        output += " REST Request With Method:\(request.method.rawValue) - url:\(request.url?.absoluteString ?? "")\n"
        output += " With Headers:\(request.allHTTPHeaderFields?.debugDescription ?? "[]")\n"
        output += " With HttpBody:\(request.httpBody?.string ?? "nil")\n"
        output += "End Of Request====\n"
        output += "\n"
        return output
    }
}
