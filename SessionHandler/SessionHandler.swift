//
//  SessionHandler.swift
//  HRIS
//
//  Created by Sourav@Beas on 24/03/17.
//  Copyright © 2017 BEAS. All rights reserved.
//

import Foundation

protocol SessionHandlerDelegate:class {
    func WSError(errorMessage:String)
    func WSSuccess(response:Any?,webserviceType:String?)
}

class SessionHandler:NSObject{
    fileprivate let sessionConfigaration = URLSessionConfiguration.default
    fileprivate var urlSession:URLSession? = nil
    public weak var sessionDelegate:SessionHandlerDelegate?
    public var identifier:String? = nil
    override init() {
        self.urlSession = URLSession(configuration: sessionConfigaration)
    }
    public func callWebservice(baseUrl:URL,httpMethod:String,acceptType:String?,contentType:String?,httpBody:Data?,authentication:String?) throws {
        
        var urlRequest = URLRequest(url: baseUrl, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60)
        urlRequest.httpMethod = httpMethod
        if let httpAuthentication = authentication {
            urlRequest.setValue(httpAuthentication, forHTTPHeaderField: "Authorization")
        }
        if let accepttype = acceptType {
            urlRequest.setValue(accepttype, forHTTPHeaderField: "Accept")
        }
        if let contenttype = contentType {
            urlRequest.setValue(contenttype, forHTTPHeaderField: "Content-Type")
        }
        
        if let body = httpBody {
            urlRequest.httpBody = body
        }
        let dataTask = urlSession?.dataTask(with: urlRequest, completionHandler: { (data, reseponse, error) in
            
            if (error == nil) {
                 let httpResponse = reseponse as! HTTPURLResponse
                if httpResponse.statusCode == 200 {
                    if (self.sessionDelegate != nil ){
                        OperationQueue.main.addOperation({
                            
                            self.sessionDelegate?.WSSuccess(response: data,webserviceType: self.identifier)
                        })
                    }
                    
                }else{
                    if (self.sessionDelegate != nil){
                        OperationQueue.main.addOperation({
                            if (reseponse != nil) {
                                self.sessionDelegate?.WSError(errorMessage:reseponse.debugDescription)
                            }
                            
                        })

                    }
                }
                
            }
            else{
                if (self.sessionDelegate != nil){
                    OperationQueue.main.addOperation({
                        
                        self.sessionDelegate?.WSError(errorMessage:(error?.localizedDescription)!)
                    })
                    
                }
            }
        })
        dataTask?.resume()
        
        
        
    }
    
    
}
