//
//  AlexandriaDSL.swift
//  Alexandria
//
//  Alexandria DSL – Swift-like format za definiranje app stranice.
//  Alexandria čita ovaj kod i renderira ga u SwiftUI.
//

import Foundation

struct TabItem: Equatable {
    let label: String
    let content: AlexandriaViewNode
}

// MARK: - View čvor (stablasta struktura) – indirect za rekurziju
indirect enum AlexandriaViewNode: Equatable {
    case vStack(children: [AlexandriaViewNode], spacing: CGFloat?)
    case hStack(children: [AlexandriaViewNode], spacing: CGFloat?)
    case zStack(children: [AlexandriaViewNode])
    case lazyVStack(children: [AlexandriaViewNode], spacing: CGFloat?)
    case lazyHStack(children: [AlexandriaViewNode], spacing: CGFloat?)
    case scrollView(child: AlexandriaViewNode)
    case list(children: [AlexandriaViewNode])
    case form(children: [AlexandriaViewNode])
    case grid(children: [AlexandriaViewNode])
    case tabView(tabs: [TabItem])
    case group(child: AlexandriaViewNode)
    case groupBox(label: String, child: AlexandriaViewNode)
    case section(header: String?, footer: String?, child: AlexandriaViewNode)
    case disclosureGroup(label: String, child: AlexandriaViewNode)
    case text(String)
    case button(String, action: String?)
    case image(String)
    case label(String, systemImage: String)
    case link(String, url: String)
    case textField(placeholder: String)
    case secureField(placeholder: String)
    case textEditor(placeholder: String)
    case toggle(label: String, isOn: Bool)
    case slider(value: CGFloat, range: ClosedRange<CGFloat>)
    case stepper(label: String, value: CGFloat, step: CGFloat)
    case picker(label: String, options: [String])
    case progressView(value: CGFloat?)
    case gauge(value: CGFloat, range: ClosedRange<CGFloat>, label: String)
    case menu(label: String, children: [AlexandriaViewNode])
    case spacer
    case divider
    case color(String)
    case rectangle
    case roundedRectangle(cornerRadius: CGFloat)
    case circle
    case ellipse
    case capsule
    case padding(CGFloat, child: AlexandriaViewNode)
    case frame(width: CGFloat?, height: CGFloat?, child: AlexandriaViewNode)
    case background(String, child: AlexandriaViewNode)
    case foreground(String, child: AlexandriaViewNode)
}

// MARK: - Primjer DSL koda (Swift-like)
/*
 VStack(spacing: 16) {
     Text("Dobrodošli")
     Button("Klikni") { }
     Image("icon")
     Spacer()
 }
 */
