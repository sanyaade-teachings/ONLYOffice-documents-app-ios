//
//  ASCNavigator.swift
//  Documents-develop
//
//  Created by Alexander Yuzhin on 21.04.2021.
//  Copyright © 2021 Ascensio System SIA. All rights reserved.
//

import UIKit

enum Destination {
    
    // MARK: - Documents
    
    case sort(types: [ASCDocumentSortStateType], ascending: Bool, complation: ASCSortViewController.ASCSortComplation?)
    case shareSettings(entity: ASCEntity)
    
    // MARK: - Login
    
    case onlyofficeConnectPortal
    case onlyofficeSignIn(portal: String?)
    case countryPhoneCodes
    
    // MARK: - Password recovery
    
    case recoveryPasswordByEmail
    case recoveryPasswordConfirmed(email: String)
    
}

final class ASCNavigator {
    
    // MARK: - Properties
    
    private weak var navigationController: UINavigationController?

    // MARK: - Initialize
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    // MARK: - Public
    
    @discardableResult
    func navigate(to destination: Destination) -> UIViewController? {
        let viewController = makeViewController(for: destination)
        
        switch destination {
        case .sort(let types, let ascending, let complation):
            if let sortViewController = viewController as? ASCSortViewController {
                sortViewController.types = types
                sortViewController.ascending = ascending
                sortViewController.onDone = complation
                let navigationVC = UINavigationController(rootASCViewController: sortViewController)
                navigationController?.present(navigationVC, animated: true, completion: nil)
            }
        case .shareSettings(let entity):
            if let sharedViewController = viewController as? ASCSharingOptionsViewController {
                let sharedNavigationVC = ASCBaseNavigationController(rootASCViewController: sharedViewController)
                
                if UIDevice.pad {
                    sharedNavigationVC.modalPresentationStyle = .formSheet
                }

                navigationController?.present(sharedNavigationVC, animated: true, completion: nil)
                sharedViewController.setup(entity: entity)
                sharedViewController.requestToLoadRightHolders()
            }
        case .onlyofficeConnectPortal:
            navigationController?.viewControllers = [viewController]
        default:
            navigationController?.pushViewController(viewController, animated: true)
        }
        
        return viewController
    }
    
    // MARK: - Private
    
    fileprivate func makeViewController(for destination: Destination) -> UIViewController {
        switch destination {
        case .sort:
            return ASCSortViewController.instance()
        case .shareSettings(let entity):
            return ASCSharingOptionsViewController(style: .grouped)
        case .onlyofficeConnectPortal:
            return ASCConnectPortalViewController.instance()
        case .onlyofficeSignIn(let portal):
            let signinViewController = ASCSignInViewController.instance()
            signinViewController.portal = portal
            return signinViewController
        case .countryPhoneCodes:
            return ASCCountryCodeViewController.instance()
        case .recoveryPasswordConfirmed(let email):
            let controller = ASCEmailSentViewController.instance()
            controller.email = email
            return controller
        case .recoveryPasswordByEmail:
            return ASCPasswordRecoveryViewController.instance()
        }
    }
    
}
