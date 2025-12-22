//
//  ConnectionLine.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let type: NetworkConnection.ConnectionType
    var isTestMode: Bool = false // Test mode - narančasta boja
    var fromPin: ConnectionPoint? = nil // Pin s kojeg linija počinje
    var toPin: ConnectionPoint? = nil // Pin na koji linija ide
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Prvo provjeri je li linija ravna (horizontalna ili vertikalna)
            let dx = to.x - from.x
            let dy = to.y - from.y
            let isHorizontal = abs(dy) < 5.0
            let isVertical = abs(dx) < 5.0
            
            // Ako je linija ravna, nacrtaj je kao ravnu liniju (bez krivulja)
            if isHorizontal || isVertical {
                path.addLine(to: to)
            } else {
                // Provjeri kategorije pinova
                let fromCategory = getPinCategory(fromPin)
                let toCategory = getPinCategory(toPin)
                
                // Ako su oba pina iste kategorije (horizontalni ili vertikalni) → S-krivulja
                // Ako su različite kategorije → luk od 90°
                if fromCategory == toCategory && fromCategory != .unknown {
                    // Ista kategorija - S-krivulja (2 obrnute parabole)
                    let controlPoints = calculateSCurvePoints(from: from, to: to)
                    path.addCurve(
                        to: to,
                        control1: controlPoints.control1,
                        control2: controlPoints.control2
                    )
                } else if fromCategory != toCategory && fromCategory != .unknown && toCategory != .unknown {
                    // Različite kategorije - ravne linije i veliki polukrug
                    draw90DegreeArcWithSemicircle(path: &path, from: from, to: to, fromPin: fromPin, toPin: toPin)
                } else {
                    // Fallback - S-krivulja za dijagonalne linije
                    let controlPoints = calculateSCurvePoints(from: from, to: to)
                    path.addCurve(
                        to: to,
                        control1: controlPoints.control1,
                        control2: controlPoints.control2
                    )
                }
            }
        }
        .stroke(lineColor, style: strokeStyle)
    }
    
    // Kategorije pinova
    private enum PinCategory {
        case horizontal // left, right (0°, 180°)
        case vertical   // top, bottom (90°, 270°)
        case unknown
    }
    
    // Odredi kategoriju pina
    private func getPinCategory(_ pin: ConnectionPoint?) -> PinCategory {
        guard let pin = pin else { return .unknown }
        switch pin {
        case .left, .right:
            return .horizontal
        case .top, .bottom:
            return .vertical
        }
    }
    
    // Izračunaj kontrolne točke za S-krivulju (2 obrnute parabole) - ista kategorija pinova
    private func calculateSCurvePoints(from: CGPoint, to: CGPoint) -> (control1: CGPoint, control2: CGPoint) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = sqrt(dx * dx + dy * dy)
        let curvature: CGFloat = 0.7 // Povećana jačina krivulje za naglašeniji S-oblik (sa 0.5 na 0.7)
        
        // Vektor okomit na glavnu liniju
        let perpendicularX = -dy / distance
        let perpendicularY = dx / distance
        
        // Pomakni kontrolne točke okomito na glavnu liniju (obrnuto za S-oblik)
        let offset = distance * curvature * 0.4 // Povećano sa 0.3 na 0.4 za naglašeniji polukrug
        
        // Prva kontrolna točka (blizu početka)
        let control1X = from.x + dx * 0.3 + perpendicularX * offset
        let control1Y = from.y + dy * 0.3 + perpendicularY * offset
        
        // Druga kontrolna točka (blizu kraja, obrnuto pomaknuta za S-oblik)
        let control2X = from.x + dx * 0.7 - perpendicularX * offset
        let control2Y = from.y + dy * 0.7 - perpendicularY * offset
        
        return (
            control1: CGPoint(x: control1X, y: control1Y),
            control2: CGPoint(x: control2X, y: control2Y)
        )
    }
    
    // Nacrtaj 2 ravne linije sa zaobljenim kutom za 90° konekcije (kroz sjecište)
    private func draw90DegreeArcWithSemicircle(path: inout Path, from: CGPoint, to: CGPoint, fromPin: ConnectionPoint?, toPin: ConnectionPoint?) {
        guard let fromPin = fromPin, let toPin = toPin else {
            // Fallback - ravna linija
            path.addLine(to: to)
            return
        }
        
        // Kreiraj 2 zamišljene linije i pronađi sjecište
        var horizontalLineY: CGFloat? = nil
        var verticalLineX: CGFloat? = nil
        
        // Odredi prvu zamišljenu liniju na temelju fromPin
        switch fromPin {
        case .left, .right:
            horizontalLineY = from.y
        case .top, .bottom:
            verticalLineX = from.x
        }
        
        // Odredi drugu zamišljenu liniju na temelju toPin
        switch toPin {
        case .left, .right:
            horizontalLineY = to.y
        case .top, .bottom:
            verticalLineX = to.x
        }
        
        guard let hY = horizontalLineY, let vX = verticalLineX else {
            // Fallback - ravna linija
            path.addLine(to: to)
            return
        }
        
        let intersection = CGPoint(x: vX, y: hY)
        
        // Izračunaj udaljenosti za određivanje radijusa zaobljenja
        let distFromToIntersection = sqrt(pow(from.x - intersection.x, 2) + pow(from.y - intersection.y, 2))
        let distToToIntersection = sqrt(pow(to.x - intersection.x, 2) + pow(to.y - intersection.y, 2))
        
        // Odredi koja je linija kraća
        let isFirstLineShorter = distFromToIntersection < distToToIntersection
        let shorterDistance = min(distFromToIntersection, distToToIntersection)
        
        // Radijus zaobljenja - duplo veći (70% kraće linije)
        let cornerRadius = shorterDistance * 0.70
        
        // Odredi točke prije i poslije sjecišta za zaobljenje
        let dx1 = intersection.x - from.x
        let dy1 = intersection.y - from.y
        let dist1 = sqrt(dx1 * dx1 + dy1 * dy1)
        let normalizedDx1 = dist1 > 0 ? dx1 / dist1 : 0
        let normalizedDy1 = dist1 > 0 ? dy1 / dist1 : 0
        
        let dx2 = to.x - intersection.x
        let dy2 = to.y - intersection.y
        let dist2 = sqrt(dx2 * dx2 + dy2 * dy2)
        let normalizedDx2 = dist2 > 0 ? dx2 / dist2 : 0
        let normalizedDy2 = dist2 > 0 ? dy2 / dist2 : 0
        
        // Odredi točke zaobljenja ovisno o tome koja je linija kraća
        let beforeIntersection: CGPoint
        let afterIntersection: CGPoint
        
        if isFirstLineShorter {
            // Prva linija je kraća - zaobljenje počinje nakon 70% prve linije (duplo veći)
            let startOffset = dist1 * 0.70
            beforeIntersection = CGPoint(
                x: from.x + normalizedDx1 * startOffset,
                y: from.y + normalizedDy1 * startOffset
            )
            
            // Zaobljenje završava na odgovarajućoj poziciji na drugoj liniji (jednak radijus)
            afterIntersection = CGPoint(
                x: intersection.x + normalizedDx2 * cornerRadius,
                y: intersection.y + normalizedDy2 * cornerRadius
            )
        } else {
            // Druga linija je kraća - zaobljenje počinje na odgovarajućoj poziciji na prvoj liniji
            beforeIntersection = CGPoint(
                x: intersection.x - normalizedDx1 * cornerRadius,
                y: intersection.y - normalizedDy1 * cornerRadius
            )
            
            // Zaobljenje završava nakon 70% druge linije (duplo veći)
            let endOffset = dist2 * 0.70
            afterIntersection = CGPoint(
                x: intersection.x + normalizedDx2 * endOffset,
                y: intersection.y + normalizedDy2 * endOffset
            )
        }
        
        // Nacrtaj ravnu liniju od from do početka zaobljenja
        path.addLine(to: beforeIntersection)
        
        // Nacrtaj zaobljeni kut koristeći kontrolne točke
        // Kontrolne točke su na sjecištu za glatki prijelaz
        path.addCurve(
            to: afterIntersection,
            control1: intersection,
            control2: intersection
        )
        
        // Nacrtaj ravnu liniju od kraja zaobljenja do to
        path.addLine(to: to)
    }
    
    // All connections are gray initially, narančasta u test modu
    private var lineColor: Color {
        if isTestMode {
            return Color(red: 1.0, green: 0.36, blue: 0.0) // Narančasta boja
        }
        return Color.gray
    }
    
    private var strokeStyle: StrokeStyle {
        switch type {
        case .wireless:
            return StrokeStyle(lineWidth: 4, dash: [5, 5])
        default:
            return StrokeStyle(lineWidth: 4)
        }
    }
}

