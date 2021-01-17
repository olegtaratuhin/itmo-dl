//
//  ExportCounter.swift
//  PainterDemo
//
//  Created by Oleg Taratuhin on 17.01.2021.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
    var lastSavedKey: DefaultsKey<String?> { .init("lastExported") }
    var lastSavedCounter: DefaultsKey<Int> { .init("lastExportedCounter", defaultValue: 0)}
}
