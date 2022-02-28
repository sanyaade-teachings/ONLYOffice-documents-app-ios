//
//  ASCLinkedinSignInController.swift
//  Documents
//
//  Created by Лолита Чернышева on 22.02.2022.
//  Copyright © 2022 Ascensio System SIA. All rights reserved.
//

import UIKit

class ASCLinkedinSignInController: ASCConnectStorageOAuth2Delegate {
    
    var clientId: String?
    var redirectUrl: String?
    
    weak var viewController: ASCConnectStorageOAuth2ViewController? {
        didSet {
            viewController?.delegate = self
        }
    }
    
    func viewDidLoad(controller: ASCConnectStorageOAuth2ViewController) {
        let parameters: [String: String] = [
            "response_type": "code",
            "client_id": clientId ?? "",
            "redirect_uri": redirectUrl ?? "",
            "scope": "r_liteprofile",
            "response_mode": "query"
        ]
        
        let authRequest = "https://www.linkedin.com/oauth/v2/authorization?\(parameters.stringAsHttpParameters())"
        guard let url = URL(string: authRequest) else { return }
        let urlRequest = URLRequest(url: url)

        controller.load(request: urlRequest)
    }
    
    func shouldStartLoad(with request: String, in controller: ASCConnectStorageOAuth2ViewController) -> Bool {
        log.info("webview url = \(request)")
        
        if let errorCode = controller.getQueryStringParameter(url: request, param: "error") {
            log.error("code: \(errorCode)")
            controller.complation?([
                "error": String(format: NSLocalizedString("Please retry. \n\n If the problem persists contact us and mention this error code: Linkedin - %@", comment: ""), errorCode)
            ])
            return false
        }
        
        if let redirectUrl = redirectUrl, request.contains(redirectUrl),
           let code = controller.getQueryStringParameter(url: request, param: "code") {
            controller.complation?([
                "token": code
            ])
            return false
        }
        return true
    }
}

