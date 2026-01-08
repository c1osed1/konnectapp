import SwiftUI
import UIKit

class ImageColorExtractor {
    static func extractDominantColors(from image: UIImage, count: Int = 5) -> [Color] {
        guard let cgImage = image.cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Упрощенный алгоритм извлечения цветов
        var colorCounts: [String: (r: Int, g: Int, b: Int, count: Int)] = [:]
        
        // Берем каждый 10-й пиксель для ускорения
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let index = (y * width + x) * bytesPerPixel
                guard index + 2 < pixelData.count else { continue }
                
                let r = Int(pixelData[index])
                let g = Int(pixelData[index + 1])
                let b = Int(pixelData[index + 2])
                
                // Пропускаем слишком темные и слишком светлые цвета
                let brightness = (r + g + b) / 3
                guard brightness > 30 && brightness < 220 else { continue }
                
                // Квантуем цвета для группировки
                let quantizedR = (r / 32) * 32
                let quantizedG = (g / 32) * 32
                let quantizedB = (b / 32) * 32
                let key = "\(quantizedR),\(quantizedG),\(quantizedB)"
                
                if colorCounts[key] == nil {
                    colorCounts[key] = (r: r, g: g, b: b, count: 1)
                } else {
                    colorCounts[key]?.count += 1
                }
            }
        }
        
        // Сортируем по частоте и берем топ цвета
        let sortedColors = colorCounts.values.sorted { $0.count > $1.count }
        let topColors = Array(sortedColors.prefix(count))
        
        return topColors.map { colorData in
            Color(
                red: Double(colorData.r) / 255.0,
                green: Double(colorData.g) / 255.0,
                blue: Double(colorData.b) / 255.0
            )
        }
    }
    
    static func getDefaultColors() -> [Color] {
        return [
            Color(red: 1.0, green: 0.85, blue: 0.3),  // Яркий желтый
            Color(red: 1.0, green: 0.6, blue: 0.2),   // Оранжевый
            Color(red: 1.0, green: 0.4, blue: 0.6),   // Розовый
            Color(red: 0.7, green: 0.4, blue: 0.9),   // Фиолетовый
            Color(red: 0.5, green: 0.3, blue: 0.8)    // Темно-фиолетовый
        ]
    }
}
