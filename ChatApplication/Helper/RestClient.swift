//
//  RestClient.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/19/21.
//

import Foundation
struct VoidCodable:Codable{
    
}

extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let data = try JSONEncoder().encode(self)
    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
      throw NSError()
    }
    return dictionary
  }
}

typealias OnRestClientError = (Data?,Error?)->()

class RestClient<D:Codable>{
    
    //MARK: - Variables
    /***************************************************/
    var config :URLSessionConfiguration
    let GET_TOKEN_REQ_CODE = 80000
    
    
    var encoder = JSONEncoder()
    var decoder = JSONDecoder()
    
    var req                  :URLRequest!
    var url                  :String?                             = nil
    var method               :HTTPMethod                          = .get
    var useMiladiDecoder     :Bool                                = true
    var noBodyReq            :Bool?                               = false
    var noBodyRes            :Bool?                               = false
    var contentType          :String?                             = "Application/Json"
    var dateEncodingStrategy :JSONEncoder.DateEncodingStrategy    = .iso8601
    var onError              : OnRestClientError?                 = nil
    var onCompleted          : (()->())?                          = nil
    var task:URLSessionTask?                                      = nil
    /***************************************************/
    
    init() {
        config  = RestClient.getConfiguration()
    }
    
    init(timeout:Double? = nil , isBackground:Bool? = false) {
        config = RestClient.getConfiguration(timeout: timeout , isBackground: isBackground ?? false)
    }
    
    //MARK: - Builder Methods
    /***************************************************/
    
    public class func getConfiguration(timeout:Double? = 40000 ,isBackground:Bool = false) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest  = timeout ?? 40000
        configuration.timeoutIntervalForResource = timeout ?? 40000
        return configuration
    }
    
    func setUrl(_ url:String) -> RestClient {
        self.url = url
        let encodedValue = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        self.req = URLRequest(url: URL(string: encodedValue)!)
        req.httpMethod = method.rawValue
        return self
    }
    
    func setMethod(_ method:HTTPMethod) -> RestClient {
        self.method = method
        self.req.httpMethod = method.rawValue
        return self
    }
    
    
    func setParamsAsQueryString<T:Encodable>(_ params:T? = nil)->RestClient{
        if let items = try? params?.asDictionary(),let url = url{
            let queryItems = items.map{URLQueryItem(name: $0.key, value: "\($0.value)")}
            var urlComps = URLComponents(string: url)!
            urlComps.queryItems = queryItems
            req = URLRequest(url: URL(string: urlComps.url?.absoluteString ?? "")!)
            req.httpMethod = method.rawValue
        }
        return self
    }
    
    func setParams<T: Encodable>(_ params:T? = nil) -> RestClient {
        if noBodyRes != nil, !noBodyRes! && method == .post {
            req?.httpBody = try! encoder.encode(params)
        }
        return self
    }
    
    func setNoBodyReq(_ noBodyReq:Bool?) -> RestClient {
        self.noBodyReq = noBodyReq
        return self
    }
    
    func setNoBodyRes(_ noBodyRes:Bool?) -> RestClient {
        self.noBodyRes = noBodyRes
        return self
    }
    
    func setUseMiladiDecoder(_ useMiladiDecoder:Bool) -> RestClient {
        self.useMiladiDecoder = useMiladiDecoder
        return self
    }
    
    func setContentType(_ contentType:String)-> RestClient{
        self.contentType = contentType
        return self
    }
    
    func setDateEncodingStrategy(_ strategy:JSONEncoder.DateEncodingStrategy)-> RestClient{
        self.dateEncodingStrategy = strategy
        return self
    }
    
    func setOnError(_ onError:OnRestClientError? = nil) ->RestClient{
        self.onError = onError
        return self
    }
    
    func setOnCompleted(_ completedHandler:(()->())?)->RestClient {
        self.onCompleted = completedHandler
        return self
    }
    
    func addRequestHeader(key:String , value:String)->RestClient{
        req.allHTTPHeaderFields?[key] = value
        return self
    }
    
    /***************************************************/
    
    public func setAuthorization(value:String) {
        req?.addValue(value, forHTTPHeaderField: "Authorization")
    }
    
    public func request(completionHandler:((D)->())? = nil ){
        
        guard  url != nil else{print("url cant be null"); return}
        req?.setValue("Application/Json", forHTTPHeaderField: "Accept")
        req?.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        task = URLSession(configuration: config).dataTask(with: req){ data,response,error in
            DispatchQueue.main.async {
                self.onCompleted?()
            }
            let  code = (response as? HTTPURLResponse)?.statusCode
            if code == 401{
                self.onError?(data,error)
                return
            }
            if D.Type.self == VoidCodable.Type.self && code == 200{
                DispatchQueue.main.async {
                    completionHandler?(VoidCodable() as! D)
                }
                return
            }
            if let value = self.decodeResponse(data , code: code ?? -1) , code == 200{
                DispatchQueue.main.async {
                    completionHandler?(value)
                }
            }else{
                self.onError?(data,error)
            }
        }
        task?.resume()
    }
    
    private func decodeResponse(_ data:Data? , code:Int) -> D?{
        guard let data = data else{return nil}
        if D.Type.self  == String.Type.self{
            let value = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\"", with: "")
            if value == "" {return nil}
            else{return value as? D}
        }
        do{
            let decoded = try decoder.decode(D.self, from:data)
            return decoded
        }catch{
            return nil
        }
    }
    
    deinit {
        print("deinit RestClient")
    }
    
    public enum HTTPMethod: String {
        case options = "OPTIONS"
        case get     = "GET"
        case head    = "HEAD"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
        case trace   = "TRACE"
        case connect = "CONNECT"
    }
}
