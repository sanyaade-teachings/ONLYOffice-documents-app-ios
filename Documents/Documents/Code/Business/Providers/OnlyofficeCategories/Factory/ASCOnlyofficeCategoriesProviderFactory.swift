//
//  ASCOnlyofficeCategoriesProviderFactory.swift
//  Documents
//
//  Created by Павел Чернышев on 22.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import Foundation

class ASCOnlyofficeCategoriesProviderFactory {
    
    private var isServerVersionEstablished = false
    private lazy var provider: ASCOnlyofficeCategoriesProviderProtocol = ASCOnlyofficeAppBasedCategoriesProvider()
    
    func get() -> ASCOnlyofficeCategoriesProviderProtocol {
        guard isServerVersionEstablished else {
            guard let communityServerVersion = ASCOnlyOfficeApi.shared.serverVersion else {
                return provider
            }
            isServerVersionEstablished = true
            guard communityServerVersion.isVersion(greaterThanOrEqualTo: "11.5") else {
                return provider
            }
            provider = ASCOnlyofficeAPICategoriesProvider()
            return provider
        }
        
        return provider
    }
}