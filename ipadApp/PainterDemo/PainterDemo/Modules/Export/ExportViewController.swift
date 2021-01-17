//
//  ExportViewController.swift
//  PainterDemo
//
//  Created by Oleg Taratuhin on 17.01.2021.
//

import Foundation
import UIKit
import SwiftyUserDefaults

class ExportViewController: UIViewController {

    weak var delegate: ExportViewControllerDelegate?
    var originalSize: CGSize?

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var counterField: UITextField!

    @IBOutlet weak var dimensionsLabel: UILabel!
    @IBOutlet weak var widthField: UITextField!
    @IBOutlet weak var heightField: UITextField!

    private static func counter(for name: String) -> String {
        "\(name)_counter"
    }

    var lastSaved: String? {
        get { Defaults[\.lastSavedKey] }
        set { Defaults[\.lastSavedKey] = newValue }
    }

    var lastSavedCounter: Int {
        get { Defaults[\.lastSavedCounter] }
        set { Defaults[\.lastSavedCounter] = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        nameField.autocorrectionType = .no
        counterField.keyboardType = .numberPad
        widthField.keyboardType = .decimalPad
        heightField.keyboardType = .decimalPad

        if let exportSize = originalSize {
            dimensionsLabel.text = "\(exportSize.width) by \(exportSize.height) pts"
            widthField.text = "\(exportSize.width)"
            heightField.text = "\(exportSize.height)"
        }

        if let previousName = lastSaved {
            nameField.text = previousName
            counterField.text = String(format: "%04d", lastSavedCounter)
        }
        nameField.becomeFirstResponder()
    }

    // MARK: - Actions

    @IBAction func handleCancel(_ sender: UIButton) {

        delegate?.exportViewController(self,
                                       didFinish: false,
                                       withName: nil,
                                       withSize: nil)
    }
    
    @IBAction func handleExport(_ sender: UIButton) {

        guard let name = nameField.text,
              let specifiedWidthDouble = Double(widthField.text!),
              let specifiedHeightDouble = CDouble(heightField.text!),
              let maxSize = originalSize else { return }

        let specifiedWidth = CGFloat(specifiedWidthDouble)
        let specifiedHeight = CGFloat(specifiedHeightDouble)

        let exportWidth: CGFloat = min(specifiedWidth, maxSize.width)
        let exportHeight: CGFloat = min(specifiedHeight, maxSize.width)

        let exportSize = CGSize(width: exportWidth, height: exportHeight)

        lastSaved = name

        if let counterString = counterField.text,
           let counterInt = Int(counterString) {
            Defaults[\.lastSavedCounter] = counterInt + 1
        }

        let imageName = "\(name)-\(counterField.text ?? "0000")"

        delegate?.exportViewController(self,
                                       didFinish: true,
                                       withName: imageName,
                                       withSize: exportSize)
    }
}
