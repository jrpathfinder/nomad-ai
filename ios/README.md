# Nomad Inventory – iOS App

An AI-powered home inventory app for tracking belongings during a move.

## Features

| Feature | Description |
|---|---|
| **Camera scan** | Point camera at any item — AI identifies it automatically |
| **Smart catalogue** | Items saved with name, photo, category, description, tags |
| **Box management** | Create labelled boxes and assign items to them |
| **QR code labels** | Generate a printable QR label for each box |
| **Quick search** | Filter by category or search by name/tag |
| **Share & print** | Share QR label via AirDrop, print, or save to Photos |

## Requirements

- Xcode 15+
- iOS 17+ (SwiftData)
- An [Anthropic API key](https://console.anthropic.com) for AI identification

## Project Setup in Xcode

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - Product Name: `NomadInventory`
   - Bundle ID: `com.nomad.inventory`
   - Interface: **SwiftUI**
   - Storage: **SwiftData**
4. Delete the auto-generated `ContentView.swift`
5. Drag the entire `NomadInventory/` folder into the Xcode project navigator
6. Make sure **"Copy items if needed"** is checked and all targets are selected
7. In project settings → **Info** tab, add:
   - Key: `ANTHROPIC_API_KEY`  Value: your Anthropic API key  
   *(or set it as an Xcode build variable for security)*

## Architecture

```
NomadInventory/
├── App/
│   ├── NomadInventoryApp.swift   # @main entry, ModelContainer setup
│   └── ContentView.swift         # Tab bar (Inventory | Boxes | Scan)
├── Models/
│   ├── Item.swift                # SwiftData model — individual item
│   ├── MovingBox.swift           # SwiftData model — packing box
│   └── ItemCategory.swift        # Enum with icon, color, AI suggestion
├── Services/
│   ├── CameraService.swift       # AVFoundation camera session
│   ├── AIService.swift           # Claude Vision API (object identification)
│   └── QRCodeService.swift       # CoreImage QR generation + printable label
└── Views/
    ├── Inventory/
    │   ├── InventoryView.swift   # Filterable item list
    │   ├── ItemRowView.swift     # Row cell
    │   └── ItemDetailView.swift  # Detail + edit
    ├── Boxes/
    │   ├── BoxesView.swift       # Box grid + AddBoxView sheet
    │   ├── BoxDetailView.swift   # Box contents + actions
    │   └── QRCodeView.swift      # QR display + share
    ├── Scan/
    │   ├── ScanView.swift        # Live camera + shutter
    │   ├── CameraPreview.swift   # UIKit AVCaptureVideoPreviewLayer bridge
    │   └── ItemConfirmView.swift # Review AI result, edit, save
    └── Shared/
        └── AddItemView.swift     # Manual add / photo picker form
```

## How It Works

### Scanning Flow
1. Tap **Scan** tab → live camera preview opens
2. Point at an item and tap the shutter button
3. Photo is sent to **Claude Vision** (`claude-opus-4-6`)
4. AI returns name, category, description and tags in JSON
5. Review screen lets you confirm or edit before saving

### QR Code Flow
1. Create a box in the **Boxes** tab
2. Open the box → tap **Show QR Code Label**
3. Share/print the label and stick it on the physical box
4. Scan the QR with any QR reader to see box ID, name, and location
5. Open the app and navigate to the box to see full contents

## AI Identification

The app sends a JPEG (max 1024 px) to `https://api.anthropic.com/v1/messages` with a structured prompt that requests JSON output:

```json
{
  "name": "Laptop",
  "description": "Silver MacBook Pro with charger",
  "category": "Electronics",
  "tags": ["apple", "laptop", "work"],
  "confidence": 0.95
}
```

If the API key is missing or the network fails, the app falls back to a manual entry form so no data is lost.
