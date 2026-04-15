import CoreImage
import UIKit
import SwiftUI

enum QRCodeService {
    // Generate a UIImage QR code from any string payload
    static func generate(from string: String, size: CGFloat = 300) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"   // Medium error correction — good balance

        guard let ciImage = filter.outputImage else { return nil }

        // Scale to requested size
        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // Returns a SwiftUI Image ready to display
    static func image(from string: String, size: CGFloat = 300) -> Image {
        if let uiImage = generate(from: string, size: size) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "qrcode")
    }

    // Compose a printable label: QR code + box name overlay
    static func labelImage(for box: MovingBox, size: CGFloat = 400) -> UIImage? {
        let qrSize: CGFloat = size * 0.75
        guard let qr = generate(from: box.qrPayload, size: qrSize) else { return nil }

        let labelHeight = size + 80
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: labelHeight))

        return renderer.image { ctx in
            // White background
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: labelHeight))

            // Draw QR code centred horizontally
            let qrX = (size - qrSize) / 2
            qr.draw(in: CGRect(x: qrX, y: 16, width: qrSize, height: qrSize))

            // Box name
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.black
            ]
            let nameStr = NSAttributedString(string: box.name, attributes: nameAttrs)
            let nameSize = nameStr.size()
            nameStr.draw(at: CGPoint(x: (size - nameSize.width) / 2, y: qrSize + 24))

            // Location subtitle
            if !box.location.isEmpty {
                let locAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.darkGray
                ]
                let locStr = NSAttributedString(string: box.location, attributes: locAttrs)
                let locSize = locStr.size()
                locStr.draw(at: CGPoint(x: (size - locSize.width) / 2, y: qrSize + 54))
            }
        }
    }
}

// CIFilter convenience extension
private extension CIFilter {
    static func qrCodeGenerator() -> QRCodeFilter {
        QRCodeFilter(name: "CIQRCodeGenerator")!
    }
}

private class QRCodeFilter: CIFilter {
    var message: Data? {
        get { value(forKey: "inputMessage") as? Data }
        set { setValue(newValue, forKey: "inputMessage") }
    }
    var correctionLevel: String {
        get { value(forKey: "inputCorrectionLevel") as? String ?? "M" }
        set { setValue(newValue, forKey: "inputCorrectionLevel") }
    }
}
