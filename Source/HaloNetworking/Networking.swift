//
//  Networking.swift
//  MoMOSFramework
//
//  Created by Borja Santos-Díez on 17/06/15.
//  Copyright (c) 2015 MOBGEN Technology. All rights reserved.
//

import Foundation
import Alamofire
import Result

/// Module encapsulating all the networking features of the Framework
class Networking {
    
    var token:HaloToken?
    var clientId:String?
    var clientSecret:String?
    
    let alamofire = Alamofire.Manager.sharedInstance
    
    /**
    Authenticate against the HALO backend using a client id and a client secret
    
    :param: clientId            Client id to be used for authentication
    :param: clientSecret        Client secret to be used for authentication
    :param: completionHandler   Callback where the response from the server can be processed
    */
    func authenticate(completionHandler handler: (result: Result<HaloToken, NSError>) -> Void) -> Void {
        
        if let haloToken = token {
            if haloToken.isExpired() {
                /// Refresh token
                haloAuthenticate(haloToken.refreshToken, completionHandler: handler)
            } else {
                handler(result: .Success(haloToken))
            }
        } else {
            haloAuthenticate(nil, completionHandler: handler)
        }
        
    }
    
    /**
    Internal call to the authentication process
    
    :param: clientId
    :param: clientSecret
    :param: refreshToken
    :param: completionHandler
    */
    private func haloAuthenticate(refreshToken: String?, completionHandler handler: (result: Result<HaloToken, NSError>) -> Void) -> Void {
        
        let params:[String:String]
        
        if let refresh = refreshToken {
            params = [
                "grant_type" : "refresh_token",
                "client_id" : clientId!,
                "client_secret" : clientSecret!,
                "refresh_token" : refresh
            ]
        } else {
            params = [
                "grant_type" : "client_credentials",
                "client_id" : clientId!,
                "client_secret" : clientSecret!
            ]
        }
        
        alamofire.request(.POST, HaloURL.OAuth.URL, parameters: params, encoding: .URL).responseJSON { (req, resp:NSHTTPURLResponse?, json, error:NSError?) -> Void in
            
            if let jsonDict = json as? Dictionary<String,AnyObject> {
                
                self.token = HaloToken(dict: jsonDict)
                self.alamofire.session.configuration.HTTPAdditionalHeaders = ["Authorization" : "\(self.token?.tokenType) \(self.token?.token)"]
                print(jsonDict)
                handler(result: .Success(self.token!))
                
            } else {
                handler(result: .Failure(error!))
            }
        }
    }
    
    /**
    Get the list of available modules for a given client id/client secret pair
    
    :param: completionHandler   Callback executed when the request has finished
    */
    func getModules(completionHandler handler: (result: Result<[HaloModule], NSError>) -> Void) -> Void {
        
        if let token = self.token {
            
            if token.isValid() {
            
                alamofire.request(.GET, HaloURL.ModulesList.URL, parameters: nil, encoding: .URL).responseJSON(completionHandler: { (req, resp, json, error) -> Void in
                    
                    if let jsonArr = json as? [Dictionary<String,AnyObject>] {
                        let arr = self.parseModules(jsonArr)
                        handler(result:.Success(arr))
                    } else {
                        let error = NSError(domain: "halo.mobgen.com", code: -1, userInfo: nil)
                        handler(result:.Failure(error))
                        print(resp)
                        print(error)
                    }
                });
            } else {
                self.authenticate { (result) -> Void in
                    self.getModules(completionHandler: handler)
                }
            }
            
        } else {
            authenticate { (result) -> Void in
                self.getModules(completionHandler: handler)
            }
        }
    }
    
    private func parseModules(modules: [Dictionary<String,AnyObject>]) -> [HaloModule] {
        
        var modArray = [HaloModule]()
        
        for dict in modules {
            modArray.append(HaloModule(dict: dict))
        }
        
        return modArray
        
    }
    
}