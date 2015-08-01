//
//  Networking.swift
//  MoMOSFramework
//
//  Created by Borja Santos-Díez on 17/06/15.
//  Copyright (c) 2015 MOBGEN Technology. All rights reserved.
//

import Foundation
import Alamofire

/// Module encapsulating all the networking features of the Framework
class Networking {

    private let alamofire = Alamofire.Manager.sharedInstance

    /// Singleton instance of the networking component
    static let sharedInstance = Halo.Networking()

    /// Client id to be used for authentication throughout the SDK
    var clientId: String?

    /// Client secret to be used for authentication throughout the SDK
    var clientSecret: String?

    /**
    Authenticate against the HALO backend using a client id and a client secret

    - parameter completionHandler:  Closure where the response from the server can be processed
    */
    func authenticate(completionHandler handler: (result: Alamofire.Result<Halo.Token>) -> Void) -> Void {

        if let haloToken = Router.token {
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
    Internal call to the authentication process. If a refresh token is provided, then the existing
    token is refreshed. Otherwise, a fresh one is requested

    - parameter refreshToken:       Refresh token (if any)
    - parameter completionHandler:  Closure to be executed once the request has finished
    */
    private func haloAuthenticate(refreshToken: String?, completionHandler handler: (result: Alamofire.Result<Halo.Token>) -> Void) -> Void {

        let params:[String: String]

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

        alamofire.request(Router.OAuth(params)).responseJSON { (_, _, result) -> Void in

            switch result {
            case .Success(let data):
                let token = Halo.Token(dict: data as! Dictionary<String,AnyObject>)
                Router.token = token
                handler(result: .Success(token))
            case .Failure(let data, let err):
                handler(result: .Failure(data, err))
            }
        }
    }

    /**
    Get the list of available modules for a given client id/client secret pair

    - parameter completionHandler:  Closure to be executed once the request has finished
    */
    func getModules(completionHandler handler: (result: Alamofire.Result<[Halo.HaloModule]>) -> Void) -> Void {

        if let tok = Router.token {

            if tok.isValid() {

                alamofire.request(Router.Modules).responseJSON(completionHandler: { (_, _, result) -> Void in

                    switch result {
                    case .Success(let data):
                        let arr = self.parseModules(data as! [Dictionary<String,AnyObject>])
                        handler(result: .Success(arr))
                    case .Failure(_, let error):
                        print("Error: \(error.localizedDescription)")
                    }

                });
            } else {
                self.authenticate { (result) -> Void in
                    switch (result) {
                    case .Success(_):
                        self.getModules(completionHandler: handler)
                    case .Failure(_, let err):
                        print("Error: \(err.localizedDescription)")
                    }
                }
            }

        } else {
            authenticate { (result) -> Void in
                switch (result) {
                case .Success(_) :
                    self.getModules(completionHandler: handler)
                case .Failure(_, let err):
                    print("Error: \(err.localizedDescription)")
                }
            }
        }
    }

    func getModuleInstances(internalId: String, completionHandler handler: (Alamofire.Result<[Dictionary<String, AnyObject>]>) -> Void) -> Void {
        
    }
    
    /**
    Parse a list of dictionaries (from the JSON response) into a list of modules
    
    - parameter modules:     List of dictionaries coming from the JSON response
    
    - returns   The list of the parsed modules
    */
    private func parseModules(modules: [Dictionary<String,AnyObject>]) -> [HaloModule] {

        var modArray = [HaloModule]()

        for dict in modules {
            modArray.append(HaloModule(dict: dict))
        }

        return modArray
    }
}