#!/bin/bash
# Run in Terminal:
#   bash "/Users/ir-home/Projects/2026/nomad-ai/nomad-inventory/Nomad Inventory/ios/sync_to_xcode.sh"

SRC="/Users/ir-home/Projects/2026/nomad-ai/nomad-inventory/Nomad Inventory/ios/NomadInventory"
DEST="/Users/ir-home/Projects/2026/nomad-ai/nomad-inventory/Nomad Inventory/Nomad Inventory/Nomad Inventory"

echo "SRC:  $SRC"
echo "DEST: $DEST"
echo ""

if [ ! -d "$DEST" ]; then
    echo "❌ DEST not found. Run this to find the right path:"
    echo "   find \"/Users/ir-home/Projects\" -name \"NomadInventoryApp.swift\" 2>/dev/null"
    exit 1
fi

cp -v "$SRC/App/NomadInventoryApp.swift"     "$DEST/App/"
cp -v "$SRC/App/ContentView.swift"           "$DEST/App/"
cp -v "$SRC/Models/Item.swift"               "$DEST/Models/"
cp -v "$SRC/Models/MovingBox.swift"          "$DEST/Models/"
cp -v "$SRC/Models/ItemCategory.swift"       "$DEST/Models/"
cp -v "$SRC/Services/AIService.swift"        "$DEST/Services/"
cp -v "$SRC/Services/CameraService.swift"    "$DEST/Services/"
cp -v "$SRC/Services/QRCodeService.swift"    "$DEST/Services/"
cp -v "$SRC/Services/LocalizationManager.swift" "$DEST/Services/"
cp -v "$SRC/Views/Inventory/InventoryView.swift"   "$DEST/Views/Inventory/"
cp -v "$SRC/Views/Inventory/ItemRowView.swift"      "$DEST/Views/Inventory/"
cp -v "$SRC/Views/Inventory/ItemDetailView.swift"   "$DEST/Views/Inventory/"
cp -v "$SRC/Views/Boxes/BoxesView.swift"     "$DEST/Views/Boxes/"
cp -v "$SRC/Views/Boxes/BoxDetailView.swift" "$DEST/Views/Boxes/"
cp -v "$SRC/Views/Boxes/QRCodeView.swift"    "$DEST/Views/Boxes/"
cp -v "$SRC/Views/Scan/ScanView.swift"       "$DEST/Views/Scan/"
cp -v "$SRC/Views/Scan/CameraPreview.swift"  "$DEST/Views/Scan/"
cp -v "$SRC/Views/Scan/ItemConfirmView.swift" "$DEST/Views/Scan/"
cp -v "$SRC/Views/Shared/AddItemView.swift"  "$DEST/Views/Shared/"
cp -v "$SRC/Views/Shared/SettingsView.swift" "$DEST/Views/Shared/"

echo ""
echo "✅ Done — press Cmd+R in Xcode"
