# NetworkTopology Tracking & Analysis

## Pregled

`NetworkTopology` klasa sada ima metode za praćenje elemenata (komponenti) i konekcija na topologiji.

## Praćenje Komponenti

### Dobivanje svih komponenti

```swift
// Sve komponente (uključujući Client A i Client B)
let allComponents = topology.getAllComponents()

// Samo regularne komponente (bez Client A i Client B)
let regularComponents = topology.getRegularComponents()

// Komponente po tipu
let servers = topology.getComponentsByType(.server)
let routers = topology.getComponentsByType(.router)

// Komponente po kategoriji
let clients = topology.getComponentsByCategory(.client)
let infrastructure = topology.getComponentsByCategory(.infrastructure)
```

### Brojanje komponenti

```swift
// Ukupan broj komponenti
let totalCount = topology.getComponentCount()

// Broj komponenti po tipu
let serverCount = topology.getComponentCountByType(.server)
```

## Praćenje Konekcija

### Dobivanje konekcija za komponentu

```swift
// Sve konekcije za određenu komponentu
let connections = topology.getConnections(for: componentId)

// Komponente koje su direktno spojene s određenom komponentom
let connectedComponents = topology.getConnectedComponents(for: componentId)

// Detaljne informacije o konekcijama komponente
let connectionDetails = topology.getComponentConnectionDetails(for: componentId)
// Vraća: [ComponentConnectionInfo] sa informacijama o svakoj konekciji
```

### Provjera konekcija

```swift
// Provjeri jesu li dvije komponente spojene
let areConnected = topology.areComponentsConnected(componentId1, componentId2)

// Komponente bez konekcija (izolirane)
let isolated = topology.getIsolatedComponents()
```

### Statistike konekcija

```swift
// Ukupan broj konekcija
let connectionCount = topology.getConnectionCount()

// Broj konekcija po tipu
let wiredCount = topology.getConnectionCountByType(.wired)
let wirelessCount = topology.getConnectionCountByType(.wireless)

// Najpovezanije komponente
let mostConnected = topology.getMostConnectedComponents(limit: 5)
// Vraća: [(component: NetworkComponent, connectionCount: Int)]
```

## Potpuna Statistika

```swift
// Sve statistike topologije
let stats = topology.getTopologyStatistics()

// stats sadrži:
// - totalComponents: Int
// - regularComponents: Int
// - totalConnections: Int
// - isolatedComponents: Int
// - componentsByType: [ComponentType: Int]
// - connectionsByType: [ConnectionType: Int]
```

## Sve Konekcije s Detaljima

```swift
// Sve konekcije s informacijama o komponentama
let allConnections = topology.getAllConnectionDetails()
// Vraća: [FullConnectionInfo] sa fromComponent i toComponent
```

## Primjeri Korištenja

### Primjer 1: Provjera koliko komponenti ima topologija

```swift
let topology = NetworkTopology()
// ... dodaj komponente ...

let totalComponents = topology.getComponentCount()
print("Topologija ima \(totalComponents) komponenti")
```

### Primjer 2: Pronađi sve komponente koje su spojene s routerom

```swift
if let router = topology.components.first(where: { $0.componentType == .router }) {
    let connected = topology.getConnectedComponents(for: router.id)
    print("Router je spojen s \(connected.count) komponenti:")
    for component in connected {
        print("  - \(component.name) (\(component.componentType.displayName))")
    }
}
```

### Primjer 3: Prikaži statistiku topologije

```swift
let stats = topology.getTopologyStatistics()
print("Statistika topologije:")
print("  Ukupno komponenti: \(stats.totalComponents)")
print("  Regularne komponente: \(stats.regularComponents)")
print("  Ukupno konekcija: \(stats.totalConnections)")
print("  Izolirane komponente: \(stats.isolatedComponents)")

print("\nKomponente po tipu:")
for (type, count) in stats.componentsByType {
    print("  \(type.displayName): \(count)")
}

print("\nKonekcije po tipu:")
for (type, count) in stats.connectionsByType {
    print("  \(type.rawValue): \(count)")
}
```

### Primjer 4: Pronađi najpovezanije komponente

```swift
let mostConnected = topology.getMostConnectedComponents(limit: 3)
print("Najpovezanije komponente:")
for (index, item) in mostConnected.enumerated() {
    print("\(index + 1). \(item.component.name) - \(item.connectionCount) konekcija")
}
```

### Primjer 5: Detaljne informacije o konekcijama komponente

```swift
if let server = topology.components.first(where: { $0.componentType == .server }) {
    let details = topology.getComponentConnectionDetails(for: server.id)
    
    print("Server '\(server.name)' je spojen s:")
    for detail in details {
        print("  - \(detail.connectedComponent.name)")
        print("    Tip konekcije: \(detail.connection.connectionType.rawValue)")
        if let point = detail.connectionPoint {
            print("    Pin: \(point.rawValue)")
        }
    }
}
```

### Primjer 6: Provjeri je li topologija povezana

```swift
let isolated = topology.getIsolatedComponents()
if isolated.isEmpty {
    print("Sve komponente su povezane!")
} else {
    print("Izolirane komponente: \(isolated.count)")
    for component in isolated {
        print("  - \(component.name)")
    }
}
```

