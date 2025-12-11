// QRCodeGenerator.swift
// Generates QR codes for profile sharing

import UIKit
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    /// Generates a QR code image from a string
    static func generate(from string: String, size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else {
            print("❌ Failed to convert string to data")
            return nil
        }

        filter.message = data
        filter.correctionLevel = "H" // High error correction

        guard let outputImage = filter.outputImage else {
            print("❌ Failed to generate QR code")
            return nil
        }

        // Scale the QR code to the desired size
        let scaleX = size.width / outputImage.extent.width
        let scaleY = size.height / outputImage.extent.height
        let scale = min(scaleX, scaleY)

        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            print("❌ Failed to create CGImage")
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generates a stylized QR code with a profile photo in the center
    static func generateStylized(from string: String, centerImage: UIImage?, size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        guard let qrImage = generate(from: string, size: size) else {
            return nil
        }

        // If no center image, return the plain QR code
        guard let centerImage = centerImage else {
            return qrImage
        }

        // Create a new image with the QR code and center image
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw QR code
            qrImage.draw(in: CGRect(origin: .zero, size: size))

            // Draw white circle background for center image
            let centerSize = size.width * 0.25
            let centerRect = CGRect(
                x: (size.width - centerSize) / 2,
                y: (size.height - centerSize) / 2,
                width: centerSize,
                height: centerSize
            )

            // Draw white circle
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: centerRect.insetBy(dx: -8, dy: -8))

            // Draw center image
            let path = UIBezierPath(ovalIn: centerRect)
            path.addClip()
            centerImage.draw(in: centerRect)
        }
    }

    /// Generates a branded QR code with Featur branding
    static func generateBranded(from string: String, profileImage: UIImage?, displayName: String, size: CGSize = CGSize(width: 800, height: 1000)) -> UIImage? {
        guard let qrImage = generateStylized(from: string, centerImage: profileImage, size: CGSize(width: 512, height: 512)) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // Background gradient
            let colors = [UIColor(red: 0.4, green: 0.3, blue: 0.8, alpha: 1.0).cgColor,
                         UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])

            // White container
            let containerRect = CGRect(x: 50, y: 150, width: size.width - 100, height: 700)
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(containerRect)

            // QR code
            let qrRect = CGRect(x: (size.width - 512) / 2, y: 200, width: 512, height: 512)
            qrImage.draw(in: qrRect)

            // Display name
            let nameText = displayName as NSString
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let nameSize = nameText.size(withAttributes: nameAttributes)
            let nameRect = CGRect(x: (size.width - nameSize.width) / 2, y: 750, width: nameSize.width, height: nameSize.height)
            nameText.draw(in: nameRect, withAttributes: nameAttributes)

            // "Scan to Connect" text
            let scanText = "Scan to Connect on Featur" as NSString
            let scanAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            let scanSize = scanText.size(withAttributes: scanAttributes)
            let scanRect = CGRect(x: (size.width - scanSize.width) / 2, y: 810, width: scanSize.width, height: scanSize.height)
            scanText.draw(in: scanRect, withAttributes: scanAttributes)
        }
    }
}
