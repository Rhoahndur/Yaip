#!/bin/bash

echo "🧹 Cleaning up debug logging (simpler approach)..."

# Files to clean up
FILES=(
    "Yaip/Yaip/ViewModels/ChatViewModel.swift"
    "Yaip/Yaip/Utilities/NetworkMonitor.swift"
    "Yaip/Yaip/ViewModels/AIFeaturesViewModel.swift"
    "Yaip/Yaip/Services/MessageService.swift"
    "Yaip/Yaip/Services/N8NService.swift"
    "Yaip/Yaip/Managers/ImageUploadManager.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Cleaning: $file"
        # Comment out prints with specific emoji
        sed -i '' 's/^        print("🔄/        \/\/ print("🔄/g' "$file"
        sed -i '' 's/^            print("🔄/            \/\/ print("🔄/g' "$file"
        sed -i '' 's/^        print("📥/        \/\/ print("📥/g' "$file"
        sed -i '' 's/^            print("📥/            \/\/ print("📥/g' "$file"
        sed -i '' 's/^        print("📤/        \/\/ print("📤/g' "$file"
        sed -i '' 's/^            print("📤/            \/\/ print("📤/g' "$file"
        sed -i '' 's/^        print("📡/        \/\/ print("📡/g' "$file"
        sed -i '' 's/^            print("📡/            \/\/ print("📡/g' "$file"
        sed -i '' 's/^        print("💾/        \/\/ print("💾/g' "$file"
        sed -i '' 's/^        print("📖/        \/\/ print("📖/g' "$file"
        sed -i '' 's/^            print("📖/            \/\/ print("📖/g' "$file"
        sed -i '' 's/^        print("✅/        \/\/ print("✅/g' "$file"
        sed -i '' 's/^            print("✅/            \/\/ print("✅/g' "$file"
        sed -i '' 's/^        print("⚠️/        \/\/ print("⚠️/g' "$file"
        sed -i '' 's/^            print("⚠️/            \/\/ print("⚠️/g' "$file"
        sed -i '' 's/^        print("🔍/        \/\/ print("🔍/g' "$file"
        sed -i '' 's/^        print("🌐/        \/\/ print("🌐/g' "$file"
        sed -i '' 's/^        print("📱/        \/\/ print("📱/g' "$file"
        sed -i '' 's/^            print("📱/            \/\/ print("📱/g' "$file"
        sed -i '' 's/^        print("🎉/        \/\/ print("🎉/g' "$file"
        sed -i '' 's/^            print("🎉/            \/\/ print("🎉/g' "$file"
        sed -i '' 's/^        print("⏱️/        \/\/ print("⏱️/g' "$file"
        sed -i '' 's/^        print("⏹️/        \/\/ print("⏹️/g' "$file"
        sed -i '' 's/^        print("⏳/        \/\/ print("⏳/g' "$file"
        # Comment out indented continuation lines (verbose multi-line logging)
        sed -i '' 's/^        print("   /        \/\/ print("   /g' "$file"
        sed -i '' 's/^            print("   /            \/\/ print("   /g' "$file"
    fi
done

echo "✅ Debug cleanup complete!"
