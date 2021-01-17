//
//  CGRect+twoPoint.swift
//  PainterDemo
//
//  Created by Oleg Taratuhin on 17.01.2021.
//

import Foundation
import CoreGraphics

extension CGRect {

    init(from pointA: CGPoint, to pointB: CGPoint) {

        let origin: CGPoint
        origin = CGPoint(x: min(pointA.x, pointB.x), y: min(pointA.y, pointB.y))

        let width = abs(pointA.x - pointB.x)
        let height = abs(pointA.y - pointB.y)

        self.init(x: origin.x, y: origin.y, width: width, height: height)
    }
}
