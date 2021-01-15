import Combine
import CreateML
import Foundation
import PlaygroundSupport
import SwiftUI

// MARK: Setup

let bundle = Bundle.main

let rootPath = URL(fileURLWithPath: "Users/olegtaratuhin/Code/itmo/semester3/DL/itmo-dl/models/DIY/AppleML")
let experimentsPath = URL(fileURLWithPath: "experiments", isDirectory: true, relativeTo: rootPath)

let rootPath = URL(fileURLWithPath: "Users/olegtaratuhin/Code/itmo/semester3/DL/itmo-dl/models/data")
let dataPath = URL(fileURLWithPath: "data", isDirectory: true, relativeTo: rootPath)

let stylePath = URL(fileURLWithPath: "style-images", relativeTo: dataPath)
let samplePath = URL(fileURLWithPath: "sample-images", relativeTo: dataPath)
let contentPath = URL(fileURLWithPath: "content-images", relativeTo: dataPath)

let styleImageURL = URL(
    fileURLWithPath: "paint_4.jpg",
    isDirectory: false,
    relativeTo: stylePath
)

let sampleImageURL = URL(
    fileURLWithPath: "faces/real_01075.jpg",
    isDirectory: false,
    relativeTo: samplePath
)

let trainingData = MLStyleTransfer.DataSource.images(
    styleImage: styleImageURL,
    contentDirectory: contentPath,
    processingOption: .scaleFit
)

let style = NSImage(byReferencing: styleImageURL)
let sample = NSImage(byReferencing: sampleImageURL)

let iterations = 100
let progressInterval = 5
let checkpointInterval = 25

// MARK: Expirements ID

let experimentID = "0005"
let sessionDirectory = URL(
    fileURLWithPath: experimentID,
    isDirectory: true,
    relativeTo: experimentsPath
)

// MARK: Session parameters

let sessionParameters = MLTrainingSessionParameters(
    sessionDirectory: sessionDirectory,
    reportInterval: progressInterval,
    checkpointInterval: checkpointInterval,
    iterations: iterations
)

// MARK: Training parameters

let maxIterations = iterations
let textelDensity = 416
let styleStrength = 5

let trainingParameters = MLStyleTransfer.ModelParameters(
    algorithm: .cnnLite,
    validation: .content(sampleImageURL),
    maxIterations: maxIterations,
    textelDensity: 416,
    styleStrength: styleStrength
)

// MARK: Training job

var subsriptions: [AnyCancellable] = []

let trainingJob = try MLStyleTransfer.train(
    trainingData: trainingData,
    parameters: trainingParameters,
    sessionParameters: sessionParameters
)

// MARK: Training job publisher

trainingJob.result.sink { result in
    print(result)
}
receiveValue: { model in
    try? model.write(to: sessionDirectory)
}
.store(in: &subsriptions)

// MARK: Training monitoring

trainingJob.progress.publisher(for: \.fractionCompleted).sink { completed in
    _ = completed

    guard let progress = MLProgress(progress: trainingJob.progress) else { return }
    if let styleLoss = progress.metrics[.styleLoss] { _ = styleLoss }
    if let contentLoss = progress.metrics[.contentLoss] { _ = contentLoss }
}
.store(in: &subsriptions)


//// MARK: Stop
//
//trainingJob.cancel()
//
//// MARK: Resume
//
//let resumedJob = try MLStyleTransfer.train(
//    trainingData: trainingData,
//    parameters: trainingParameters,
//    sessionParameters: sessionParameters
//)

// MARK: Checkpoints

trainingJob.checkpoints
    .compactMap { $0.metrics[.stylizedImageURL] as? URL }
    .map { NSImage(byReferencing: $0) }
    .sink { image in
        let _ = image

        let view = VStack {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            Image(nsImage: style).resizable().aspectRatio(contentMode: .fit)
            Image(nsImage: sample).resizable().aspectRatio(contentMode: .fit)
        }.frame(maxHeight: 1400)

        PlaygroundSupport.PlaygroundPage.current.setLiveView(view)
    }
    .store(in: &subsriptions)
