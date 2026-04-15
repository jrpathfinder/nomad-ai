#!/bin/bash
# Syncs the git repo source files into the Xcode project folder.
# Run this from Terminal after every git pull:
#   bash sync_to_xcode.sh

REPO="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC="$REPO/NomadInventory"

# ── Find the Xcode project folder automatically ──────────────────────────────
XCODE_ROOT=$(find "$HOME/Projects" -name "*.xcodeproj" -maxdepth 6 2>/dev/null | grep -i "nomad" | head -1 | xargs dirname)

if [ -z "$XCODE_ROOT" ]; then
    echo "❌ Could not find Nomad Inventory.xcodeproj under ~/Projects"
    echo "   Set DEST manually at the top of this script."
    exit 1
fi

# Xcode copies files into a subfolder matching the project name
DEST="$XCODE_ROOT/Nomad Inventory"

echo "📂 Source : $SRC"
echo "📂 Dest   : $DEST"
echo ""

if [ ! -d "$DEST" ]; then
    echo "❌ Destination folder not found: $DEST"
    exit 1
fi

# ── Copy all Swift source folders ────────────────────────────────────────────
copy_folder() {
    local folder=$1
    if [ -d "$SRC/$folder" ]; then
        cp -Rv "$SRC/$folder/"* "$DEST/$folder/" 2>/dev/null && \
            echo "✅ Synced $folder" || \
            echo "⚠️  $folder — destination missing (create it in Xcode first)"
    fi
}

copy_folder "App"
copy_folder "Models"
copy_folder "Services"
copy_folder "Views/Inventory"
copy_folder "Views/Boxes"
copy_folder "Views/Scan"
copy_folder "Views/Shared"

echo ""
echo "✅ Done — press Cmd+R in Xcode to rebuild."
