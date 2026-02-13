//
//  WebView.swift
//  Alexandria
//
//  WKWebView omotan za SwiftUI – prikaz web stranice.
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @Binding var url: URL?
    var onURLChange: ((URL?) -> Void)?
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if let url = url, webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onURLChange?(webView.url)
        }
    }
}

/// Wrapper za WebView – prima URL string, prikazuje web stranicu
struct WebViewWrapper: View {
    let urlString: String
    @State private var url: URL?
    
    var body: some View {
        WebView(url: $url)
            .onAppear {
                if let u = URL(string: urlString) {
                    url = u
                }
            }
    }
}
