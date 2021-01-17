//
//  ExportViewControllerDelegate.swift
//  PainterDemo
//
//  Created by Oleg Taratuhin on 17.01.2021.
//

import Foundation
import UIKit

protocol ExportViewControllerDelegate: AnyObject {
    func exportViewController(_ viewController: ExportViewController,
                              didFinish: Bool,
                              withName name: String?,
                              withSize size: CGSize?)
}
