//
//  TrackModeView.swift
//  TreeOfChoice
//
//  Created by Toma Babić on 09.12.2025..
//

import SwiftUI
import UniformTypeIdentifiers

/// Model za element na tracku
struct TrackItem: Identifiable {
    let id: UUID
    let componentId: UUID // ID komponente iz topologije
    let trackNumber: Int // Broj tracka (0-19)
    let startTime: Int // Početno vrijeme na timeline-u (0-200)
    let duration: Int // Trajanje (u jedinicama timeline-a)
    
    init(id: UUID = UUID(), componentId: UUID, trackNumber: Int, startTime: Int, duration: Int = 10) {
        self.id = id
        self.componentId = componentId
        self.trackNumber = trackNumber
        self.startTime = startTime
        self.duration = duration
    }
}

/// View za Track mode - prikazuje track mode specifičan sadržaj
/// U Edit mode-u se prikazuje kao prozor iznad control panela
struct TrackModeView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isEditMode: Bool
    var canvasElement: CanvasElement? // Optional pristup topologiji
    
    @State private var showSaveDialog = false
    @State private var showUploadDialog = false
    @State private var saveError: String?
    @State private var uploadError: String?
    @State private var trackItems: [TrackItem] = [] // Elementi postavljeni na trackove
    @State private var draggedComponent: NetworkComponent? // Komponenta koja se trenutno vuče
    @State private var dragLocation: CGPoint = .zero // Lokacija miša tijekom drag-a
    @State private var isDragging: Bool = false // Stanje drag-a
    
    init(isEditMode: Binding<Bool> = .constant(false), canvasElement: CanvasElement? = nil) {
        self._isEditMode = isEditMode
        self.canvasElement = canvasElement
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar - narančasti kvadrat s close, upload i save
            topBar
            
            // Main content - dva kvadrata s paddingom
            HStack(spacing: 12) {
                // Mali kvadrat od vrha do dna (lijevo)
                leftPanel
                
                // Veliki kvadrat koji zauzima većinu ekrana (desno)
                rightPanel
            }
            .padding(12) // Padding od ruba
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(
            isPresented: $showUploadDialog,
            allowedContentTypes: [UTType(filenameExtension: "swift") ?? .plainText, .json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    uploadTopology(from: url)
                }
            case .failure(let error):
                uploadError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $showSaveDialog,
            document: TopologySwiftDocument(topology: getTopology()),
            contentType: UTType(filenameExtension: "swift") ?? .plainText,
            defaultFilename: "TopologyData"
        ) { result in
            switch result {
            case .success:
                saveError = nil
            case .failure(let error):
                saveError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Actions
    
    private func getTopology() -> NetworkTopology {
        return canvasElement?.topologyViewElement.topologyElement.topology ?? NetworkTopology()
    }
    
    private func saveTopology() {
        guard let canvasElement = canvasElement else {
            saveError = "No topology available"
            return
        }
        
        let topology = canvasElement.topologyViewElement.topologyElement.topology
        
        // Show save dialog
        showSaveDialog = true
    }
    
    private func uploadTopology(from url: URL) {
        guard let canvasElement = canvasElement else {
            uploadError = "No topology available"
            return
        }
        
        do {
            let storageService = TopologyStorageService.shared
            
            // Provjeri tip datoteke
            if url.pathExtension == "swift" {
                // Za Swift datoteke, koristimo JSON alternativu za sada
                // (Swift parsing nije implementiran)
                uploadError = "Swift file parsing not yet implemented. Please use JSON format."
            } else if url.pathExtension == "json" {
                // Učitaj iz JSON
                let importedTopology = try storageService.loadTopologyFromJSON(from: url)
                
                // Kopiraj u trenutnu topologiju
                let currentTopology = canvasElement.topologyViewElement.topologyElement.topology
                currentTopology.components = importedTopology.components
                currentTopology.connections = importedTopology.connections
                currentTopology.clientA = importedTopology.clientA
                currentTopology.clientB = importedTopology.clientB
                currentTopology.agentAssignments = importedTopology.agentAssignments
                
                uploadError = nil
            } else {
                uploadError = "Unsupported file format. Please use .swift or .json"
            }
        } catch {
            uploadError = error.localizedDescription
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Narančasti zaobljeni kvadrat s crvenim krugom i X
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isEditMode = false
                }
            }) {
                ZStack {
                    // Narančasti zaobljeni kvadrat
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 1.0, green: 0.36, blue: 0.0))
                        .frame(width: 32, height: 32)
                    
                    // Crveni krug s X
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Upload button
            Button(action: {
                showUploadDialog = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                    Text("Upload")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 1.0, green: 0.36, blue: 0.0))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            // Save button
            Button(action: {
                saveTopology()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                    Text("Save")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 1.0, green: 0.36, blue: 0.0))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Left Panel (mali kvadrat) - Lista elemenata topologije
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Header - "Topology Elements"
            HStack {
                Text("Elements")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(topologyElements.count)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // Scrollable content area s elementima topologije
            ScrollView {
                VStack(spacing: 8) {
                    if topologyElements.isEmpty {
                        // Empty state
                        VStack(spacing: 8) {
                            Image(systemName: "network")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.3))
                            Text("No elements")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Lista elemenata
                        ForEach(topologyElements) { component in
                            TopologyElementListItem(component: component, draggedComponent: $draggedComponent)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        )
        .frame(width: 200) // Fiksna širina za mali kvadrat
    }
    
    // MARK: - Computed Properties
    
    /// Vraća listu svih elemenata na topologiji (bez Client A i B)
    private var topologyElements: [NetworkComponent] {
        guard let canvasElement = canvasElement else {
            return []
        }
        
        let topology = canvasElement.topologyViewElement.topologyElement.topology
        // Filtriraj Client A i B
        return topology.components.filter { 
            $0.isClientA != true && $0.isClientB != true 
        }
    }
    
    /// Vraća komponentu po ID-u
    private func getComponent(by id: UUID) -> NetworkComponent? {
        return topologyElements.first { $0.id == id }
    }
    
    /// Rukuje drop-om elementa na track
    private func handleDrop(component: NetworkComponent, trackIndex: Int, location: CGPoint, geometry: GeometryProxy) {
        // Izračunaj startTime na temelju lokacije
        // Timeline ide od 0 do 200, širina je 2000px, dakle 10px = 1 jedinica
        let timelineWidth: CGFloat = 2000
        let timelineUnits: Int = 200
        let pixelsPerUnit = timelineWidth / CGFloat(timelineUnits)
        
        let startTime = max(0, min(timelineUnits - 10, Int(location.x / pixelsPerUnit)))
        let duration = 10
        
        // Provjeri da li već postoji element na ovom tracku u tom vremenskom intervalu
        let hasOverlap = trackItems.contains { item in
            item.trackNumber == trackIndex &&
            !(item.startTime + item.duration <= startTime || item.startTime >= startTime + duration)
        }
        
        // Ako postoji preklapanje, pronađi prvi slobodan track
        var finalTrackIndex = trackIndex
        if hasOverlap {
            // Traži slobodan track
            for i in 0..<20 {
                let isFree = !trackItems.contains { item in
                    item.trackNumber == i &&
                    !(item.startTime + item.duration <= startTime || item.startTime >= startTime + duration)
                }
                if isFree {
                    finalTrackIndex = i
                    break
                }
            }
        }
        
        // Kreiraj novi track item
        let newItem = TrackItem(
            componentId: component.id,
            trackNumber: finalTrackIndex,
            startTime: startTime,
            duration: duration
        )
        
        trackItems.append(newItem)
        draggedComponent = nil
        isDragging = false
    }
    
    // MARK: - Right Panel (veliki kvadrat)
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Timeline na vrhu s brojevima
            timelineHeader
            
            // Scrollable content area s track poljima (vertikalno i horizontalno)
            GeometryReader { geometry in
                ZStack {
                    ScrollView {
                        ScrollView(.horizontal, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Vertikalno raspoređena horizontalna polja (tracks)
                                ForEach(0..<20) { trackIndex in
                                    ZStack(alignment: .leading) {
                                        // Background track polje
                                        TrackFieldView()
                                            .frame(height: 50)
                                            .frame(minWidth: 2000)
                                        
                                        // Elementi postavljeni na ovaj track
                                        ForEach(trackItems.filter { $0.trackNumber == trackIndex }) { item in
                                            if let component = getComponent(by: item.componentId) {
                                                TrackItemView(
                                                    item: item,
                                                    component: component,
                                                    trackWidth: 2000
                                                )
                                            }
                                        }
                                    }
                                    .frame(height: 50)
                                    .frame(minWidth: 2000)
                                    .contentShape(Rectangle())
                                    .onDrop(of: [.text], delegate: TrackDropDelegate(
                                        trackIndex: trackIndex,
                                        draggedComponent: $draggedComponent,
                                        trackItems: $trackItems,
                                        getComponent: getComponent,
                                        onDrop: { component, location in
                                            handleDrop(component: component, trackIndex: trackIndex, location: location, geometry: geometry)
                                        }
                                    ))
                                }
                            }
                        }
                    }
                    
                    // Drag preview overlay - prikazuje se iznad svega i prati kursor
                    if let dragged = draggedComponent, isDragging {
                        TrackDragPreview(
                            component: dragged,
                            location: dragLocation,
                            trackWidth: 2000
                        )
                    }
                }
                .simultaneousGesture(
                    // Global gesture za praćenje miša tijekom drag-a
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if draggedComponent != nil {
                                isDragging = true
                                // Koristimo lokaciju miša u koordinatama view-a
                                dragLocation = value.location
                            }
                        }
                        .onEnded { _ in
                            // Reset ako se drag otkaže bez drop-a
                            if draggedComponent != nil {
                                draggedComponent = nil
                                isDragging = false
                            }
                        }
                )
                .onContinuousHover { phase in
                    if draggedComponent != nil {
                        switch phase {
                        case .active(let location):
                            isDragging = true
                            dragLocation = location
                        case .ended:
                            // Reset ako miš izađe iz view-a
                            if draggedComponent != nil {
                                draggedComponent = nil
                                isDragging = false
                            }
                            break
                        }
                    }
                }
            }
            
            // Horizontalni slider na dnu
            horizontalSlider
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity) // Zauzima preostali prostor
    }
    
    // MARK: - Horizontal Slider
    
    private var horizontalSlider: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.3))
            
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    // Prazan prostor - slider je na maksimumu jer je prazan
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 2000) // Širina koja odgovara track poljima
                }
            }
            .frame(height: 20) // Visina slidera
        }
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Timeline Header
    
    private var timelineHeader: some View {
        VStack(spacing: 0) {
            // Horizontalna linija s brojevima
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Brojevi na timeline-u (kao u audio editoru) - prošireno do 200
                    ForEach(0..<200) { index in
                        VStack(spacing: 0) {
                            // Glavni marker (svaki 10. broj)
                            if index % 10 == 0 {
                                Text("\(index)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 60)
                                    .padding(.top, 4)
                            } else if index % 5 == 0 {
                                // Srednji marker (svaki 5. broj)
                                Text("\(index)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 30)
                                    .padding(.top, 4)
                            }
                            
                            // Vertikalna linija
                            Rectangle()
                                .fill(index % 10 == 0 ? Color.white.opacity(0.6) : 
                                      index % 5 == 0 ? Color.white.opacity(0.4) : 
                                      Color.white.opacity(0.2))
                                .frame(width: index % 10 == 0 ? 2 : 
                                       index % 5 == 0 ? 1 : 0.5)
                                .frame(height: index % 10 == 0 ? 20 : 
                                       index % 5 == 0 ? 15 : 10)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 40) // Visina timeline headera
            
            // Horizontalna linija ispod brojeva
            Divider()
                .background(Color.white.opacity(0.3))
        }
        .background(Color.black.opacity(0.4))
    }
}

// MARK: - Track Field View

/// View za pojedino track polje u desnom panelu - horizontalno polje sa sivo-crnom bojom
struct TrackFieldView: View {
    var body: some View {
        // Glavno track polje (sivo-crna boja) - bez natpisa
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(white: 0.15), // Sivo-crna
                        Color(white: 0.12)  // Tamnija sivo-crna
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 50)
            .overlay(
                // Gornja linija za razdvajanje trackova
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            )
    }
}

/// View za pojedino track polje u lijevom panelu - samo horizontalno polje sa sivo-crnom bojom
struct LeftTrackFieldView: View {
    let trackNumber: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Track broj
            Text("\(trackNumber)")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 30)
                .padding(.leading, 8)
            
            // Glavno track polje (sivo-crna boja)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(white: 0.15), // Sivo-crna
                            Color(white: 0.12)  // Tamnija sivo-crna
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxWidth: .infinity)
        }
        .frame(height: 50)
        .overlay(
            // Gornja linija za razdvajanje trackova
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        )
    }
}

// MARK: - TopologySwiftDocument

struct TopologySwiftDocument: FileDocument {
    static var readableContentTypes: [UTType] { 
        [UTType(filenameExtension: "swift") ?? .plainText, .plainText] 
    }
    static var writableContentTypes: [UTType] { 
        [UTType(filenameExtension: "swift") ?? .plainText, .plainText] 
    }
    
    var topology: NetworkTopology
    
    init(topology: NetworkTopology) {
        self.topology = topology
    }
    
    init(configuration: ReadConfiguration) throws {
        // Reading not needed for save operation
        self.topology = NetworkTopology()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let storageService = TopologyStorageService.shared
        
        // Generiraj Swift kod - koristimo public metodu
        let swiftCode = storageService.generateSwiftCodeForDocument(from: topology)
        
        guard let data = swiftCode.data(using: .utf8) else {
            throw NSError(domain: "TopologyStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode Swift code"])
        }
        
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - TopologyElementListItem

/// View za prikaz jednog elementa iz topologije u listi
struct TopologyElementListItem: View {
    @ObservedObject var component: NetworkComponent
    @Binding var draggedComponent: NetworkComponent?
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        HStack(spacing: 10) {
            // Drag area - ikona + naziv (može se dragati)
            HStack(spacing: 10) {
                // Ikona elementa
                iconView
                    .frame(width: 32, height: 32)
                
                // Naziv elementa
                Text(component.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onDrag {
                draggedComponent = component
                return NSItemProvider(object: component.id.uuidString as NSString)
            } preview: {
                // Drag preview - prikazuje se dok se vuče
                HStack(spacing: 6) {
                    iconView
                        .frame(width: 20, height: 20)
                    Text(component.name)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentOrange)
                )
            }
            
            // Okrugli botun sa strelicom prema dole (ne može se dragati)
            Button(action: {
                // TODO: Implement action
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .allowsHitTesting(true) // Botun je interaktivan
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accentOrange)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var iconView: some View {
        // Provjeri ima li custom ikonu
        if ComponentIconHelper.hasCustomIcon(for: component.componentType),
           let customIconName = ComponentIconHelper.customIconName(for: component.componentType),
           let customImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
            // Custom icon
            Image(nsImage: customImage)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.white.opacity(0.9))
        } else {
            // SF Symbol icon
            Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - TrackItemView

/// View za prikaz elementa postavljenog na track
struct TrackItemView: View {
    let item: TrackItem
    let component: NetworkComponent
    let trackWidth: CGFloat
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    private let pixelsPerUnit: CGFloat = 10 // 10px = 1 timeline unit (2000px / 200 units)
    
    var body: some View {
        let xPosition = CGFloat(item.startTime) * pixelsPerUnit
        let width = CGFloat(item.duration) * pixelsPerUnit
        
        HStack(spacing: 6) {
            // Ikona elementa
            iconView
                .frame(width: 20, height: 20)
            
            // Naziv elementa
            Text(component.name)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: max(width, 60), height: 40)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(accentOrange)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .position(x: xPosition + (width / 2), y: 25) // Centar na y=25 (sredina tracka)
    }
    
    @ViewBuilder
    private var iconView: some View {
        if ComponentIconHelper.hasCustomIcon(for: component.componentType),
           let customIconName = ComponentIconHelper.customIconName(for: component.componentType),
           let customImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
            Image(nsImage: customImage)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.white)
        } else {
            Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - TrackDragPreview

/// Preview elementa dok se vuče preko trackova - prati kursor miša
struct TrackDragPreview: View {
    let component: NetworkComponent
    let location: CGPoint
    let trackWidth: CGFloat
    
    private let accentOrange = Color(red: 1.0, green: 0.36, blue: 0.0)
    
    var body: some View {
        // Prikaži preview na lokaciji miša (offset malo gore i lijevo da ne bude direktno na kursoru)
        let xPosition = max(30, min(location.x, trackWidth - 30))
        let yPosition = max(20, min(location.y, 980)) // 20 trackova * 50px = 1000px
        
        HStack(spacing: 6) {
            iconView
                .frame(width: 20, height: 20)
            
            Text(component.name)
                .font(.caption2)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: 60, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(accentOrange.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                )
                .shadow(color: accentOrange.opacity(0.5), radius: 8, x: 0, y: 2)
        )
        .position(x: xPosition, y: yPosition)
        .allowsHitTesting(false) // Ne blokira interakcije ispod
    }
    
    @ViewBuilder
    private var iconView: some View {
        if ComponentIconHelper.hasCustomIcon(for: component.componentType),
           let customIconName = ComponentIconHelper.customIconName(for: component.componentType),
           let customImage = ComponentIconHelper.loadCustomIcon(named: customIconName) {
            Image(nsImage: customImage)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.white)
        } else {
            Image(systemName: ComponentIconHelper.icon(for: component.componentType))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
}


// MARK: - TrackDropDelegate

/// Delegate za drop elemenata na track
struct TrackDropDelegate: DropDelegate {
    let trackIndex: Int
    @Binding var draggedComponent: NetworkComponent?
    @Binding var trackItems: [TrackItem]
    let getComponent: (UUID) -> NetworkComponent?
    let onDrop: (NetworkComponent, CGPoint) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let dragged = draggedComponent else { return false }
        
        // Lokacija drop-a u koordinatama tracka
        let location = info.location
        
        onDrop(dragged, location)
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Može se koristiti za visual feedback
    }
    
    func dropExited(info: DropInfo) {
        // Može se koristiti za visual feedback
    }
}
