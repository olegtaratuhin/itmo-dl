//
//  SelectionView.swift
//  PainterDemo
//
//  Created by Oleg Taratuhin on 17.01.2021.
//

import Foundation

import UIKit

class SelectionView: UIView {
    var borderColor: CGColor = CGColor(srgbRed: 1.0, green: 0.0, blue: 0.0, alpha: 0.8)

    init(borderColor bc: UIColor) {
        borderColor = bc.cgColor
        super.init(frame: .zero)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setup()
    }

    private func setup() {
        layer.borderColor = borderColor
        layer.borderWidth = 1.0
        backgroundColor = .clear
        layer.masksToBounds = true
    }
}
