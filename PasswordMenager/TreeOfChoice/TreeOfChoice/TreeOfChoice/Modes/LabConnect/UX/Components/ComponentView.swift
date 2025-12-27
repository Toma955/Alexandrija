//
//  ComponentView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI

struct ComponentView: View {
    @ObservedObject var component: NetworkComponent
    @ObservedObject var topology: NetworkTopology
    @ObservedObject var simulation: NetworkSimulation
    let geometry: GeometryProxy
    let hoveredPoint: ConnectionPoint?
    let isTestMode: Bool
    let onTap: (NetworkComponent) -> Void
    let onDrag: (NetworkComponent, CGPoint) -> Void
    let onConnectionDragStart: (NetworkComponent, CGPoint, CGPoint) -> Void
    let onConnectionDragUpdate: ((CGPoint) -> Void)?
    let onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)?
    let onDragUpdate: ((NetworkComponent, CGPoint) -> Void)?
    let onDelete: ((NetworkComponent) -> Void)?
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var dragStartAbsoluteX: CGFloat = 0 // Fiksna početna X pozicija za drag
    @State private var dragStartAbsoluteY: CGFloat = 0 // Fiksna početna Y pozicija za drag
    @State private var draggingConnection: Bool = false
    @State private var pinClickStarted: Bool = false // Provjera da se pinClick pozove samo jednom
    @State private var isResizingArea: Bool = false
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartAbsoluteX: CGFloat = 0 // Fiksna apsolutna X pozicija tijekom resize-a
    @State private var resizeStartAbsoluteY: CGFloat = 0 // Fiksna apsolutna Y pozicija tijekom resize-a
    @State private var resizeAnchorPoint: CGPoint? = nil // Apsolutna pozicija anchor pointa (suprotni kut/stranica)
    @State private var finalAreaCenter: CGPoint? = nil // Finalni centar area kvadrata nakon resize-a
    @State private var resizeCorner: AreaResizeCorner? = nil
    @State private var resizeEdge: AreaResizeEdge? = nil
    @State private var draggingHandlePosition: CGPoint? = nil // Pozicija strelice koja se vuče (prati miš)
    @State private var dragStartAreaCenter: CGPoint? = nil // Početni areaCenter prije početka drag-a crnog kvadrata
    @State private var mouseLocation: CGPoint? = nil // Lokacija miša za prikaz najbliže strelice
    
    enum AreaResizeCorner {
        case topRight, bottomRight, bottomLeft, topLeft
    }
    
    enum AreaResizeEdge {
        case top, right, bottom, left
    }
    
    var body: some View {
        // Koristi fiksnu početnu poziciju tijekom drag-a, inače računaj iz component.position
        let absoluteX = isDragging ? dragStartAbsoluteX : calculateAbsoluteX()
        let absoluteY = isDragging ? dragStartAbsoluteY : calculateAbsoluteY()
        // Ne koristi determineIconColor() - BaseComponentTopologyView koristi logiku iz BaseTopologyElement
        // iconColor se ne prosljeđuje jer BaseComponentTopologyView ignorira taj parametar
        let iconColor: Color? = nil // Ne prosljeđuj iconColor - koristi se logika iz BaseTopologyElement
        let isAreaComponent = component.componentType == .userArea ||
                             component.componentType == .businessArea ||
                             component.componentType == .businessPrivateArea ||
                             component.componentType == .nilterniusArea
        
        return ZStack {
            // Isprekidani narančasti kvadrat za area komponente
            if isAreaComponent {
                let areaWidth = component.areaWidth ?? 120
                let areaHeight = component.areaHeight ?? 120
                // Default: siva boja (kao i ikone)
                let areaColor = component.customColor ?? Color.gray
                
                // Koristi fiksnu poziciju tijekom drag-a za area center
                let areaAbsoluteX = isDragging ? dragStartAbsoluteX : absoluteX
                let areaAbsoluteY = isDragging ? dragStartAbsoluteY : absoluteY
                let areaCenter = calculateAreaCenter(
                    absoluteX: areaAbsoluteX + (isDragging ? dragOffset.width : 0),
                    absoluteY: areaAbsoluteY + (isDragging ? dragOffset.height : 0),
                    areaWidth: areaWidth,
                    areaHeight: areaHeight
                )
                
                ZStack {
                    // Isprekidani kvadrat - koristi abs() samo za prikaz, ali zadrži originalnu vrijednost u modelu
                    // KLJUČNO: allowsHitTesting(false) da ne blokira klikove na button-u
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(areaColor, style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .frame(width: abs(areaWidth), height: abs(areaHeight))
                        .allowsHitTesting(false) // Ne hvataj klikove - button mora biti klikabilan
                    
                    // Strelice na kutovima
                    if isResizingArea, let corner = resizeCorner, let dragPos = draggingHandlePosition {
                        // Prikaži strelicu koja se vuče na poziciji miša
                        areaResizeHandleAtPosition(corner: corner, position: dragPos, areaColor: areaColor, areaCenter: areaCenter)
                        // Prikaži ostale strelice na normalnim pozicijama
                        if corner != .topRight {
                            areaResizeHandle(corner: .topRight, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if corner != .bottomRight {
                            areaResizeHandle(corner: .bottomRight, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if corner != .bottomLeft {
                            areaResizeHandle(corner: .bottomLeft, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if corner != .topLeft {
                            areaResizeHandle(corner: .topLeft, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                    } else if let mousePos = mouseLocation {
                        // Prikaži samo najbližu strelicu mišu (unutar 20px)
                        if let closestCorner = findClosestCorner(to: mousePos, areaWidth: areaWidth, areaHeight: areaHeight, areaCenter: areaCenter) {
                            areaResizeHandle(corner: closestCorner, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                    }
                    
                    // Strelice na sredinama stranica
                    if isResizingArea, let edge = resizeEdge, let dragPos = draggingHandlePosition {
                        // Prikaži strelicu koja se vuče na poziciji miša
                        areaEdgeResizeHandleAtPosition(edge: edge, position: dragPos, areaColor: areaColor, areaCenter: areaCenter)
                        // Prikaži ostale strelice na normalnim pozicijama
                        if edge != .top {
                            areaEdgeResizeHandle(edge: .top, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if edge != .right {
                            areaEdgeResizeHandle(edge: .right, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if edge != .bottom {
                            areaEdgeResizeHandle(edge: .bottom, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                        if edge != .left {
                            areaEdgeResizeHandle(edge: .left, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                    } else if let mousePos = mouseLocation {
                        // Prikaži samo najbližu strelicu mišu (unutar 20px)
                        if let closestEdge = findClosestEdge(to: mousePos, areaWidth: areaWidth, areaHeight: areaHeight, areaCenter: areaCenter) {
                            areaEdgeResizeHandle(edge: closestEdge, areaWidth: areaWidth, areaHeight: areaHeight, areaColor: areaColor, areaCenter: areaCenter)
                        }
                    }
                    
                    // Natpis ispod donje strelice
                    Text(component.name)
                        .font(.caption)
                        .foregroundColor(areaColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .offset(y: areaHeight / 2 + 25)
                }
                .position(x: areaCenter.x, y: areaCenter.y)
                // KLJUČNO: allowsHitTesting(true) samo za resize handles i text, ne za stroke
                // Stroke već ima allowsHitTesting(false), tako da button može reagirati
                .allowsHitTesting(true) // Omogući hit testing za resize handles
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        mouseLocation = location
                    case .ended:
                        mouseLocation = nil
                    }
                }
            }
            
            // KLJUČNO: NetworkComponentView (button) mora biti IZNAD Area kvadrata da može reagirati na klikove
            // Komponenta (crni kvadrat ili krug u test modu) - UVIJEK na fiksnoj poziciji, ne pomiče se tijekom resize-a
            NetworkComponentView(
                component: component,
                topology: topology,
                iconColor: iconColor,
                hoveredPoint: hoveredPoint,
                onIconTap: {
                    // U Config mode-u, klik na ikonu otvara settings izbornik
                    if isTestMode {
                        onTap(component) // Otvori ComponentDetailView (settings)
                    }
                },
                onIconDrag: { comp, location in
                    // U Edit mode-u, drag na ikoni započinje pomicanje komponente
                    // location je relativna na BaseComponentTopologyView (70x70), centar je na (35, 35)
                    // Trebamo je pretvoriti u globalne koordinate
                    
                    // Spremi fiksnu početnu poziciju komponente (samo jednom)
                    if !isDragging {
                        isDragging = true
                        // Koristi fiksnu početnu poziciju komponente (prije nego što se drag započne)
                        dragStartAbsoluteX = calculateAbsoluteX()
                        dragStartAbsoluteY = calculateAbsoluteY()
                        dragStartPosition = CGPoint(x: dragStartAbsoluteX, y: dragStartAbsoluteY)
                        
                        // Pozovi onDragUpdate SAMO JEDNOM na početku drag-a da se prikaže delete button
                        // Ovo se poziva samo jednom, ne kontinuirano
                        let globalLocation = CGPoint(
                            x: dragStartAbsoluteX + (location.x - 35),
                            y: dragStartAbsoluteY + (location.y - 35)
                        )
                        onDragUpdate?(comp, globalLocation)
                    }
                    
                    // Pretvori relativne koordinate u globalne
                    // BaseComponentTopologyView je pozicioniran na (dragStartAbsoluteX, dragStartAbsoluteY)
                    // location je relativna na BaseComponentTopologyView, gdje je centar na (35, 35)
                    let globalLocation = CGPoint(
                        x: dragStartAbsoluteX + (location.x - 35),
                        y: dragStartAbsoluteY + (location.y - 35)
                    )
                    
                    // Postavi dragOffset da komponenta prati miš
                    // dragOffset je razlika između trenutne pozicije miša i početne pozicije komponente
                    dragOffset = CGSize(
                        width: globalLocation.x - dragStartAbsoluteX,
                        height: globalLocation.y - dragStartAbsoluteY
                    )
                    
                    // KLJUČNO: NE pozivaj onDragUpdate tijekom drag-a!
                    // onDragUpdate poziva handleComponentDragUpdate koji može uzrokovati pozicioniranje
                    // Pozicioniranje će se aktivirati samo na kraju drag-a u onIconDragEnd
                },
                onIconDragUpdate: { comp, location in
                    // Ažuriraj poziciju tijekom drag-a (kontinuirano)
                    // location je relativna na BaseComponentTopologyView (70x70), centar je na (35, 35)
                    // Osiguraj da je drag započeo
                    guard isDragging else { return }
                    
                    // Pretvori relativne koordinate u globalne
                    let globalLocation = CGPoint(
                        x: dragStartAbsoluteX + (location.x - 35),
                        y: dragStartAbsoluteY + (location.y - 35)
                    )
                    
                    // Ažuriraj dragOffset da komponenta prati miš
                    dragOffset = CGSize(
                        width: globalLocation.x - dragStartAbsoluteX,
                        height: globalLocation.y - dragStartAbsoluteY
                    )
                    
                    // KLJUČNO: NE pozivaj onDragUpdate tijekom drag-a!
                    // onDragUpdate poziva handleComponentDragUpdate koji može uzrokovati pozicioniranje
                    // Pozicioniranje će se aktivirati samo na kraju drag-a u onIconDragEnd
                    // Delete button state se ne mora kontinuirano ažurirati - dovoljno je jednom na početku
                },
                onIconDragEnd: { comp, location in
                    // Završi drag i snap-aj na grid
                    // location je relativna na BaseComponentTopologyView (70x70), centar je na (35, 35)
                    
                    // Pretvori relativne koordinate u globalne
                    let globalLocation = CGPoint(
                        x: dragStartAbsoluteX + (location.x - 35),
                        y: dragStartAbsoluteY + (location.y - 35)
                    )
                    
                    // Snap-aj na grid
                    let snappedLocation = GridSnapHelper.snapToGrid(globalLocation)
                    
                    // KLJUČNO: Reset drag state PRIJE poziva onDrag
                    isDragging = false
                    dragOffset = .zero
                    dragStartAbsoluteX = 0
                    dragStartAbsoluteY = 0
                    
                    // Pozovi onDrag NAKON što se isDragging postavi na false
                    onDrag(comp, snappedLocation)
                },
                onPinClick: onPinClick,
                onConnectionDragStart: onConnectionDragStart,
                isTestMode: isTestMode,
                isEditMode: !isTestMode // Edit mode je suprotno od Config mode (isTestMode)
            )
            .position(
                // KLJUČNO: Koristi fiksnu poziciju tijekom drag-a (dragStartAbsoluteX/Y + dragOffset)
                // Ovo osigurava da se komponenta renderira samo na jednoj poziciji tijekom drag-a
                // Tijekom resize-a koristi početnu poziciju
                // Inače koristi normalnu poziciju iz component.position (izračunatu iz calculateAbsoluteX/Y)
                x: isDragging && !isResizingArea 
                    ? dragStartAbsoluteX + dragOffset.width 
                    : (isResizingArea ? resizeStartAbsoluteX : absoluteX),
                y: isDragging && !isResizingArea 
                    ? dragStartAbsoluteY + dragOffset.height 
                    : (isResizingArea ? resizeStartAbsoluteY : absoluteY)
            )
            // Osiguraj da se view ažurira kada se dragOffset promijeni
            .animation(.none, value: dragOffset)
            // KLJUČNO: Ne mijenjaj .id() tijekom drag-a jer to uzrokuje re-kreaciju view-a i nestajanje
            // Koristi konstantan ID da se view ne re-kreira
            .id(component.id.uuidString)
            .zIndex(100) // KLJUČNO: Button mora biti IZNAD Area kvadrata da može reagirati na klikove
        }
        .simultaneousGesture(
            // JEDAN gesture s minimumDistance: 0 da hvata i klik i drag
            // Onemogući drag u test modu
            // KLJUČNO: Ne aktiviraj ovaj gesture ako je drag započeo na ikoni (isDragging je true)
            // U Config mode-u, koristi simultaneousGesture da button može reagirati
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Ako je test mode (Config mode), provjeri je li klik na ikoni/button-u
                    // Ako jest, ne hvataj klik - button će ga obraditi
                    if isTestMode {
                        let componentCenter = CGPoint(x: absoluteX, y: absoluteY)
                        let componentSize: CGFloat = 70
                        let componentRect = CGRect(
                            x: componentCenter.x - componentSize / 2,
                            y: componentCenter.y - componentSize / 2,
                            width: componentSize,
                            height: componentSize
                        )
                        // Ako je klik na ikoni/button-u u Config mode-u, ne hvataj ga
                        // Button će ga obraditi i otvoriti settings menu
                        if componentRect.contains(value.startLocation) {
                            return
                        }
                        // Ako nije klik na ikoni, ne dozvoli drag (za area resize itd.)
                        return
                    }
                    // Ako je drag započeo na ikoni, ne aktiviraj ovaj gesture (za resize i connection points)
                    guard !isDragging else { return }
                    // KLJUČNO: Koristi fiksnu poziciju umjesto calculateAbsoluteX/Y() da se ne aktivira pozicioniranje
                    // Koristi absoluteX i absoluteY iz body property-ja koji već koriste fiksnu poziciju ako je isDragging == true
                    let componentCenter = CGPoint(x: absoluteX, y: absoluteY)
                    
                    // KLJUČNO: value.startLocation i value.location su GLOBALNE koordinate (relativne na parent view/canvas)
                    // jer ComponentView koristi .position() modifier
                    let startLocationGlobal = value.startLocation
                    let currentLocationGlobal = value.location
                    
                    // Provjeri je li klik na strelicu za resize (corner) - ima prioritet nad edge
                    // ILI ako je već resize aktivan, nastavi s resize-om
                    let detectedCorner = detectAreaResizeCorner(at: startLocationGlobal, componentCenter: componentCenter, areaWidth: component.areaWidth ?? 120, areaHeight: component.areaHeight ?? 120)
                    let corner = detectedCorner ?? (isResizingArea ? resizeCorner : nil)
                    if isAreaComponent, let corner = corner {
                        if !isResizingArea || resizeCorner != corner {
                            isResizingArea = true
                            resizeCorner = corner
                            resizeEdge = nil
                            resizeStartSize = CGSize(width: component.areaWidth ?? 120, height: component.areaHeight ?? 120)
                            resizeStartAbsoluteX = absoluteX
                            resizeStartAbsoluteY = absoluteY
                            
                            // Spremi apsolutnu poziciju anchor pointa (suprotni kut) - SAMO JEDNOM
                            let areaWidth = component.areaWidth ?? 120
                            let areaHeight = component.areaHeight ?? 120
                            switch corner {
                            case .topRight:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x - areaWidth / 2, y: componentCenter.y + areaHeight / 2)
                            case .bottomRight:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x - areaWidth / 2, y: componentCenter.y - areaHeight / 2)
                            case .bottomLeft:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x + areaWidth / 2, y: componentCenter.y - areaHeight / 2)
                            case .topLeft:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x + areaWidth / 2, y: componentCenter.y + areaHeight / 2)
                            }
                            
                            draggingHandlePosition = currentLocationGlobal
                        }
                        
                        // Ažuriraj poziciju strelice da prati miš
                        draggingHandlePosition = currentLocationGlobal
                        
                        // Koristi delta od startLocation (stabilno, bez inkrementalnog)
                        let deltaX = currentLocationGlobal.x - startLocationGlobal.x
                        let deltaY = currentLocationGlobal.y - startLocationGlobal.y
                        
                        var newWidth = resizeStartSize.width
                        var newHeight = resizeStartSize.height
                        
                        switch corner {
                        case .topRight:
                            newWidth += deltaX
                            newHeight -= deltaY
                        case .bottomRight:
                            newWidth += deltaX
                            newHeight += deltaY
                        case .bottomLeft:
                            newWidth -= deltaX
                            newHeight += deltaY
                        case .topLeft:
                            newWidth -= deltaX
                            newHeight -= deltaY
                        }
                        
                        component.areaWidth = newWidth
                        component.areaHeight = newHeight
                    }
                    // Provjeri je li klik na strelicu za resize (edge) - samo ako nije corner resize aktivan
                    else if isAreaComponent, !isResizingArea || resizeCorner == nil, let edge = detectAreaResizeEdge(at: startLocationGlobal, componentCenter: componentCenter, areaWidth: component.areaWidth ?? 120, areaHeight: component.areaHeight ?? 120) {
                        if !isResizingArea || resizeEdge != edge {
                            isResizingArea = true
                            resizeEdge = edge
                            resizeCorner = nil
                            resizeStartSize = CGSize(width: component.areaWidth ?? 120, height: component.areaHeight ?? 120)
                            resizeStartAbsoluteX = absoluteX
                            resizeStartAbsoluteY = absoluteY
                            
                            // Spremi apsolutnu poziciju anchor pointa (suprotna stranica) - SAMO JEDNOM
                            let areaWidth = component.areaWidth ?? 120
                            let areaHeight = component.areaHeight ?? 120
                            switch edge {
                            case .top:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x, y: componentCenter.y + areaHeight / 2)
                            case .right:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x - areaWidth / 2, y: componentCenter.y)
                            case .bottom:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x, y: componentCenter.y - areaHeight / 2)
                            case .left:
                                resizeAnchorPoint = CGPoint(x: componentCenter.x + areaWidth / 2, y: componentCenter.y)
                            }
                            
                            draggingHandlePosition = currentLocationGlobal
                        }
                        
                        // Ažuriraj poziciju strelice da prati miš
                        draggingHandlePosition = currentLocationGlobal
                        
                        // Koristi delta od startLocation (stabilno, bez inkrementalnog)
                        let deltaX = currentLocationGlobal.x - startLocationGlobal.x
                        let deltaY = currentLocationGlobal.y - startLocationGlobal.y
                        
                        var newWidth = resizeStartSize.width
                        var newHeight = resizeStartSize.height
                        
                        switch edge {
                        case .top:
                            newHeight -= deltaY
                        case .bottom:
                            newHeight += deltaY
                        case .left:
                            newWidth -= deltaX
                        case .right:
                            newWidth += deltaX
                        }
                        
                        component.areaWidth = newWidth
                        component.areaHeight = newHeight
                    }
                    // Provjeri je li klik na connection point (koristi ConnectionPointDetector s globalnim koordinatama)
                    // Onemogući pinove u test modu
                    else if !isTestMode, let connectionPoint = ConnectionPointDetector.detect(at: startLocationGlobal, componentCenter: componentCenter) {
                        let pinPosition = ConnectionPointDetector.position(for: connectionPoint, componentCenter: componentCenter)
                        
                        // KLJUČNO: Kada se klikne na pin, pozovi onPinClick (samo jednom)
                        if !pinClickStarted && onPinClick != nil {
                            pinClickStarted = true
                            draggingConnection = true
                            onPinClick?(component, connectionPoint, pinPosition)
                        }
                        
                        // Ažuriraj toPoint kontinuirano dok se vuče (krug prati miš)
                        if draggingConnection {
                            onConnectionDragUpdate?(currentLocationGlobal)
                        }
                    } else {
                        // Provjeri je li klik na komponentu (crno područje), ne na kvadrat ili strelice
                        let componentSize: CGFloat = 70
                        let componentRect = CGRect(
                            x: componentCenter.x - componentSize / 2,
                            y: componentCenter.y - componentSize / 2,
                            width: componentSize,
                            height: componentSize
                        )
                        
                        // Provjeri je li klik na ikonu (središnji dio komponente)
                        // U Edit mode-u, drag se započinje SAMO na ikoni, ne na cijeloj komponenti
                        let iconSize: CGFloat = 40
                        let iconRect = CGRect(
                            x: componentCenter.x - iconSize / 2,
                            y: componentCenter.y - iconSize / 2,
                            width: iconSize,
                            height: iconSize
                        )
                        
                        // U Edit mode-u, onemogući drag na cijeloj komponenti
                        // Drag se započinje SAMO na ikoni (rješava se u BaseComponentTopologyView)
                        // U Config mode-u, drag je ionako onemogućen
                        if componentRect.contains(startLocationGlobal) {
                            // U Edit mode-u, drag se započinje samo na ikoni, ne na cijeloj komponenti
                            // Ne dozvoli drag na cijeloj komponenti
                            // (drag na ikoni se rješava u BaseComponentTopologyView)
                            // Ne izvršavaj drag logiku - samo ikona započinje drag u Edit mode-u
                            // U Config mode-u, drag je ionako onemogućen
                        } else {
                            // Klik izvan komponente - ne radi ništa
                        }
                    }
                }
                .onEnded { value in
                    // Ako je test mode, ne dozvoli drag
                    guard !isTestMode else { return }
                    // Ako je bio area resize, spremi finalni areaCenter ali NE resetiraj state - omogući kontinuirani resize
                    if isResizingArea {
                        // Izračunaj finalni areaCenter na temelju anchor pointa i finalne veličine
                        let finalWidth = component.areaWidth ?? 120
                        let finalHeight = component.areaHeight ?? 120
                        
                        if let anchorPoint = resizeAnchorPoint {
                            if let corner = resizeCorner {
                                switch corner {
                                case .topRight:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x + finalWidth / 2, y: anchorPoint.y - finalHeight / 2)
                                case .bottomRight:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x + finalWidth / 2, y: anchorPoint.y + finalHeight / 2)
                                case .bottomLeft:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x - finalWidth / 2, y: anchorPoint.y + finalHeight / 2)
                                case .topLeft:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x - finalWidth / 2, y: anchorPoint.y - finalHeight / 2)
                                }
                            } else if let edge = resizeEdge {
                                switch edge {
                                case .top:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x, y: anchorPoint.y - finalHeight / 2)
                                case .right:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x + finalWidth / 2, y: anchorPoint.y)
                                case .bottom:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x, y: anchorPoint.y + finalHeight / 2)
                                case .left:
                                    finalAreaCenter = CGPoint(x: anchorPoint.x - finalWidth / 2, y: anchorPoint.y)
                                }
                            }
                        }
                        
                        // Ažuriraj resizeStartSize na trenutne vrijednosti za sljedeći resize
                        resizeStartSize = CGSize(width: component.areaWidth ?? 120, height: component.areaHeight ?? 120)
                        
                        // NE resetiraj isResizingArea, resizeCorner, resizeEdge, resizeAnchorPoint - omogući kontinuirani resize
                        // Resetiraj draggingHandlePosition za sljedeći drag
                        draggingHandlePosition = nil
                    }
                    
                    // Ako je bio connection drag, resetiraj state
                    if draggingConnection {
                        draggingConnection = false
                        pinClickStarted = false
                    }
                    
                    // KLJUČNO: Ne pozivaj onDrag ovdje ako je drag započeo na ikoni!
                    // Drag na ikoni se rješava u onIconDragEnd, ne ovdje
                    // Ovo je samo za drag na cijeloj komponenti (resize, connection points)
                    // Ako je isDragging == true, to znači da je drag započeo na ikoni i već će se riješiti u onIconDragEnd
                    // Ne pozivaj onDrag ovdje jer bi to uzrokovalo dupli poziv i pozicioniranje tijekom drag-a
                }
        )
    }
    
    private func calculateAbsoluteX() -> CGFloat {
        // Calculate absolute X based on zones
        let zoneWidth: CGFloat = 110
        let padding: CGFloat = 10
        let middleAreaStart = padding + zoneWidth
        
        if component.isClientA == true {
            // Client A: centered in zone
            return padding + (zoneWidth / 2)
        } else if component.isClientB == true {
            // Client B: centered in zone
            return (geometry.size.width - padding - zoneWidth) + (zoneWidth / 2)
        } else {
            // Component in middle area - position is relative to middle area start
            if component.position.x < 0 {
                // Component is in Client A zone (negative offset)
                return middleAreaStart + component.position.x
            } else if component.position.x > geometry.size.width - (padding * 2) - (zoneWidth * 2) {
                // Component is in Client B zone
                let offsetFromB = component.position.x - (geometry.size.width - (padding * 2) - (zoneWidth * 2))
                return geometry.size.width - padding - zoneWidth + offsetFromB
            } else {
                // Component is in middle area
                return middleAreaStart + component.position.x
            }
        }
    }
    
    private func calculateAbsoluteY() -> CGFloat {
        // Calculate absolute Y - Client A and B are 2/3 of window height, in bottom half
        if component.isClientA == true || component.isClientB == true {
            let clientHeight = geometry.size.height * (2.0 / 3.0)
            let bottomHalfStart = geometry.size.height * 0.5
            let padding: CGFloat = 20
            return bottomHalfStart + (clientHeight / 2) - padding
        } else {
            return component.position.y
        }
    }
    
    private func determineIconColor(absoluteX: CGFloat) -> Color {
        // User element koristi custom boju ako je postavljena, inače narančasta
        if component.componentType == .user {
            return component.customColor ?? Color(red: 1.0, green: 0.36, blue: 0.0) // Orange default
        }
        
        let zoneWidth: CGFloat = 110
        let padding: CGFloat = 10
        let isInClientAArea = absoluteX >= padding && absoluteX <= padding + zoneWidth
        let isInClientBArea = absoluteX >= geometry.size.width - padding - zoneWidth && absoluteX <= geometry.size.width - padding
        
        if isInClientAArea {
            return Color(red: 0.0, green: 0.2, blue: 1.0) // Blue
        } else if isInClientBArea {
            return Color(red: 0.0, green: 0.9, blue: 0.1) // Green
        } else {
            return .gray
        }
    }
    
    private func calculateAreaCenter(absoluteX: CGFloat, absoluteY: CGFloat, areaWidth: CGFloat, areaHeight: CGFloat) -> CGPoint {
        // Ako postoji finalni areaCenter (nakon resize-a), koristi ga
        if let finalCenter = finalAreaCenter {
            return finalCenter
        }
        
        // Ako je resize aktivan, računaj centar tako da anchor point ostane fiksno
        if isResizingArea, let anchorPoint = resizeAnchorPoint {
            if let corner = resizeCorner {
                // Izračunaj novi centar na temelju anchor pointa (suprotni kut)
                switch corner {
                case .topRight:
                    // Bottom-left kut je anchor
                    return CGPoint(x: anchorPoint.x + areaWidth / 2, y: anchorPoint.y - areaHeight / 2)
                case .bottomRight:
                    // Top-left kut je anchor
                    return CGPoint(x: anchorPoint.x + areaWidth / 2, y: anchorPoint.y + areaHeight / 2)
                case .bottomLeft:
                    // Top-right kut je anchor
                    return CGPoint(x: anchorPoint.x - areaWidth / 2, y: anchorPoint.y + areaHeight / 2)
                case .topLeft:
                    // Bottom-right kut je anchor
                    return CGPoint(x: anchorPoint.x - areaWidth / 2, y: anchorPoint.y - areaHeight / 2)
                }
            } else if let edge = resizeEdge {
                // Izračunaj novi centar na temelju anchor pointa (suprotna stranica)
                switch edge {
                case .top:
                    // Bottom edge je anchor
                    return CGPoint(x: anchorPoint.x, y: anchorPoint.y - areaHeight / 2)
                case .right:
                    // Left edge je anchor
                    return CGPoint(x: anchorPoint.x + areaWidth / 2, y: anchorPoint.y)
                case .bottom:
                    // Top edge je anchor
                    return CGPoint(x: anchorPoint.x, y: anchorPoint.y + areaHeight / 2)
                case .left:
                    // Right edge je anchor
                    return CGPoint(x: anchorPoint.x - areaWidth / 2, y: anchorPoint.y)
                }
            }
        }
        
        // Normalno - koristi poziciju komponente (NE centriraj automatski)
        // absoluteX i absoluteY su već pozicija komponente, koristi ih direktno
        let areaCenterX = absoluteX + (isDragging && !isResizingArea ? dragOffset.width : 0)
        let areaCenterY = absoluteY + (isDragging && !isResizingArea ? dragOffset.height : 0)
        
        return CGPoint(x: areaCenterX, y: areaCenterY)
    }
    
    @ViewBuilder
    private func areaResizeHandle(corner: AreaResizeCorner, areaWidth: CGFloat, areaHeight: CGFloat, areaColor: Color, areaCenter: CGPoint) -> some View {
        let offset = offsetForCorner(corner, areaWidth: areaWidth, areaHeight: areaHeight)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(cornerAngle(for: corner) - 45))
        }
        .offset(x: offset.width, y: offset.height)
        .allowsHitTesting(true)
    }
    
    @ViewBuilder
    private func areaResizeHandleAtPosition(corner: AreaResizeCorner, position: CGPoint, areaColor: Color, areaCenter: CGPoint) -> some View {
        // Izračunaj offset od areaCenter do position
        let offset = CGSize(width: position.x - areaCenter.x, height: position.y - areaCenter.y)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(cornerAngle(for: corner) - 45))
        }
        .offset(x: offset.width, y: offset.height)
    }
    
    private func offsetForCorner(_ corner: AreaResizeCorner, areaWidth: CGFloat, areaHeight: CGFloat) -> CGSize {
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        switch corner {
        case .topRight:
            return CGSize(width: areaWidth / 2 + handleOffset, height: -areaHeight / 2 - handleOffset)
        case .bottomRight:
            return CGSize(width: areaWidth / 2 + handleOffset, height: areaHeight / 2 + handleOffset)
        case .bottomLeft:
            return CGSize(width: -areaWidth / 2 - handleOffset, height: areaHeight / 2 + handleOffset)
        case .topLeft:
            return CGSize(width: -areaWidth / 2 - handleOffset, height: -areaHeight / 2 - handleOffset)
        }
    }
    
    private func cornerAngle(for corner: AreaResizeCorner) -> Double {
        switch corner {
        case .topRight: return 45
        case .bottomRight: return 135
        case .bottomLeft: return 225
        case .topLeft: return 315
        }
    }
    
    @ViewBuilder
    private func areaEdgeResizeHandle(edge: AreaResizeEdge, areaWidth: CGFloat, areaHeight: CGFloat, areaColor: Color, areaCenter: CGPoint) -> some View {
        let offset = offsetForEdge(edge, areaWidth: areaWidth, areaHeight: areaHeight)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(edgeAngle(for: edge)))
        }
        .offset(x: offset.width, y: offset.height)
        .allowsHitTesting(true)
    }
    
    @ViewBuilder
    private func areaEdgeResizeHandleAtPosition(edge: AreaResizeEdge, position: CGPoint, areaColor: Color, areaCenter: CGPoint) -> some View {
        // Izračunaj offset od areaCenter do position
        let offset = CGSize(width: position.x - areaCenter.x, height: position.y - areaCenter.y)
        ZStack {
            Circle()
                .fill(areaColor)
                .frame(width: 16, height: 16)
            
            Image(systemName: "arrow.up")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(edgeAngle(for: edge)))
        }
        .offset(x: offset.width, y: offset.height)
    }
    
    private func offsetForEdge(_ edge: AreaResizeEdge, areaWidth: CGFloat, areaHeight: CGFloat) -> CGSize {
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        switch edge {
        case .top:
            return CGSize(width: 0, height: -areaHeight / 2 - handleOffset)
        case .right:
            return CGSize(width: areaWidth / 2 + handleOffset, height: 0)
        case .bottom:
            return CGSize(width: 0, height: areaHeight / 2 + handleOffset)
        case .left:
            return CGSize(width: -areaWidth / 2 - handleOffset, height: 0)
        }
    }
    
    private func edgeAngle(for edge: AreaResizeEdge) -> Double {
        switch edge {
        case .top: return 0
        case .right: return 90
        case .bottom: return 180
        case .left: return 270
        }
    }
    
    private func detectAreaResizeEdge(at location: CGPoint, componentCenter: CGPoint, areaWidth: CGFloat, areaHeight: CGFloat) -> AreaResizeEdge? {
        let handleRadius: CGFloat = 20 // Povećano za lakše klikanje
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        let edges: [(CGSize, AreaResizeEdge)] = [
            (CGSize(width: 0, height: -areaHeight / 2 - handleOffset), .top),
            (CGSize(width: areaWidth / 2 + handleOffset, height: 0), .right),
            (CGSize(width: 0, height: areaHeight / 2 + handleOffset), .bottom),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: 0), .left)
        ]
        
        for (offset, edge) in edges {
            let handlePosition = CGPoint(x: componentCenter.x + offset.width, y: componentCenter.y + offset.height)
            let dx = location.x - handlePosition.x
            let dy = location.y - handlePosition.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= handleRadius {
                return edge
            }
        }
        
        return nil
    }
    
    private func detectAreaResizeCorner(at location: CGPoint, componentCenter: CGPoint, areaWidth: CGFloat, areaHeight: CGFloat) -> AreaResizeCorner? {
        let handleRadius: CGFloat = 20 // Povećano za lakše klikanje
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        let corners: [(CGSize, AreaResizeCorner)] = [
            (CGSize(width: areaWidth / 2 + handleOffset, height: -areaHeight / 2 - handleOffset), .topRight),
            (CGSize(width: areaWidth / 2 + handleOffset, height: areaHeight / 2 + handleOffset), .bottomRight),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: areaHeight / 2 + handleOffset), .bottomLeft),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: -areaHeight / 2 - handleOffset), .topLeft)
        ]
        
        for (offset, corner) in corners {
            let handlePosition = CGPoint(x: componentCenter.x + offset.width, y: componentCenter.y + offset.height)
            let dx = location.x - handlePosition.x
            let dy = location.y - handlePosition.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= handleRadius {
                return corner
            }
        }
        
        return nil
    }
    
    // Pronađi najbližu kutnu strelicu mišu
    private func findClosestCorner(to mouseLocation: CGPoint, areaWidth: CGFloat, areaHeight: CGFloat, areaCenter: CGPoint) -> AreaResizeCorner? {
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        let hitRadius: CGFloat = 20 // Radius unutar kojeg se strelica prikazuje
        
        var closestCorner: AreaResizeCorner? = nil
        var minDistance: CGFloat = .infinity
        
        let corners: [(CGSize, AreaResizeCorner)] = [
            (CGSize(width: areaWidth / 2 + handleOffset, height: -areaHeight / 2 - handleOffset), .topRight),
            (CGSize(width: areaWidth / 2 + handleOffset, height: areaHeight / 2 + handleOffset), .bottomRight),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: areaHeight / 2 + handleOffset), .bottomLeft),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: -areaHeight / 2 - handleOffset), .topLeft)
        ]
        
        for (offset, corner) in corners {
            let handlePosition = CGPoint(x: areaCenter.x + offset.width, y: areaCenter.y + offset.height)
            let dx = mouseLocation.x - handlePosition.x
            let dy = mouseLocation.y - handlePosition.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= hitRadius && distance < minDistance {
                minDistance = distance
                closestCorner = corner
            }
        }
        
        return closestCorner
    }
    
    // Pronađi najbližu strelicu na sredini stranice mišu
    private func findClosestEdge(to mouseLocation: CGPoint, areaWidth: CGFloat, areaHeight: CGFloat, areaCenter: CGPoint) -> AreaResizeEdge? {
        let handleOffset: CGFloat = 8 // Offset za strelicu izvan kvadrata
        let hitRadius: CGFloat = 20 // Radius unutar kojeg se strelica prikazuje
        
        var closestEdge: AreaResizeEdge? = nil
        var minDistance: CGFloat = .infinity
        
        let edges: [(CGSize, AreaResizeEdge)] = [
            (CGSize(width: 0, height: -areaHeight / 2 - handleOffset), .top),
            (CGSize(width: areaWidth / 2 + handleOffset, height: 0), .right),
            (CGSize(width: 0, height: areaHeight / 2 + handleOffset), .bottom),
            (CGSize(width: -areaWidth / 2 - handleOffset, height: 0), .left)
        ]
        
        for (offset, edge) in edges {
            let handlePosition = CGPoint(x: areaCenter.x + offset.width, y: areaCenter.y + offset.height)
            let dx = mouseLocation.x - handlePosition.x
            let dy = mouseLocation.y - handlePosition.y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= hitRadius && distance < minDistance {
                minDistance = distance
                closestEdge = edge
            }
        }
        
        return closestEdge
    }
}

