//
//  SessionHandler.swift
//  HRIS
//
//  Created by Sourav@Beas on 24/03/17.
//  Copyright © 2017 Sourav Basu Roy. All rights reserved.
//

import Foundation

public protocol SessionHandlerDelegate:class {
    func WSError(errorMessage:String)
    func WSSuccess(response:Any?,webserviceType:String?)
}

public class SessionHandler:NSObject{
    fileprivate var sessionConfigaration = URLSessionConfiguration.default
    fileprivate var urlSession:URLSession? = nil
    public weak var sessionDelegate:SessionHandlerDelegate?
    public var identifier:String? = nil
    public var view:UIView?
    public var isMultiPart = false
    private let boundry = UUID().uuidString
//    public var isBackground = false
    public override init() {
        self.urlSession = URLSession(configuration: sessionConfigaration)
    }
    private func CustomActivityIndicatory(_ viewContainer: UIView, startAnimate:Bool? = true) {
        let mainContainer: UIView = UIView(frame: viewContainer.frame)
        mainContainer.center = viewContainer.center
        mainContainer.backgroundColor = UIColor.clear
        //    mainContainer.alpha = 0.5
        mainContainer.tag = 789456123
        mainContainer.isUserInteractionEnabled = false
        
        let viewBackgroundLoading: UIView = UIView(frame: CGRect(x:0,y: 0,width: 80,height: 80))
        viewBackgroundLoading.center = viewContainer.center
        viewBackgroundLoading.backgroundColor = UIColor.black
        viewBackgroundLoading.alpha = 0.7
        viewBackgroundLoading.clipsToBounds = true
        viewBackgroundLoading.layer.cornerRadius = 15
        
        let activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.frame = CGRect(x:0.0,y: 0.0,width: 40.0, height: 40.0)
        activityIndicatorView.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.whiteLarge
        activityIndicatorView.center = CGPoint(x: viewBackgroundLoading.frame.size.width / 2, y: viewBackgroundLoading.frame.size.height / 2)
        if startAnimate!{
            viewBackgroundLoading.addSubview(activityIndicatorView)
            mainContainer.addSubview(viewBackgroundLoading)
            viewContainer.addSubview(mainContainer)
            activityIndicatorView.startAnimating()
        }else{
            for subview in viewContainer.subviews{
                if subview.tag == 789456123{
                    subview.removeFromSuperview()
                }
            }
        }
        //    return activityIndicatorView
    }
    
    public func multipartData(keyValuePair:[String:Any]) -> Data? {
        var body = Data()
//        var bodyStr = ""
        for (key,value) in keyValuePair {
            if let image = value as? UIImage {
                let mimetype = "image/jpg"
                let defFileName = "default.jpg"
                let imageData = UIImageJPEGRepresentation(image, 0.5) ?? Data()
//                bodyStr += "--\(boundry)\r\n"
//                bodyStr += "Content-Disposition:form-data; name=\(key.description);filename=\(defFileName)\r\n"
//                bodyStr += "Content-Type: \(mimetype)\r\n\r\n"
//                bodyStr += String(data: imageData, encoding: .utf8 ) ?? ""
//                bodyStr += "\r\n"
                body.append("--\(boundry)\r\n".data(using: .utf8) ?? Data())
                body.append("Content-Disposition:form-data; name=attachment[\(key.description)];filename=\(defFileName)\r\n".data(using: .utf8) ?? Data())
                body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8) ?? Data())
                body.append(imageData)
                body.append("\r\n".data(using: .utf8) ?? Data())
            }
            else{
//                bodyStr += "--\(boundry)\r\n"
//                bodyStr += "Content-Disposition:form-data; name=\(key.description)"
//                bodyStr += "\r\n\r\n\(value as? String ?? "")\n"
                body.append("--\(boundry)\r\n".data(using: .utf8) ?? Data())
                body.append("Content-Disposition:form-data; name=\(key.description)".data(using: .utf8) ?? Data())
                body.append("\r\n\r\n\(value as? String ?? "")\n".data(using: .utf8) ?? Data())
            }
            
        }
//        body = bodyStr.data(using: .utf8) ?? Data()
        if body.isEmpty == false {
            isMultiPart = true
            print(String(data: body, encoding: .utf8) ?? "")
            return body
        }
        else{
            isMultiPart = false
            return nil
        }
    }
    
    public func parseJSON(anyObject:Any?) -> [String:Any] {
        guard let data = anyObject as? Data else { return [String:Any]() }
        print("json Rsponse: \(String(data: data, encoding: .utf8) ?? "{}")")
        do {
            let decode = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any] ?? [String:Any]()
            return decode
            
        } catch  {
            return [String:Any]()
        }
    }
    
    public func callWebservice(baseUrl:URL,httpMethod:String,acceptType:String?,contentType:String?,httpBody:Data?,authentication:String?) throws {
        if let customview = view {
            CustomActivityIndicatory(customview, startAnimate: true)
        }
//        if isBackground == true {
//            let identi = "com.process.background"
//            sessionConfigaration = URLSessionConfiguration.background(withIdentifier: identi)
//            self.urlSession = URLSession(configuration: sessionConfigaration)
//        }

        var urlRequest = URLRequest(url: baseUrl, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60)
        urlRequest.httpMethod = httpMethod
        if let httpAuthentication = authentication {
            urlRequest.setValue(httpAuthentication, forHTTPHeaderField: "Authorization")
        }
        if let httpAccept = acceptType {
            urlRequest.setValue(httpAccept, forHTTPHeaderField: "Accept")
        }
        if isMultiPart == true {
            urlRequest.setValue("multipart/form-data; boundary=\(boundry)", forHTTPHeaderField: "Content-Type")
        }
        else{
            if let httpContentType = contentType {
                urlRequest.setValue(httpContentType, forHTTPHeaderField: "Content-Type")
            }
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
                            if let customview = self.view {
                            self.CustomActivityIndicatory(customview, startAnimate: false)
                           }
                            self.sessionDelegate?.WSSuccess(response: data,webserviceType: self.identifier)
                        })
                    }
                    
                }else{
                    if (self.sessionDelegate != nil){
                        OperationQueue.main.addOperation({
                            if let customview = self.view {
                                self.CustomActivityIndicatory(customview, startAnimate: false)
                            }
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
                        if let customview = self.view {
                            self.CustomActivityIndicatory(customview, startAnimate: false)
                        }
                        self.sessionDelegate?.WSError(errorMessage:(error?.localizedDescription)!)
                    })
                    
                }
            }
        })
        dataTask?.resume()
  
    }

}
