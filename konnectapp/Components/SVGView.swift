import SwiftUI
import WebKit

struct SVGView: UIViewRepresentable {
    let svgString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.configuration.preferences.javaScriptEnabled = false
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Загружаем SVG сразу
        loadSVG(webView: webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Обновляем только если содержимое изменилось
        loadSVG(webView: webView)
    }
    
    private func loadSVG(webView: WKWebView) {
        // Очищаем SVG от потенциальных внешних ресурсов WEBP
        let cleanedSVG = svgString.replacingOccurrences(of: ".webp", with: "", options: .caseInsensitive)
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                }
                svg {
                    width: 100%;
                    height: 100%;
                }
                img {
                    display: none;
                }
            </style>
        </head>
        <body>
            \(cleanedSVG)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

