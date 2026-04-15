import SwiftUI

// MARK: - Supported languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .russian: return "🇷🇺"
        }
    }
}

// MARK: - Manager (inject as @EnvironmentObject)

final class LocalizationManager: ObservableObject {
    @AppStorage("app_language") var languageCode: String = "en" {
        didSet { objectWillChange.send() }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageCode) ?? .english }
        set { languageCode = newValue.rawValue }
    }

    func s(_ key: LocalizedKey) -> String {
        key.string(for: language)
    }
}

// MARK: - All localised strings

enum LocalizedKey {
    // Tabs
    case tabInventory, tabBoxes, tabScan, tabSettings

    // Inventory
    case inventoryTitle, inventoryEmpty, inventoryEmptySub
    case searchPlaceholder, filterAll, noItems

    // Boxes
    case boxesTitle, boxesEmpty, boxesEmptySub, createFirstBox
    case newBox, boxDetails, boxName, boxLocation, boxDescription
    case labelColour, addItem, sealed, unseal, sealBox, items
    case showQRCode, notInBox

    // Scan
    case scanTitle, identifying, retake, confirmItem, aiIdentified
    case aiFailed, checkSettings

    // Item detail
    case editItem, saveItem, qrCode, scanToIdentify, shareQR
    case added, updated, tags, noTags, category, box, description
    case close, edit, save, cancel, delete

    // Add item
    case newItem, itemName, choosePhoto, assignBox, noBox

    // Categories
    case catElectronics, catClothing, catKitchen, catFurniture
    case catBooks, catDocuments, catTools, catToys, catSports
    case catBathroom, catBedroom, catDecoration, catFood, catOther

    // Settings
    case settingsTitle, languageSection, languageLabel
    case apiKeySection, apiKeyLabel, apiKeyPlaceholder
    case saveApiKey, saved, removeApiKey, testConnection
    case testing, keyStored, noKeySaved
    case debugSection, keyLength

    // QR
    case qrLabel, printLabel, share

    // Errors
    case errorCamera, errorCameraMsg, openSettings

    func string(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return english
        case .russian: return russian
        }
    }

    private var english: String {
        switch self {
        case .tabInventory:     return "Inventory"
        case .tabBoxes:         return "Boxes"
        case .tabScan:          return "Scan"
        case .tabSettings:      return "Settings"
        case .inventoryTitle:   return "Inventory"
        case .inventoryEmpty:   return "No items yet"
        case .inventoryEmptySub: return "Tap Scan to photograph items,\nor tap + to add manually."
        case .searchPlaceholder: return "Search items…"
        case .filterAll:        return "All"
        case .noItems:          return "No items"
        case .boxesTitle:       return "Boxes"
        case .boxesEmpty:       return "No boxes yet"
        case .boxesEmptySub:    return "Create boxes to organise your items\nand generate QR code labels."
        case .createFirstBox:   return "Create first box"
        case .newBox:           return "New Box"
        case .boxDetails:       return "Box Details"
        case .boxName:          return "Box name (e.g. Kitchen 1)"
        case .boxLocation:      return "Location (e.g. Living Room)"
        case .boxDescription:   return "Description (optional)"
        case .labelColour:      return "Label Colour"
        case .addItem:          return "Add Item"
        case .sealed:           return "Sealed"
        case .unseal:           return "Unseal"
        case .sealBox:          return "Seal box"
        case .items:            return "items"
        case .showQRCode:       return "Show QR Code Label"
        case .notInBox:         return "Not assigned to any box"
        case .scanTitle:        return "Scan Item"
        case .identifying:      return "Identifying…"
        case .retake:           return "Retake"
        case .confirmItem:      return "Confirm Item"
        case .aiIdentified:     return "AI identified with"
        case .aiFailed:         return "AI recognition failed"
        case .checkSettings:    return "Check Settings → enter your API key"
        case .editItem:         return "Edit Item"
        case .saveItem:         return "Save"
        case .qrCode:           return "QR Code"
        case .scanToIdentify:   return "Scan to identify this item"
        case .shareQR:          return "Share QR"
        case .added:            return "Added"
        case .updated:          return "Updated"
        case .tags:             return "Tags"
        case .noTags:           return "No tags"
        case .category:         return "Category"
        case .box:              return "Box"
        case .description:      return "Description"
        case .close:            return "Close"
        case .edit:             return "Edit"
        case .save:             return "Save"
        case .cancel:           return "Cancel"
        case .delete:           return "Delete"
        case .newItem:          return "New Item"
        case .itemName:         return "Item name"
        case .choosePhoto:      return "Choose photo"
        case .assignBox:        return "Assign to box"
        case .noBox:            return "No box"
        case .catElectronics:   return "Electronics"
        case .catClothing:      return "Clothing"
        case .catKitchen:       return "Kitchen"
        case .catFurniture:     return "Furniture"
        case .catBooks:         return "Books"
        case .catDocuments:     return "Documents"
        case .catTools:         return "Tools"
        case .catToys:          return "Toys"
        case .catSports:        return "Sports"
        case .catBathroom:      return "Bathroom"
        case .catBedroom:       return "Bedroom"
        case .catDecoration:    return "Decoration"
        case .catFood:          return "Food"
        case .catOther:         return "Other"
        case .settingsTitle:    return "Settings"
        case .languageSection:  return "Language"
        case .languageLabel:    return "App Language"
        case .apiKeySection:    return "Anthropic API Key"
        case .apiKeyLabel:      return "API Key"
        case .apiKeyPlaceholder: return "sk-ant-..."
        case .saveApiKey:       return "Save API Key"
        case .saved:            return "Saved!"
        case .removeApiKey:     return "Remove API Key"
        case .testConnection:   return "Test API Connection"
        case .testing:          return "Testing…"
        case .keyStored:        return "API key saved"
        case .noKeySaved:       return "No key saved. Get one free at console.anthropic.com"
        case .debugSection:     return "Debug Info"
        case .keyLength:        return "Stored key length"
        case .qrLabel:          return "QR Code"
        case .printLabel:       return "Share / Print Label"
        case .share:            return "Share"
        case .errorCamera:      return "Camera Access Required"
        case .errorCameraMsg:   return "Please allow camera access in Settings to scan items."
        case .openSettings:     return "Open Settings"
        }
    }

    private var russian: String {
        switch self {
        case .tabInventory:     return "Инвентарь"
        case .tabBoxes:         return "Коробки"
        case .tabScan:          return "Сканировать"
        case .tabSettings:      return "Настройки"
        case .inventoryTitle:   return "Инвентарь"
        case .inventoryEmpty:   return "Нет предметов"
        case .inventoryEmptySub: return "Нажмите «Сканировать» для фото,\nили + для добавления вручную."
        case .searchPlaceholder: return "Поиск предметов…"
        case .filterAll:        return "Все"
        case .noItems:          return "Нет предметов"
        case .boxesTitle:       return "Коробки"
        case .boxesEmpty:       return "Нет коробок"
        case .boxesEmptySub:    return "Создайте коробки для организации вещей\nи генерации QR-кодов."
        case .createFirstBox:   return "Создать первую коробку"
        case .newBox:           return "Новая коробка"
        case .boxDetails:       return "Детали коробки"
        case .boxName:          return "Название (напр. Кухня 1)"
        case .boxLocation:      return "Место (напр. Гостиная)"
        case .boxDescription:   return "Описание (необязательно)"
        case .labelColour:      return "Цвет ярлыка"
        case .addItem:          return "Добавить предмет"
        case .sealed:           return "Запечатана"
        case .unseal:           return "Распечатать"
        case .sealBox:          return "Запечатать коробку"
        case .items:            return "предметов"
        case .showQRCode:       return "Показать QR-код"
        case .notInBox:         return "Не в коробке"
        case .scanTitle:        return "Сканировать"
        case .identifying:      return "Определяю…"
        case .retake:           return "Переснять"
        case .confirmItem:      return "Подтвердить"
        case .aiIdentified:     return "ИИ определил с точностью"
        case .aiFailed:         return "ИИ не смог определить"
        case .checkSettings:    return "Проверьте Настройки → введите API-ключ"
        case .editItem:         return "Редактировать"
        case .saveItem:         return "Сохранить"
        case .qrCode:           return "QR-код"
        case .scanToIdentify:   return "Сканируйте для определения"
        case .shareQR:          return "Поделиться QR"
        case .added:            return "Добавлено"
        case .updated:          return "Изменено"
        case .tags:             return "Метки"
        case .noTags:           return "Нет меток"
        case .category:         return "Категория"
        case .box:              return "Коробка"
        case .description:      return "Описание"
        case .close:            return "Закрыть"
        case .edit:             return "Изменить"
        case .save:             return "Сохранить"
        case .cancel:           return "Отмена"
        case .delete:           return "Удалить"
        case .newItem:          return "Новый предмет"
        case .itemName:         return "Название предмета"
        case .choosePhoto:      return "Выбрать фото"
        case .assignBox:        return "Назначить коробку"
        case .noBox:            return "Без коробки"
        case .catElectronics:   return "Электроника"
        case .catClothing:      return "Одежда"
        case .catKitchen:       return "Кухня"
        case .catFurniture:     return "Мебель"
        case .catBooks:         return "Книги"
        case .catDocuments:     return "Документы"
        case .catTools:         return "Инструменты"
        case .catToys:          return "Игрушки"
        case .catSports:        return "Спорт"
        case .catBathroom:      return "Ванная"
        case .catBedroom:       return "Спальня"
        case .catDecoration:    return "Декор"
        case .catFood:          return "Еда"
        case .catOther:         return "Другое"
        case .settingsTitle:    return "Настройки"
        case .languageSection:  return "Язык"
        case .languageLabel:    return "Язык приложения"
        case .apiKeySection:    return "API-ключ Anthropic"
        case .apiKeyLabel:      return "API-ключ"
        case .apiKeyPlaceholder: return "sk-ant-..."
        case .saveApiKey:       return "Сохранить ключ"
        case .saved:            return "Сохранено!"
        case .removeApiKey:     return "Удалить API-ключ"
        case .testConnection:   return "Проверить соединение"
        case .testing:          return "Проверяю…"
        case .keyStored:        return "Ключ сохранён"
        case .noKeySaved:       return "Ключ не задан. Получите на console.anthropic.com"
        case .debugSection:     return "Диагностика"
        case .keyLength:        return "Длина ключа"
        case .qrLabel:          return "QR-код"
        case .printLabel:       return "Поделиться / Распечатать"
        case .share:            return "Поделиться"
        case .errorCamera:      return "Нет доступа к камере"
        case .errorCameraMsg:   return "Разрешите доступ к камере в Настройках."
        case .openSettings:     return "Открыть настройки"
        }
    }
}
