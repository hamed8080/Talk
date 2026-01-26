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
import Combine

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
    private var cancellableSet: Set<AnyCancellable> = Set()
    
    public init(delegate: ChatDelegate, session: URLSession = .shared) {
        self.delegate = delegate
        self.session = session
        register()
    }
    
    private func register() {
        $selectedServerType.sink { [weak self] newValue in
            self?.setDefaultServerOnSpecChange(newValue: newValue)
        }
        .store(in: &cancellableSet)
    }

    public func isPhoneNumberValid() -> Bool {
        isValidPhoneNumber = !text.isEmpty
        return !text.isEmpty
    }

    public func login() async {
        isLoading = true
        if selectedServerType == .integration {
            await integerationSSOLoing()
            return
        } else if selectedServerType == .token {
            let ssoToken = SSOTokenResponse(accessToken: text,
                                            expiresIn: Int.max,
                                            idToken: nil,
                                            refreshToken: nil,
                                            scope: nil,
                                            tokenType: nil,
                                            deviceUID: UUID().uuidString,
                                            codeVerifier: nil)
            await onSuccessToken(ssoToken)
            return
        }
        let urlReq = makeHandshakeRequest()
        do {
            let resp = try await session.data(for: urlReq)
            let decodecd: HandshakeResponse = try await decodeOnBackground(data: resp.0)
            
            if let keyId = decodecd.keyId {
                isLoading = false
                await requestOTP(identity: identity, keyId: keyId)
            }
            expireIn = decodecd.client?.accessTokenExpiryTime ?? 60
            startTimer()
        } catch {
            isLoading = false
            showError(.failed)
        }
    }
    
    private func makeHandshakeRequest() -> URLRequest {
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let req = HandshakeRequest(deviceName: UIDevice.current.name,
                                         deviceOs: UIDevice.current.systemName,
                                         deviceOsVersion: UIDevice.current.systemVersion,
                                         deviceType: isiPad ? "TABLET" : "MOBILE_PHONE",
                                         deviceUID: UIDevice.current.identifierForVendor?.uuidString ?? "")
        let address = getURLString(path: AppState.shared.spec.paths.talkBack.handshake)
        var urlReq = URLRequest(url: URL(string: address)!)
        urlReq.httpBody = req.parameterData
        urlReq.method = .post
        return urlReq
    }

    public func requestOTP(identity: String, keyId: String, resend: Bool = false) async {
        if isLoading { return }
        let urlReq = makeAuthorizeRequest(keyId: keyId)
        do {
            let resp = try await session.data(for: urlReq)
            let result: AuthorizeResponse = try await decodeOnBackground(data: resp.0)
            isLoading = false
            if result.errorMessage != nil {
                showError(.failed)
            } else {
                if !resend {
                    state = .verify
                }
                self.keyId = keyId
            }
        } catch {
            isLoading = false
            showError(.failed)
        }
    }
    
    private func makeAuthorizeRequest(keyId: String) -> URLRequest {
        let address = getURLString(path: AppState.shared.spec.paths.talkBack.authorize)
        var urlReq = URLRequest(url: URL(string: address)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: identity.replaceRTLNumbers())])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        return urlReq
    }
    
    private func onSuccessToken(_ ssoToken: SSOTokenResponse) async {
        let spec: Spec = getSpec()
        let token = ssoToken.accessToken ?? ""
        await TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
        createChatObject(spec: spec, token: token)
        state = .successLoggedIn
        
        /// This will be called only once on successfull login
        /// This method is different than token refresh which might be called multiple times.
        if let remoteSpec = try? await SpecManagerViewModel.shared.getConfigsOnToken() {
            createChatObject(spec: remoteSpec, token: token)
        }
    }
    
    private func createChatObject(spec: Spec, token: String) {
        let config = Spec.config(spec: spec, token: token)
        UserConfigManagerVM.instance.createChatObjectAndConnect(userId: nil, config: config, delegate: self.delegate)
    }
    
    private func getSpec() -> Spec {
        let isSnadbox = selectedServerType == .sandbox
        let currentSpec = AppState.shared.spec
        let sandboxServer = currentSpec.servers.first(where: { $0.server == ServerTypes.sandbox.rawValue })
        
        if isSnadbox, var sandboxServer = sandboxServer {
            return Spec(
                servers: currentSpec.servers,
                server: sandboxServer,
                paths: currentSpec.paths,
                subDomains: currentSpec.subDomains
            )
        }
        
        if selectedServerType == .token, let mainServer = currentSpec.servers.first(where: { $0.server == ServerTypes.main.rawValue }) {
            return Spec(
                servers: currentSpec.servers,
                server: .init(socket: mainServer.socket, server: mainServer),
                paths: currentSpec.paths,
                subDomains: currentSpec.subDomains
            )
        }
        return AppState.shared.spec
    }

    public func verifyCode() async {
        if isLoading { return }
        let codes = verifyCodes.joined(separator:"").replacingOccurrences(of: "\u{200B}", with: "").replaceRTLNumbers()
        guard let keyId = keyId, codes.count == verifyCodes.count else { return }
        isLoading = true
        let urlReq = makeVerifyRequest(codes: codes, keyId: keyId)
        do {
            let resp = try await session.data(for: urlReq)
            var ssoToken: SSOTokenResponse = try await decodeOnBackground(data: resp.0)
            ssoToken.keyId = keyId
            showSuccessAnimation = true
            try? await Task.sleep(for: .seconds(0.5))
            isLoading = false
            hideKeyboard()
            doHaptic()
            await onSuccessToken(ssoToken)
            try? await Task.sleep(for: .seconds(0.5))
            resetState()
        }
        catch {
            isLoading = false
            doHaptic(failed: true)
            showError(.verificationCodeIncorrect)
        }
    }
    
    private func makeVerifyRequest(codes: String, keyId: String) -> URLRequest {
        let address = getURLString(path: AppState.shared.spec.paths.talkBack.verify)
        var urlReq = URLRequest(url: URL(string: address)!)
        urlReq.url?.append(queryItems: [.init(name: "identity", value: identity), .init(name: "otp", value: codes)])
        urlReq.allHTTPHeaderFields = ["keyId": keyId]
        urlReq.method = .post
        return urlReq
    }
    
    @AppBackgroundActor
    private func decodeOnBackground<T: Decodable>(data: Data) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
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

/// Integeration login sso token.
extension LoginViewModel {
    private func integerationSSOLoing() async {
        let ssoToken = SSOTokenResponse(accessToken: text,
                                        expiresIn: Int(Calendar.current.date(byAdding: .year, value: 1, to: .now)?.millisecondsSince1970 ?? 0),
                                        idToken: nil,
                                        refreshToken: nil,
                                        scope: nil,
                                        tokenType: nil)
        await onSuccessToken(ssoToken)
        isLoading = false
    }
}

extension LoginViewModel {
    /// Default main server or sandbox server base address.
    private func getURLString(path: String) -> String {
        let spec = AppState.shared.spec
        let isSandbox = selectedServerType == .sandbox
        let defaultServer = spec.server
        let sandboxServer = spec.servers.first(where: { $0.server == ServerTypes.sandbox.rawValue })
        let server: Server = isSandbox ? sandboxServer ?? defaultServer : defaultServer
        return "\(server.talkback)\(path)"
    }
    
    private func setDefaultServerOnSpecChange(newValue: ServerTypes) {
        let currentSpec = AppState.shared.spec
        var defaultServer: Server
        defaultServer = currentSpec.servers.first(where: { $0.server == newValue.rawValue }) ?? currentSpec.server
        let newSpec = Spec(servers: currentSpec.servers, server: defaultServer, paths: currentSpec.paths, subDomains: currentSpec.subDomains)
        SpecManagerViewModel.shared.store(newSpec)
        AppState.shared.setSpec(newSpec)
    }
}

/// PKCE login.
extension LoginViewModel {
    public func startNewPKCESession() {
        let parameters = makePKCEParameters()
        let authenticator = OAuth2PKCEAuthenticator()
        authenticator.authenticate(parameters: parameters) { [weak self] result in
            Task { @MainActor [weak self] in
                await self?.onAuthentication(result)
            }
        }
    }
    
    private func makePKCEParameters() -> OAuth2PKCEParameters{
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
        return parameters
    }
    
    private func onAuthentication(_ result: Result<SSOTokenResponse, OAuth2PKCEAuthenticatorError>) async {
        switch result {
        case .success(let accessTokenResponse):
            let ssoToken = accessTokenResponse
            await onSuccessToken(ssoToken)
        case .failure(let error):
            let message = error.localizedDescription
        #if DEBUG
                print(message)
        #endif
            startNewPKCESession()
        }
    }
}
