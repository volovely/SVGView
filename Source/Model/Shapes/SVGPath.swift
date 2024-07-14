import SwiftUI
import Combine

public class SVGPath: SVGShape, ObservableObject {

    @Published public var segments: [PathSegment]
    @Published public var fillRule: CGPathFillRule

    public init(segments: [PathSegment] = [], fillRule: CGPathFillRule = .winding) {
        self.segments = segments
        self.fillRule = fillRule
    }

    override public func frame() -> CGRect {
        toBezierPath().cgPath.boundingBox
    }

    override public func bounds() -> CGRect {
        frame()
    }

    override func serialize(_ serializer: Serializer) {
        let path = segments.map { s in "\(s.type)\(s.data.compactMap { $0.serialize() }.joined(separator: ","))" }.joined(separator: " ")
        serializer.add("path", path)
        serializer.add("fillRule", fillRule)
        super.serialize(serializer)
    }

    public func contentView() -> some View {
        SVGPathView(model: self)
    }
}

struct SVGPathView: View {

    @ObservedObject var model = SVGPath()

    public var body: some View {
        model.toBezierPath().toSwiftUI(model: model, eoFill: model.fillRule == .evenOdd)
    }
}

extension MBezierPath: @unchecked Sendable {
    
}

extension CGFloat: @unchecked Sendable {
    
}

struct SVGPathShapeView: Shape {
    let path: MBezierPath
    
    func path(in rect: CGRect) -> Path {
        let pathBounds = path.cgPath.boundingBox
        
        let scaleFactor: CGFloat
        if pathBounds.size.isLandscape {
            scaleFactor = rect.width / pathBounds.size.width
        } else {
            scaleFactor = rect.height / pathBounds.size.height
        }
        
        let T = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        path.apply(T)
        
        return Path(path.cgPath)
    }
}

extension CGSize {
    var isPortrait: Bool {
        width < height
    }
    
    var isLandscape: Bool {
        !isPortrait
    }
}

extension MBezierPath {

    func toSwiftUI(model: SVGShape, eoFill: Bool = false) -> some View {
        let isGradient = model.fill is SVGGradient
        let bounds = isGradient ? model.bounds() : CGRect.zero
        return SVGPathShapeView(path: self)
            .applySVGStroke(stroke: model.stroke, eoFill: eoFill)
            .applyShapeAttributes(model: model)
            .applyIf(isGradient) {
                $0.frame(width: bounds.width, height: bounds.height)
                    .position(x: 0, y: 0)
                    .offset(x: bounds.width/2, y: bounds.height/2)
            }
    }
}

