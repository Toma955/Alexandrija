//
//  AlexandriaRenderer.swift
//  Alexandria
//
//  Renderer – AlexandriaViewNode → SwiftUI View.
//

import SwiftUI

struct AlexandriaRenderer: View {
    let node: AlexandriaViewNode
    let console: ConsoleStore
    let accentColor: Color
    
    init(node: AlexandriaViewNode, console: ConsoleStore = .shared, accentColor: Color = Color(hex: "ff5c00")) {
        self.node = node
        self.console = console
        self.accentColor = accentColor
    }
    
    var body: some View {
        render(node)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func render(_ node: AlexandriaViewNode) -> AnyView {
        switch node {
        case .vStack(let children, let spacing):
            AnyView(
                VStack(alignment: .leading, spacing: spacing ?? 8) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .hStack(let children, let spacing):
            AnyView(
                HStack(spacing: spacing ?? 8) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .zStack(let children):
            AnyView(
                ZStack(alignment: .center) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .lazyVStack(let children, let spacing):
            AnyView(
                LazyVStack(alignment: .leading, spacing: spacing ?? 8) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .lazyHStack(let children, let spacing):
            AnyView(
                LazyHStack(spacing: spacing ?? 8) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .scrollView(let child):
            AnyView(ScrollView { render(child) })
        case .color(let hex):
            AnyView(Color(hex: hex))
        case .rectangle:
            AnyView(Rectangle().fill(Color.white.opacity(0.1)))
        case .roundedRectangle(let radius):
            AnyView(RoundedRectangle(cornerRadius: radius).fill(Color.white.opacity(0.1)))
        case .circle:
            AnyView(Circle().fill(Color.white.opacity(0.1)))
        case .text(let content):
            AnyView(Text(content).foregroundColor(.white))
        case .button(let label, _):
            AnyView(
                Button(label) {
                    console.log("Button tapped: \(label)")
                }
                .foregroundColor(accentColor)
            )
        case .image(let name):
            AnyView(
                Image(systemName: name)
                    .foregroundColor(accentColor)
                    .font(.system(size: 24))
            )
        case .spacer:
            AnyView(Spacer())
        case .divider:
            AnyView(Divider().background(Color.white.opacity(0.3)))
        case .padding(let amount, let child):
            AnyView(render(child).padding(amount))
        case .frame(let width, let height, let child):
            AnyView(render(child).frame(width: width, height: height))
        case .positioned(let x, let y, let width, let height, let child):
            AnyView(
                ZStack(alignment: .topLeading) {
                    Color.clear
                    render(child)
                        .frame(width: width, height: height)
                        .offset(x: x, y: y)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        case .background(let hex, let child):
            AnyView(render(child).background(Color(hex: hex)))
        case .foreground(let hex, let child):
            AnyView(render(child).foregroundColor(Color(hex: hex)))
        case .list(let children):
            AnyView(
                List {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .form(let children):
            AnyView(
                Form {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .grid(let children):
            AnyView(
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
            )
        case .tabView(let tabs):
            AnyView(
                TabView {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { _, tab in
                        render(tab.content)
                            .tabItem { Text(tab.label) }
                    }
                }
            )
        case .group(let child):
            AnyView(Group { render(child) })
        case .groupBox(let label, let child):
            AnyView(GroupBox(label: Text(label)) { render(child) }.foregroundColor(.white))
        case .section(let header, let footer, let child):
            AnyView(
                Section(header: header.map { Text($0) }, footer: footer.map { Text($0) }) {
                    render(child)
                }
            )
        case .disclosureGroup(let label, let child):
            AnyView(DisclosureGroup(label) { render(child) }.foregroundColor(.white))
        case .label(let title, let systemImage):
            AnyView(Label(title, systemImage: systemImage).foregroundColor(.white))
        case .link(let title, let url):
            AnyView(
                Link(title, destination: URL(string: url) ?? URL(string: "https://")!)
                    .foregroundColor(accentColor)
            )
        case .textField(let placeholder):
            AnyView(StatefulTextField(placeholder: placeholder))
        case .secureField(let placeholder):
            AnyView(StatefulSecureField(placeholder: placeholder))
        case .textEditor(let placeholder):
            AnyView(StatefulTextEditor(placeholder: placeholder))
        case .toggle(let label, let isOn):
            AnyView(StatefulToggle(label: label, initial: isOn))
        case .slider(let value, let range):
            AnyView(StatefulSlider(value: value, range: range))
        case .stepper(let label, let value, let step):
            AnyView(StatefulStepper(label: label, value: value, step: step))
        case .picker(let label, let options):
            AnyView(StatefulPicker(label: label, options: options))
        case .progressView(let value):
            if let v = value {
                AnyView(ProgressView(value: v))
            } else {
                AnyView(ProgressView())
            }
        case .gauge(let value, let range, let label):
            AnyView(
                Gauge(value: value, in: range) {
                    if !label.isEmpty { Text(label) }
                }
                .foregroundColor(accentColor)
            )
        case .menu(let label, let children):
            AnyView(
                Menu(label) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        render(child)
                    }
                }
                .foregroundColor(accentColor)
            )
        case .ellipse:
            AnyView(Ellipse().fill(Color.white.opacity(0.1)))
        case .capsule:
            AnyView(Capsule().fill(Color.white.opacity(0.1)))
        }
    }
}

// MARK: - Stateful wrappers za kontrole s bindings
private struct StatefulTextField: View {
    let placeholder: String
    @State private var text = ""
    var body: some View {
        TextField(placeholder, text: $text)
            .foregroundColor(.white)
    }
}

private struct StatefulSecureField: View {
    let placeholder: String
    @State private var text = ""
    var body: some View {
        SecureField(placeholder, text: $text)
            .foregroundColor(.white)
    }
}

private struct StatefulTextEditor: View {
    let placeholder: String
    @State private var text = ""
    var body: some View {
        TextEditor(text: $text)
            .foregroundColor(.white)
            .frame(minHeight: 60)
    }
}

private struct StatefulToggle: View {
    let label: String
    let initial: Bool
    @State private var isOn: Bool
    init(label: String, initial: Bool) {
        self.label = label
        self.initial = initial
        _isOn = State(initialValue: initial)
    }
    var body: some View {
        Toggle(label, isOn: $isOn)
    }
}

private struct StatefulSlider: View {
    let range: ClosedRange<CGFloat>
    @State private var value: Double
    init(value: CGFloat, range: ClosedRange<CGFloat>) {
        self.range = range
        _value = State(initialValue: Double(value))
    }
    var body: some View {
        Slider(value: $value, in: Double(range.lowerBound)...Double(range.upperBound))
    }
}

private struct StatefulStepper: View {
    let label: String
    let step: CGFloat
    @State private var value: Double
    init(label: String, value: CGFloat, step: CGFloat) {
        self.label = label
        self.step = step
        _value = State(initialValue: Double(value))
    }
    var body: some View {
        HStack {
            Text(label).foregroundColor(.white)
            Stepper("", value: $value, in: -100...100, step: step)
        }
    }
}

private struct StatefulPicker: View {
    let label: String
    let options: [String]
    @State private var selection: Int
    init(label: String, options: [String]) {
        self.label = label
        self.options = options
        _selection = State(initialValue: 0)
    }
    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, opt in
                Text(opt).tag(i)
            }
        }
        .foregroundColor(.white)
    }
}
