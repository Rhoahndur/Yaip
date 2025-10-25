#!/bin/bash

echo "🧹 Cleaning up debug logging..."

# Files to clean up (most verbose ones)
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
        # Comment out print statements with emoji (verbose debugging)
        sed -i '' -E 's/^([[:space:]]*)print\("[\U0001F300-\U0001F9FF]/\1\/\/ print("/' "$file"
        # Comment out multi-line print statements (verbose debugging)
        sed -i '' -E 's/^([[:space:]]*)print\("   /\1\/\/ print("   /' "$file"
    fi
done

echo "✅ Debug cleanup complete!"
echo "Files cleaned: ${#FILES[@]}"
