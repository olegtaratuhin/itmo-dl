//
//  PainterViewController.swift
//  PainterDemo
//
//  Created by Oleg Taratuhin on 17.01.2021.
//

//
// This file contains code from official pencil demo session
//

import Foundation


import UIKit
import PencilKit

class SketchViewController: UIViewController,
                            PKCanvasViewDelegate,
                            PKToolPickerObserver,
                            ExportViewControllerDelegate {

    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!

    var dragStartPoint: CGPoint?
    var dragEndPoint: CGPoint?
    var selectedRect: CGRect?
    var selectedView = SelectionView()

    func drawImageOnCanvas(_ useImage: UIImage, canvasSize: CGSize, canvasColor: UIColor ) -> UIImage {
        let rect = CGRect(origin: .zero, size: canvasSize)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)

        // fill the entire image
        canvasColor.setFill()
        UIRectFill(rect)

        // calculate a Rect the size of the image to draw, centered in the canvas rect
        let centeredImageRect = CGRect(x: (canvasSize.width - useImage.size.width) / 2,
                                       y: (canvasSize.height - useImage.size.height) / 2,
                                       width: useImage.size.width,
                                       height: useImage.size.height)
        // get a drawing context
        let context = UIGraphicsGetCurrentContext();

        // "cut" a transparent rectanlge in the middle of the "canvas" image
        context?.clear(centeredImageRect)

        // draw the image into that rect
        useImage.draw(in: centeredImageRect)

        // get the new "image in the center of a canvas image"
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        canvasView.delegate = self

        // Set as false by default, to support drag to export gesture
        // Consider having this as a toggle for an export-selection mode?
//        canvasView.allowsFingerDrawing = false
        canvasView.drawingPolicy = .pencilOnly

        let panRecognizer = UIPanGestureRecognizer(target: self,
                                                   action: #selector(handlePanGesture))
        canvasView.addGestureRecognizer(panRecognizer)

        canvasView.isOpaque = true
        canvasView.backgroundColor = .white

        canvasView.drawing = PKDrawing()

        if let img = UIImage(named: "simple_paint_by_numbers") {
            let expandedSize = CGSize(width: img.size.width + 60, height: img.size.height + 60)
            let imageOnBlueCanvas = drawImageOnCanvas(img, canvasSize: expandedSize, canvasColor: .white)
            let v = UIImageView(image: imageOnBlueCanvas)
            canvasView.addSubview(v)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Adapted from PencilKitDraw sample code's viewWillAppear
        let toolPicker = PKToolPicker()

        if (view?.window) != nil {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)
            
            canvasView.becomeFirstResponder()
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func handleSaveTapped(_ sender: UIButton) {
        print("Save Tapped")
    }
    
    /// Export the entire canvas to a PNG file
    ///
    /// This is an alternative to the drag gesture, which will export a sub-rect of the canvas.
    @IBAction func handleExportTapped(_ sender: UIButton) {
        // TODO: customize this name by prompting for a name, and adding a timestamp
        export(rect: canvasView.bounds,
               filename: UUID().uuidString,
               sizeSuffix: "@2x",
               scale: UIScreen.main.scale)
    }
    
    /// Export the specified rect to a PNG file, at the specified scale.
    func export(rect: CGRect, filename: String, sizeSuffix: String, scale: CGFloat) {
        let drawingImage = canvasView.drawing.image(from: rect, scale: scale)
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let filePath = paths.first!.appendingPathComponent("\(filename)\(sizeSuffix).png")
        
        if let data = drawingImage.pngData() {
            do {
                try data.write(to: filePath)
            } catch {
                print("Failed to save: \(error)")
            }
        }
    }

    func exportAllSizes(rect: CGRect, filename: String, scale: CGFloat) {
        let at3xScale = (scale * 1.5) / UIScreen.main.scale

        if let oSize = selectedRect?.size,
           oSize.width >= rect.width * at3xScale,
           oSize.height >= rect.height * at3xScale {
            
            export(rect: rect, filename: filename, sizeSuffix: "@3x", scale: scale * 1.5)
        }

        export(rect: rect, filename: filename, sizeSuffix: "@2x", scale: scale)
        export(rect: rect, filename: filename, sizeSuffix: "@1x", scale: scale / 2.0)
    }

    @objc func handlePanGesture(gr: UIPanGestureRecognizer) {
        if gr.state == .began {
            dragStartPoint = gr.location(in: canvasView)
            //print(dragStartPoint)
        }

        if gr.state == .changed {
            if let startPoint = dragStartPoint {
                if selectedView.superview == nil {
                    canvasView.addSubview(selectedView)
                }

                selectedView.frame = CGRect(from: startPoint, to: gr.location(in: canvasView))
            }
        }
        
        if gr.state == .failed {
            clearExportSelection()
        }
        
        if gr.state == .ended {
            guard let startPoint = dragStartPoint else { return }
            dragEndPoint = gr.location(in: canvasView)
            selectedRect = CGRect(from: startPoint, to: dragEndPoint!)
            print("Drag rect: \(String(describing: selectedRect))")
            guard let exportVC = storyboard?.instantiateViewController(withIdentifier: "ExportViewController") as? ExportViewController else { return }
            exportVC.delegate = self
            exportVC.originalSize = selectedRect?.size
            exportVC.modalPresentationStyle = .formSheet
            present(exportVC, animated: true)
        }
    }

    func clearExportSelection() {

        dragStartPoint = nil
        dragEndPoint = nil
        selectedRect = nil

        selectedView.frame = .zero
        selectedView.removeFromSuperview()
    }

    // MARK: - PKCanvasViewDelegate

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        //hasModifiedDrawing = true
        print("Drawing Changed")
    }

    // MARK: - PKToolPickerObserver

    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        print("Frame obscured by tools changed")
    }

    /// Delegate method: Note that the tool picker has become visible or hidden.
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        print("Tool visibility changed")
    }

    // MARK: - ExportViewControllerDelegate

    func exportViewController(_ exportVC: ExportViewController, didFinish: Bool, withName name: String?, withSize size: CGSize?) {
        dismiss(animated: true)

        guard let exportRect = selectedRect else { return }
        if didFinish, let exportName = name, let exportSize = size {
            print("Exporting \(exportRect) to \(exportName).png at \(exportSize)")
            let exportScale = (exportSize.width / exportRect.width) * UIScreen.main.scale
            exportAllSizes(rect: exportRect, filename: exportName, scale: exportScale)
        }
        clearExportSelection()
    }
}

