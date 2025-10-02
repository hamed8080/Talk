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

@MainActor
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

    public func login() {
        isLoading = true
        if selectedServerType == .integration {
            let ssoToken = SSOTokenResponse(accessToken: text,
                                                  expiresIn: Int(Calendar.current.date(byAdding: .year, value: 1, to: .now)?.millisecondsSince1970 ?? 0),
                                                  idToken: nil,
                                                  refreshToken: nil,
                                                  scope: nil,
                                                  tokenType: nil)
            Task { [weak self] in
                guard let self = self else { return }
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
        let spec = AppState.shared.spec
        let address = "\(spec.server.talkback)\(spec.paths.talkBack.handshake)"
        var urlReq = URLRequest(url: URL(string: address)!)
        urlReq.httpBody = req.parameterData
        urlReq.method = .post
        Task { @AppBackgroundActor [weak self] in
            guard let self = self else { return }
            do {
                let resp = try await session.data(for: urlReq)
                let decodecd = try JSONDecoder().decode(HandshakeResponse.self, from: resp.0)
                
                await MainActor.run {
                    if let keyId = decodecd.keyId {
                        isLoading = false
                        requestOTP(identity: identity, keyId: keyId)
                    }
                    expireIn = decodecd.client?.accessTokenExpiryTime ?? 60
                    startTimer()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(.failed)
                }
            }
        }
    }

    public func requestOTP(identity: String, keyId: String, resend: Bool = false) {
        if isLoading { return }
        let spec = AppState.shared.spec
        let address = "\(spec.server.talkback)\(spec.paths.talkBack.authorize)"
        var urlReq = URLRequest(url: URL(string: address)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: identity.replaceRTLNumbers())])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        Task { @AppBackgroundActor [weak self] in
            guard let self = self else { return }
            do {
                let resp = try await session.data(for: urlReq)
                let result = try JSONDecoder().decode(AuthorizeResponse.self, from: resp.0)
                await MainActor.run {
                    isLoading = false
                    if result.errorMessage != nil {
                        showError(.failed)
                    } else {
                        
                        if !resend {
                            state = .verify
                        }
                        self.keyId = keyId
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError(.failed)
                }
            }
        }
    }

    public func saveTokenAndCreateChatObject(_ ssoToken: SSOTokenResponse) async {
        await MainActor.run {
            TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
            let config = Spec.config(spec: AppState.shared.spec, token: ssoToken.accessToken ?? "", selectedServerType: selectedServerType)
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: nil, config: config, delegate: self.delegate)
            state = .successLoggedIn
        }
    }

    public func verifyCode() {
        if isLoading { return }
        let codes = verifyCodes.joined(separator:"").replacingOccurrences(of: "\u{200B}", with: "").replaceRTLNumbers()
        guard let keyId = keyId, codes.count == verifyCodes.count else { return }
        isLoading = true
        let spec = AppState.shared.spec
        let address = "\(spec.server.talkback)\(spec.paths.talkBack.verify)"
        var urlReq = URLRequest(url: URL(string: address)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: identity), .init(name: "otp", value: codes)])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let resp = try await session.data(for: urlReq)
                var ssoToken = try await decodeSSOToken(data: resp.0)
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
                await MainActor.run {
                    isLoading = false
                    doHaptic(failed: true)
                    showError(.verificationCodeIncorrect)
                }
            }
        }
    }
    
    @AppBackgroundActor
    private func decodeSSOToken(data: Data) throws -> SSOTokenResponse {
        try JSONDecoder().decode(SSOTokenResponse.self, from: data)
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
                requestOTP(identity: text, keyId: keyId, resend: true)
                startTimer()
            }
        }
    }

    private func startTimer() {
        timerHasFinished = false
        timer?.invalidate()
        timer = nil
        timerValue = expireIn
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                self?.handleTimer()
            }
        }
    }
    
    private func handleTimer() {
        if timerValue != 0 {
            timerValue -= 1
            timerString = timerValue.timerString(locale: Language.preferredLocale) ?? ""
        } else {
            timerHasFinished = true
            timer?.invalidate()
            self.timer = nil
        }
    }

    public func cancelTimer() {
        timerHasFinished = false
        timer?.invalidate()
        timer = nil
    }

    public func startNewPKCESession() {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let auth0domain = AppState.shared.spec.server.sso
        let authorizeURL = "\(auth0domain)\(AppState.shared.spec.paths.sso.authorize)"
        let tokenURL = "\(auth0domain)\(AppState.shared.spec.paths.sso.token)"
        let clientId = AppState.shared.spec.paths.sso.clientId
        let redirectUri = AppState.shared.spec.paths.talk.redirect
        let parameters = OAuth2PKCEParameters(authorizeUrl: authorizeURL,
                                              tokenUrl: tokenURL,
                                              clientId: clientId,
                                              redirectUri: redirectUri,
                                              callbackURLScheme: bundleIdentifier)
        let authenticator = OAuth2PKCEAuthenticator()
        authenticator.authenticate(parameters: parameters) { [weak self] result in
            Task { @MainActor [weak self] in
                await self?.onAuthentication(result)
            }
        }
    }
    
    private func onAuthentication(_ result: Result<SSOTokenResponse, OAuth2PKCEAuthenticatorError>) async {
        switch result {
        case .success(let accessTokenResponse):
            let ssoToken = accessTokenResponse
            await saveTokenAndCreateChatObject(ssoToken)
        case .failure(let error):
            let message = error.localizedDescription
        #if DEBUG
                print(message)
        #endif
            startNewPKCESession()
        }
    }

    private func doHaptic(failed: Bool = false) {
        UIImpactFeedbackGenerator(style: failed ? .rigid : .soft).impactOccurred()
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var identity: String {
        return "\(0)\(text)".replaceRTLNumbers()
    }
}
