//
//  CGFloat+fromString.swift
//  PainterDemo
//
//  Created by Oleg Taratuhin on 17.01.2021.
//

import Foundation
import UIKit

extension CGFloat {

    // Adapted from:
    // https://stackoverflow.com/a/48589764

    init?(string: String?) {
        guard let numberString = string else { return nil }
        guard let number = NumberFormatter().number(from: numberString) else {
            return nil
        }

        self.init(number.floatValue)
    }
}
