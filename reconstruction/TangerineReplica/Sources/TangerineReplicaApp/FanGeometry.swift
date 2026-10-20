import CoreGraphics

enum FanGeometry {
    static let innerRadius: CGFloat = 74
    static let outerRadius: CGFloat = 178
    static let gap: Double = 0.045
    static let pageSize = 8

    static func visibleActions(_ actions: [ConversionAction], page: Int) -> [ConversionAction] {
        guard !actions.isEmpty else { return [] }
        let start = min(max(page, 0) * pageSize, max(actions.count - 1, 0))
        let end = min(start + pageSize, actions.count)
        return Array(actions[start..<end])
    }

    static func pageCount(for actions: [ConversionAction]) -> Int {
        max(1, Int(ceil(Double(actions.count) / Double(pageSize))))
    }

    static func action(
        at point: CGPoint,
        in size: CGSize,
        actions: [ConversionAction]
    ) -> ConversionAction? {
        guard !actions.isEmpty else { return nil }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance >= innerRadius, distance <= outerRadius else { return nil }

        let rawAngle = atan2(dy, dx)
        let topAngle = -Double.pi / 2
        var delta = rawAngle - topAngle
        while delta < 0 { delta += Double.pi * 2 }
        while delta >= Double.pi * 2 { delta -= Double.pi * 2 }

        let sector = (Double.pi * 2) / Double(actions.count)
        let index = min(Int(floor((delta + sector / 2) / sector)), actions.count - 1)
        let sectorCenter = Double(index) * sector
        let angularDistance = abs(normalizeAngle(delta - sectorCenter))
        guard angularDistance <= (sector / 2) - gap else { return nil }
        return actions[index]
    }

    private static func normalizeAngle(_ angle: Double) -> Double {
        var result = angle
        while result > Double.pi { result -= Double.pi * 2 }
        while result < -Double.pi { result += Double.pi * 2 }
        return result
    }
}
