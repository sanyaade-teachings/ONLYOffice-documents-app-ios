//
//  CenteredLabelHeaderView.swift
//  Documents-opensource
//
//  Created by Lolita Chernysheva on 17.05.2024.
//  Copyright © 2024 Ascensio System SIA. All rights reserved.
//

import UIKit

class CenteredLabelHeaderView: UIView {
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(headerLabel)

        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(with text: String, backgroundColor: UIColor?) {
        headerLabel.text = text
        headerLabel.backgroundColor = backgroundColor
    }
}
