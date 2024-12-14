//
//  LoginViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Chat
import Foundation
import UIKit
import TalkModels
import TalkExtensions
import SwiftUI

public final class LoginViewModel: ObservableObject {
    @Published public var isLoading = false
    // This two variable need to be set from Binding so public setter needed.
    // It will use for phone number or static token for the integration server.
    @Published public var text: String = ""
    @Published public var verifyCodes: [String] = ["", "", "", "", "", ""]
    public private(set) var isValidPhoneNumber: Bool?
    @Published public  var state: LoginState = .login
    public private(set) var keyId: String?
    @Published public var selectedServerType: ServerTypes = .main
    public let session: URLSession
    public weak var delegate: ChatDelegate?

    public var timerValue: Int = 0
    public var timer: Timer?
    @Published public var expireIn: Int = 60
    @Published public var timerString = "00:00"
    @Published public var timerHasFinished = false
    @Published public var path: NavigationPath = .init()
    @Published public var showSuccessAnimation: Bool = false

    public init(delegate: ChatDelegate, session: URLSession = .shared) {
        self.delegate = delegate
        self.session = session
    }

    public func isPhoneNumberValid() -> Bool {
        isValidPhoneNumber = !text.isEmpty
        return !text.isEmpty
    }

    @MainActor
    public func login() {
        isLoading = true
        if selectedServerType == .integration {
            let ssoToken = SSOTokenResponse(accessToken: text,
                                                  expiresIn: Int(Calendar.current.date(byAdding: .year, value: 1, to: .now)?.millisecondsSince1970 ?? 0),
                                                  idToken: nil,
                                                  refreshToken: nil,
                                                  scope: nil,
                                                  tokenType: nil)
            Task {
                await saveTokenAndCreateChatObject(ssoToken)
            }
            isLoading = false
            return
        }
        
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let req = HandshakeRequest(deviceName: UIDevice.current.name,
                                         deviceOs: UIDevice.current.systemName,
                                         deviceOsVersion: UIDevice.current.systemVersion,
                                         deviceType: isiPad ? "TABLET" : "MOBILE_PHONE",
                                         deviceUID: UIDevice.current.identifierForVendor?.uuidString ?? "")
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: selectedServerType).handshake)!)
        urlReq.httpBody = req.parameterData
        urlReq.method = .post
        Task {
            do {
                let resp = try await session.data(for: urlReq)
                let decodecd = try JSONDecoder().decode(HandshakeResponse.self, from: resp.0)
                if let keyId = decodecd.keyId {
                    isLoading = false                    
                    requestOTP(identity: text, keyId: keyId)
                }
                await MainActor.run {
                    expireIn = decodecd.client?.accessTokenExpiryTime ?? 60
                }
                await startTimer()
            } catch {
                isLoading = false
                showError(.failed)
            }
        }
    }

    @MainActor
    public func requestOTP(identity: String, keyId: String, resend: Bool = false) {
        if isLoading { return }
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: selectedServerType).authorize)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: identity.replaceRTLNumbers())])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        Task {
            do {
                let resp = try await session.data(for: urlReq)
                let result = try JSONDecoder().decode(AuthorizeResponse.self, from: resp.0)
                isLoading = false
                if result.errorMessage != nil {
                    showError(.failed)
                } else {
                    await MainActor.run {
                        if !resend {
                            state = .verify
                        }
                        self.keyId = keyId
                    }
                }
            } catch {
                isLoading = false
                showError(.failed)
            }
        }
    }

    public func saveTokenAndCreateChatObject(_ ssoToken: SSOTokenResponse) async {
        await MainActor.run {
            TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
            let config = Config.config(token: ssoToken.accessToken ?? "", selectedServerType: selectedServerType)
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: nil, config: config, delegate: self.delegate)
            state = .successLoggedIn
        }
    }

    @MainActor
    public func verifyCode() {
        if isLoading { return }
        let codes = verifyCodes.joined(separator:"").replacingOccurrences(of: "\u{200B}", with: "").replaceRTLNumbers()
        guard let keyId = keyId, codes.count == verifyCodes.count else { return }
        isLoading = true
        var urlReq = URLRequest(url: URL(string: AppRoutes(serverType: selectedServerType).verify)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: text.replaceRTLNumbers()), .init(name: "otp", value: codes)])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        Task {
            do {
                let resp = try await session.data(for: urlReq)
                var ssoToken = try JSONDecoder().decode(SSOTokenResponse.self, from: resp.0)
                ssoToken.keyId = keyId
                showSuccessAnimation = true
                try? await Task.sleep(for: .seconds(0.5))
                isLoading = false
                hideKeyboard()
                doHaptic()
                await saveTokenAndCreateChatObject(ssoToken)
                try? await Task.sleep(for: .seconds(0.5))
                await MainActor.run {
                    resetState()
                }
            }
            catch {
                isLoading = false
                doHaptic(failed: true)
                showError(.verificationCodeIncorrect)
            }
        }
    }

    public func resetState() {
        path.removeLast()
        state = .login
        text = ""
        keyId = nil
        isLoading = false
        showSuccessAnimation = false
        verifyCodes = ["", "", "", "", "", ""]
    }

    public func showError(_ state: LoginState) {
        Task { [weak self] in
            guard let self = self else { return }
            await MainActor.run {
                self.state = state
            }
        }
    }

    public func resend() {
        if let keyId = keyId {
            Task { [weak self] in
                guard let self = self else { return }
                await requestOTP(identity: text, keyId: keyId, resend: true)
                await startTimer()
            }
        }
    }

    @MainActor
    public func startTimer() async {
        timerHasFinished = false
        timer?.invalidate()
        timer = nil
        timerValue = expireIn
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            if timerValue != 0 {
                timerValue -= 1
                timerString = timerValue.timerString(locale: Language.preferredLocale) ?? ""
            } else {
                timerHasFinished = true
                timer.invalidate()
                self.timer = nil
            }
        }
    }

    public func cancelTimer() {
        timerHasFinished = false
        timer?.invalidate()
        timer = nil
    }

    public func startNewPKCESession() {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let auth0domain = "accounts.pod.ir"
        let authorizeURL = "https://\(auth0domain)/oauth2/authorize"
        let tokenURL = "https://\(auth0domain)/oauth2/token"
        let clientId = "88413l69cd4051a039cf115ee4e073"
        let redirectUri = "talk://login"
        let parameters = OAuth2PKCEParameters(authorizeUrl: authorizeURL,
                                              tokenUrl: tokenURL,
                                              clientId: clientId,
                                              redirectUri: redirectUri,
                                              callbackURLScheme: bundleIdentifier)
        let authenticator = OAuth2PKCEAuthenticator()
        authenticator.authenticate(parameters: parameters) { [weak self] result in
            switch result {
            case .success(let accessTokenResponse):
                Task { [weak self] in
                    let ssoToken = accessTokenResponse
                    await self?.saveTokenAndCreateChatObject(ssoToken)
                }
            case .failure(let error):
                let message = error.localizedDescription
                print(message)
                self?.startNewPKCESession()
            }
        }
    }

    private func doHaptic(failed: Bool = false) {
        UIImpactFeedbackGenerator(style: failed ? .rigid : .soft).impactOccurred()
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
