//
//  EditSharedLinkView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 05.06.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import SwiftUI

struct EditSharedLinkView: View {
    @ObservedObject var viewModel: EditSharedLinkViewModel

    var body: some View {
        List {
            generalSection
            typeSection
        }
        .navigationBarTitle(Text(NSLocalizedString("Shared link", comment: "")), displayMode: .inline)
    }

    @ViewBuilder
    private var generalSection: some View {
        Section(
            header: Text(NSLocalizedString("General", comment: "")))
        {
            accessCell
            linkLifeTimeCell
        }
    }

    private var accessCell: some View {
        MenuView(menuItems: viewModel.accessMenuItems) {
            ASCDetailedChevronUpDownCellView(model: ASCDetailedChevronUpDownCellViewModel(
                title: NSLocalizedString("Access rights", comment: ""),
                detail: viewModel.selectedAccessRight.title()
            ))
        }
    }

    private var linkLifeTimeCell: some View {
        MenuView(menuItems: viewModel.linkLifeTimeMenuItems) {
            ASCDetailedChevronUpDownCellView(model: ASCDetailedChevronUpDownCellViewModel(
                title: NSLocalizedString("Link life time", comment: ""),
                detail: ""
            ))
        }
    }

    @ViewBuilder
    private var typeSection: some View {
        Section(
            header: Text(NSLocalizedString("Type", comment: "")))
        {
            CheckmarkCellView(model: CheckmarkCellViewModel(
                text: NSLocalizedString("Anyone with the link", comment: ""),
                isChecked: viewModel.linkAccess == .anyoneWithLink,
                onTapAction: {
                    if viewModel.linkAccess == .docspaceUserOnly {
                        viewModel.setLinkType()
                    } else {
                        return
                    }
                }
            ))
            CheckmarkCellView(model: CheckmarkCellViewModel(
                text: NSLocalizedString("DoсSpace users only", comment: ""),
                isChecked: viewModel.linkAccess == .docspaceUserOnly,
                onTapAction: {
                    if viewModel.linkAccess == .anyoneWithLink {
                        viewModel.setLinkType()
                    } else {
                        return
                    }
                }
            ))
        }
    }
}
