//
//  SettingViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Foundation
import UIKit
import FanapPodChatSDK
import Combine

class SettingViewModel: ObservableObject {
    
    @Published
    var model = SettingModel()
    
    @Published
    var secondToExpire:Double = 0
    
    private (set) var connectionStatusCancelable:AnyCancellable? = nil
    
    @Published
    var connectionStatus:ConnectionStatus     = .Connecting
    
    init() {
        connectionStatusCancelable = AppState.shared.$connectionStatus.sink { status in            
            self.connectionStatus = status
        }
    }
    
    func startTokenTimer(){
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            if let createDate = TokenManager.shared.getCreateTokenDate() , let ssoTokenExipreTime = TokenManager.shared.getSSOTokenFromUserDefaults()?.expiresIn{
                let expireIn = createDate.advanced(by:  Double(ssoTokenExipreTime)).timeIntervalSince1970 - Date().timeIntervalSince1970
                self?.secondToExpire = Double(expireIn)
            }
        }
    }
    
    func switchUser(isNext: Bool){
        if isNext {
            
        }else{
            
        }
    }
}
