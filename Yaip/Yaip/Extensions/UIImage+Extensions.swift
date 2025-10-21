//
//  UIImage+Extensions.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/21/25.
//

import UIKit

extension UIImage {
    /// Compress image to target size in KB
    func compressed(maxSizeKB: Int = 500) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        var imageData = self.jpegData(compressionQuality: compression)
        
        // Reduce quality until under max size
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = self.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
    
    /// Resize image to max dimension
    func resized(maxDimension: CGFloat = 1024) -> UIImage {
        let size = self.size
        
        // Already smaller than max
        if size.width <= maxDimension && size.height <= maxDimension {
            return self
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        // Resize
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

