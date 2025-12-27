//
//  BaseComponentTopologyView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import AppKit

/// Base view za prikaz mrežne komponente u topologiji
/// Koristi novu OOP arhitekturu s BaseTopologyElement
/// Prikazuje komponentu s ikonom, pinovima za konekcije i podrškom za test mode
/// Podržava Edit mode (drag & drop) i Settings mode (otvori postavke)
struct BaseComponentTopologyView: View {
    @ObservedObject var component: NetworkComponent
    var topology: NetworkTopology? = nil
    var iconColor: Color? = nil
    var pinColor: Color? = nil
    var hoveredPoint: ConnectionPoint? = nil
    var onIconTap: (() -> Void)? = nil
    var onIconDrag: ((NetworkComponent, CGPoint) -> Void)? = nil // Drag handler za Edit mode
    var onIconDragUpdate: ((NetworkComponent, CGPoint) -> Void)? = nil // Drag update handler
    var onIconDragEnd: ((NetworkComponent, CGPoint) -> Void)? = nil // Drag end handler
    var onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)? = nil
    var onConnectionDragStart: ((NetworkComponent, CGPoint, CGPoint) -> Void)? = nil
    var isTestMode: Bool = false
    var isEditMode: Bool = true // Default: edit mode
    var displayable: Any? = nil // Za buduće proširenje
    
    // Kreiraj TopologyElement za ovu komponentu
    @StateObject private var topologyElement: BaseTopologyElement
    
    // State za drag ikone u Edit mode-u
    @State private var isDraggingIcon: Bool = false
    @State private var iconDragOffset: CGSize = .zero
    @State private var iconDragStartLocation: CGPoint = .zero
    @State private var dragStartTime: Date? = nil // Vrijeme početka drag-a za detekciju tap-a
    
    // State za settings menu
    @State private var showSettingsMenu: Bool = false
    
    private let componentSize: CGFloat = 70
    private let connectionPointDistance: CGFloat = 45
    private let connectionPointRadius: CGFloat = 8
    
    init(
        component: NetworkComponent,
        topology: NetworkTopology? = nil,
        iconColor: Color? = nil,
        pinColor: Color? = nil,
        hoveredPoint: ConnectionPoint? = nil,
        onIconTap: (() -> Void)? = nil,
        onIconDrag: ((NetworkComponent, CGPoint) -> Void)? = nil,
        onIconDragUpdate: ((NetworkComponent, CGPoint) -> Void)? = nil,
        onIconDragEnd: ((NetworkComponent, CGPoint) -> Void)? = nil,
        onPinClick: ((NetworkComponent, ConnectionPoint, CGPoint) -> Void)? = nil,
        onConnectionDragStart: ((NetworkComponent, CGPoint, CGPoint) -> Void)? = nil,
        isTestMode: Bool = false,
        isEditMode: Bool = true,
        displayable: Any? = nil
    ) {
        self.component = component
        self.topology = topology
        self.iconColor = iconColor
        self.pinColor = pinColor
        self.hoveredPoint = hoveredPoint
        self.onIconTap = onIconTap
        self.onIconDrag = onIconDrag
        self.onIconDragUpdate = onIconDragUpdate
        self.onIconDragEnd = onIconDragEnd
        self.onPinClick = onPinClick
        self.onConnectionDragStart = onConnectionDragStart
        self.isTestMode = isTestMode
        self.isEditMode = isEditMode
        self.displayable = displayable
        
        // Kreiraj TopologyElement - automatski određuje tip (Area ili Regular)
        let visibility: ElementVisibility = (component.isClientA == true || component.isClientB == true) ? .private : .public
        _topologyElement = StateObject(wrappedValue: TopologyElementFactory.createElement(for: component, visibility: visibility, topology: topology))
    }
    
    var body: some View {
        // Osiguraj da je topology postavljen prije nego što se pozove getIconColor()
        // Ovo osigurava da se boja određuje pravilno čak i prije onAppear
        if topologyElement.topology == nil && topology != nil {
            topologyElement.topology = topology
        }
        
        return ZStack {
            // Background shape - mijenja se ovisno o mode-u
            // Edit mode: sivi kvadrat
            // Config mode: narančasti krug
            backgroundShape
            
            // Component icon - različito ponašanje ovisno o mode-u
            // Button u sredini kvadrata s ikonom unutar njega
            componentIconWithGesture
                .frame(width: componentSize, height: componentSize)
                .contentShape(Rectangle()) // Omogući hit testing na cijelom Button-u
            
            // Connection points (pins) - samo ako nije test mode
            // SVI elementi imaju pinove (ConnectableElement)
            if !isTestMode {
                connectionPoints
            }
        }
        .frame(width: componentSize, height: componentSize)
        .onChange(of: isEditMode) { newValue in
            topologyElement.editMode = newValue
            topologyElement.settingsMode = !newValue
        }
        .onChange(of: isTestMode) { newValue in
            // Kada je isTestMode = true, to je Config mode
            // Postavi settingsMode na true kada je Config mode aktivan
            topologyElement.settingsMode = newValue
            topologyElement.editMode = !newValue
        }
        .onChange(of: topology?.connections.count) { _ in
            // Ažuriraj topology reference i osvježi view kada se promijene konekcije
            topologyElement.topology = topology
            topologyElement.objectWillChange.send()
        }
        .onAppear {
            // Ažuriraj topology reference kada se view pojavi
            topologyElement.topology = topology
        }
        .sheet(isPresented: $showSettingsMenu) {
            // Prikaži settings menu iz BaseTopologyElement
            // Osiguraj da se component prosljeđuje kao @ObservedObject za binding
            SettingsMenuView(
                component: component, // Koristi direktno component iz BaseComponentTopologyView
                topology: topology,
                customView: topologyElement.settingsMenu.customSettingsView()
            )
        }
    }
    
    // MARK: - Background Shape
    
    /// Background shape koji se mijenja ovisno o mode-u
    private var backgroundShape: some View {
        Group {
            // isTestMode = true znači Config mode (iz LabConnectView gumba)
            // settingsMode također može biti true za Config mode
            let isConfigMode = isTestMode || topologyElement.settingsMode
            let orangeColor = Color(red: 1.0, green: 0.36, blue: 0.0)
            
            if isConfigMode {
                // U Config mode-u: krug s narančastim obrubom (stroke), crna pozadina
                Circle()
                    .fill(Color.black.opacity(0.8)) // Crna pozadina
                    .frame(width: componentSize, height: componentSize)
                    .overlay(
                        Circle()
                            .stroke(orangeColor, lineWidth: 2) // Narančasti obrub
                    )
            } else {
                // U Edit mode-u: sivi kvadrat
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.8))
                    .frame(width: componentSize, height: componentSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 2)
                    )
            }
        }
    }
    
    // MARK: - Icon with Gesture
    
    /// Ikona s gesture-om - različito ponašanje ovisno o mode-u
    private var componentIconWithGesture: some View {
        Group {
            // Provjeri da li je Config mode (isTestMode = true ili settingsMode = true)
            let isConfigMode = isTestMode || topologyElement.settingsMode
            
            if !isConfigMode {
                // Edit mode: Button s drag gesture na ikoni za pomicanje komponente
                // U Edit mode-u, drag pomiče komponentu, tap ne radi ništa
                Button(action: {}) {
                    componentIcon
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Centriraj ikonu u Button-u
                }
                .buttonStyle(PlainButtonStyle()) // Ukloni default button styling
                .frame(width: componentSize, height: componentSize) // Button je istih dimenzija kao kvadrat
                .highPriorityGesture(
                    // highPriorityGesture daje DragGesture prioritet nad Button action
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDraggingIcon {
                                isDraggingIcon = true
                                iconDragStartLocation = value.startLocation
                                
                                // Pozovi onIconDrag za početak drag-a
                                if let onIconDrag = onIconDrag {
                                    onIconDrag(component, value.startLocation)
                                }
                            }
                            
                            // Ažuriraj offset (relativno na BaseComponentTopologyView)
                            iconDragOffset = CGSize(
                                width: value.location.x - value.startLocation.x,
                                height: value.location.y - value.startLocation.y
                            )
                            
                            // Pozovi onIconDragUpdate za kontinuirano ažuriranje
                            if let onIconDragUpdate = onIconDragUpdate {
                                onIconDragUpdate(component, value.location)
                            }
                        }
                        .onEnded { value in
                            isDraggingIcon = false
                            
                            // Pozovi onIconDragEnd za završetak drag-a
                            if let onIconDragEnd = onIconDragEnd {
                                onIconDragEnd(component, value.location)
                            }
                            
                            // Reset offset
                            iconDragOffset = .zero
                        }
                )
            } else {
                // Config mode: Button s tap action za otvaranje settings izbornika (menu)
                // Ovo vrijedi za SVE elemente, uključujući Area elemente
                Button(action: {
                    // U Config mode-u, klik na Button otvara menu/postavke
                    topologyElement.openSettings()
                    showSettingsMenu = true
                }) {
                    componentIcon
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Centriraj ikonu u Button-u
                }
                .buttonStyle(PlainButtonStyle()) // Ukloni default button styling
                .frame(width: componentSize, height: componentSize) // Button je istih dimenzija kao kvadrat
                .contentShape(Rectangle()) // Osiguraj da je cijeli button klikabilan
            }
        }
    }
    
    // MARK: - Component Icon
    
    private var componentIcon: some View {
        // UVIJEK koristi logiku iz BaseTopologyElement za boju ikone
        // Default: siva boja, narančasta samo u Config mode-u
        // iconColor parametar se ignorira jer parent klasa određuje boju
        // Osiguraj da je settingsMode postavljen ako je isTestMode = true (Config mode)
        let finalIconColor: Color
        if isTestMode && !topologyElement.settingsMode {
            // Ako je isTestMode = true (Config mode), ali settingsMode nije postavljen, postavi ga
            finalIconColor = Color(red: 1.0, green: 0.36, blue: 0.0) // Narančasta u Config mode-u
        } else {
            finalIconColor = topologyElement.getIconColor()
        }
        
        // Provjeri da li treba koristiti selectedDeviceType za User Area ili Gateway za ostale Area elemente
        if component.componentType == .userArea, let deviceType = component.selectedDeviceType {
            // Za User Area, koristi ikonu odabranog device type-a
            return Group {
                Image(systemName: ComponentIconHelper.icon(for: deviceType))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(finalIconColor)
            }
        } else if component.componentType == .businessArea || 
                  component.componentType == .businessPrivateArea || 
                  component.componentType == .nilterniusArea {
            // Za ostale Area elemente, koristi Gateway ikonu
            return Group {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(finalIconColor)
            }
        }
        
        return Group {
            if ComponentIconHelper.hasCustomIcon(for: component.componentType),
               let customIconName = ComponentIconHelper.customIconName(for: component.componentType),
               let customImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
                // Custom icon - koristi template rendering mode da bi se primijenila boja
                Image(nsImage: customImage)
                    .renderingMode(.template) // KLJUČNO: omogućava primjenu boje na custom ikone
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(finalIconColor) // Sada će se boja primijeniti
            } else {
                // SF Symbol icon
                Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(finalIconColor)
            }
        }
    }
    
    // MARK: - Connection Points
    
    /// SVI elementi imaju pinove (ConnectableElement protokol)
    private var connectionPoints: some View {
        ZStack {
            // Koristi connectionPoints iz TopologyElement
            ForEach(topologyElement.connectionPoints, id: \.self) { point in
                connectionPoint(at: point)
            }
        }
    }
    
    private func connectionPoint(at point: ConnectionPoint) -> some View {
        let componentCenter = CGPoint(x: componentSize / 2, y: componentSize / 2)
        let position = topologyElement.getPinPosition(point, componentCenter: componentCenter)
        
        let isHovered = hoveredPoint == point
        // UVIJEK koristi logiku iz BaseTopologyElement za boju pinova (siva po defaultu)
        let pinColorToUse = pinColor ?? topologyElement.getIconColor()
        
        // KLJUČNO: Prikaži pin samo ako je miš blizu (isHovered == true)
        // Inače pin nije vidljiv (opacity 0)
        return Circle()
            .fill(isHovered ? pinColorToUse : Color.clear)
            .frame(width: connectionPointRadius * 2, height: connectionPointRadius * 2)
            .overlay(
                Circle()
                    .stroke(isHovered ? Color.white : Color.clear, lineWidth: 2)
            )
            .opacity(isHovered ? 1.0 : 0.0) // Sakrij pin ako nije hovered
            .position(x: position.x, y: position.y)
    }
}

