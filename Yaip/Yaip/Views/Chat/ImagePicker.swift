//
//  ImagePicker.swift
//  Yaip
//
//  Created by Aleksandr Gaun on 10/20/25.
//

import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            Image(systemName: "photo")
                .foregroundStyle(.blue)
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                print("📸 Photo picker selection changed")
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    print("✅ Data loaded: \(data.count) bytes")
                    if let uiImage = UIImage(data: data) {
                        print("✅ UIImage created successfully")
                        selectedImage = uiImage
                    } else {
                        print("❌ Failed to create UIImage from data")
                    }
                } else {
                    print("❌ Failed to load data from picker")
                }
            }
        }
    }
}

