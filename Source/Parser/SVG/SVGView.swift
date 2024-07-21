//
//  SVGView.swift
//  SVGView
//
//  Created by Alisa Mylnikova on 20/08/2020.
//

import SwiftUI

public struct SVGView: View {

    public let svg: SVGNode?

    public init(contentsOf url: URL) {
        self.svg = SVGParser.parse(contentsOf: url)
    }

    @available(*, deprecated, message: "Use (contentsOf:) initializer instead")
    public init(fileURL: URL) {
        self.svg = SVGParser.parse(contentsOf: fileURL)
    }

    public init(data: Data) {
        self.svg = SVGParser.parse(data: data)
    }

    public init(string: String) {
        self.svg = SVGParser.parse(string: string)
    }

    public init(stream: InputStream) {
        self.svg = SVGParser.parse(stream: stream)
    }

    public init(xml: XMLElement) {
        self.svg = SVGParser.parse(xml: xml)
    }

    public init(svg: SVGNode) {
        self.svg = svg
    }

    public func getNode(byId id: String) -> SVGNode? {
        return svg?.getNode(byId: id)
    }

    public var body: some View {
        svg?.toSwiftUI()
    }
}

extension SVGView {
    public init?(
        contentsOf: URL,
        sizeToFit: CGSize? = nil,
        tapGesture: @escaping () -> ()
    ) {
        let node = SVGParser.parse(contentsOf: contentsOf)
        
        guard let node else {
            return nil
        }
        
        guard let viewPort = node as? SVGViewport else {
            return nil
        }
        
        if let sizeToFit = sizeToFit, let viewBox = viewPort.viewBox {
            let newViewBox = CGRect(origin: .zero, size: sizeToFit)
            let t = viewBox.transform(toFit: newViewBox)
            
            node.iterate(transform: t, newViewBox: newViewBox)
        }
        
        let allNodes = node.getAllChildren()
        for node in allNodes {
            node.onTapGesture {
                tapGesture()
            }
        }
        
        self.init(svg: node)
    }
}

extension SVGNode {
    func getAllChildren() -> [SVGNode] {
        var res = [SVGNode]()
        self.getAllChildrenRec(res: &res)
        
        return res
    }
    
    private func getAllChildrenRec(res: inout [SVGNode]) {
        if let group = self as? SVGGroup {
            for item in group.contents {
                item.getAllChildrenRec(res: &res)
            }
        } else {
            res.append(self)
        }
    }
}


extension SVGNode {
    func iterate(transform: CGAffineTransform, newViewBox: CGRect) {
        self.originTransform = transform
        switch self {
        case let viewPort as SVGViewport:
            viewPort.viewBox = newViewBox
            for item in viewPort.contents {
                item.iterate(transform: transform, newViewBox: newViewBox)
            }
        case let group as SVGGroup:
            for item in group.contents {
                item.iterate(transform: transform, newViewBox: newViewBox)
            }
            
        default:
            break
        }
    }
}

extension CGRect {
    // TODO: Add other ratios if needed
    func transform(toFit rectToFit: CGRect) -> CGAffineTransform {
        guard self.origin != .zero else { return .identity }
        
        let t = self.aspectFitTransform(toFit: rectToFit)
        
        return t
    }
    
    func aspectFitTransform(toFit targetRect: CGRect) -> CGAffineTransform {

        let scaleX = targetRect.width / self.width
        let scaleY = targetRect.height / self.height
        let scale = min(scaleX, scaleY)
        
        let transformedWidth = self.width * scale
        let transformedHeight = self.height * scale
        
        let translateX = (targetRect.width - transformedWidth) / 2.0
        let translateY = (targetRect.height - transformedHeight) / 2.0
        
        let transform = CGAffineTransform(translationX: -self.minX, y: -self.minY) // Aligning origin
            .concatenating( // Scaling is happening around the canter, so we need compensate offset
                CGAffineTransform(
                    translationX: translateX,
                    y: translateY
                )
                .scaledBy(x: scale, y: scale)
            )
        
        return transform
    }
}

extension SVGPolygon {
    func applyInitial(transform: CGAffineTransform) {
        let transformed = points.map { $0.applying(transform) }
        self.points = transformed
    }
}

extension SVGPath {
    func applyInitial(transform: CGAffineTransform) {
        let segments = self.segments
    }
}


