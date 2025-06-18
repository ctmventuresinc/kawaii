//
//  BackgroundRemover.swift
//  daily-affirmations
//
//  Created by Los Mayers on 11/5/24.
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
	func normalized() -> UIImage {
		if imageOrientation == .up {
			return self
		}
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		draw(in: CGRect(origin: .zero, size: size))
		let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return normalizedImage ?? self
	}
	
	func croppedToNonTransparentBounds() -> UIImage? {
		guard let cgImage = self.cgImage else { return nil }
		
		let width = cgImage.width
		let height = cgImage.height
		let bytesPerPixel = 4
		let bytesPerRow = bytesPerPixel * width
		let bitsPerComponent = 8
		
		guard let context = CGContext(
			data: nil,
			width: width,
			height: height,
			bitsPerComponent: bitsPerComponent,
			bytesPerRow: bytesPerRow,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
		) else { return nil }
		
		context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
		
		guard let data = context.data else { return nil }
		let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
		
		var minX = width, maxX = 0, minY = height, maxY = 0
		
		// Find bounds of non-transparent pixels
		for y in 0..<height {
			for x in 0..<width {
				let pixelIndex = (y * width + x) * bytesPerPixel
				let alpha = pixels[pixelIndex + 3]
				
				if alpha > 0 { // Non-transparent pixel
					minX = min(minX, x)
					maxX = max(maxX, x)
					minY = min(minY, y)
					maxY = max(maxY, y)
				}
			}
		}
		
		// Check if we found any non-transparent pixels
		guard minX < maxX && minY < maxY else { return nil }
		
		// Add small padding to avoid cutting off edges
		let padding = 10
		let cropRect = CGRect(
			x: max(0, minX - padding),
			y: max(0, minY - padding),
			width: min(width, maxX - minX + 2 * padding),
			height: min(height, maxY - minY + 2 * padding)
		)
		
		guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
		return UIImage(cgImage: croppedCGImage, scale: scale, orientation: imageOrientation)
	}
}

class BackgroundRemover {
	private let context = CIContext()
	private let processingQueue = DispatchQueue(label: "ProcessingQueue")
	
	func removeBackground(of image: UIImage, completion: @escaping (UIImage?) -> Void) {
		let normalizedImage = image.normalized() // Ensure the image is in "up" orientation
		guard let ciImage = CIImage(image: normalizedImage) else {
			completion(nil)
			return
		}
		
		processingQueue.async {
			guard let maskImage = self.subjectMaskImage(from: ciImage) else {
				completion(nil)
				return
			}
			let outputImage = self.apply(mask: maskImage, to: ciImage)
			let renderedImage = self.render(ciImage: outputImage)
			DispatchQueue.main.async {
				completion(renderedImage)
			}
		}
	}
	
	private func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
		let handler = VNImageRequestHandler(ciImage: inputImage)
		let request = VNGenerateForegroundInstanceMaskRequest()
		do {
			try handler.perform([request])
			guard let result = request.results?.first else {
				print("No observations found")
				return nil
			}
			let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
			return CIImage(cvPixelBuffer: maskPixelBuffer)
		} catch {
			print("Error generating mask: \(error)")
			return nil
		}
	}
	
	private func apply(mask: CIImage, to image: CIImage) -> CIImage {
		let blendFilter = CIFilter.blendWithMask()
		blendFilter.inputImage = image
		blendFilter.maskImage = mask
		blendFilter.backgroundImage = CIImage.empty()
		return blendFilter.outputImage!
	}
	
	private func render(ciImage: CIImage) -> UIImage? {
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
			print("Failed to render CGImage")
			return nil
		}
		let uiImage = UIImage(cgImage: cgImage)
		
		// Auto-crop to remove transparent dead space
		return uiImage.croppedToNonTransparentBounds() ?? uiImage
	}
}
