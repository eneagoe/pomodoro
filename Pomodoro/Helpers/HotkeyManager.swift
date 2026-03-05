import Foundation
import Carbon.HIToolbox

// MARK: - HotkeyConfig

struct HotkeyConfig: Codable, Equatable {
    var keyCode: Int
    var modifiers: Int   // Carbon modifier flags (cmdKey | optionKey | controlKey etc.)

    static let defaultStart  = HotkeyConfig(keyCode: kVK_UpArrow,    modifiers: cmdKey | optionKey | controlKey)
    static let defaultPause  = HotkeyConfig(keyCode: kVK_LeftArrow,  modifiers: cmdKey | optionKey | controlKey)
    static let defaultResume = HotkeyConfig(keyCode: kVK_RightArrow, modifiers: cmdKey | optionKey | controlKey)

    var displayString: String {
        var s = ""
        if modifiers & controlKey != 0 { s += "⌃" }
        if modifiers & optionKey  != 0 { s += "⌥" }
        if modifiers & cmdKey     != 0 { s += "⌘" }
        if modifiers & shiftKey   != 0 { s += "⇧" }
        s += keySymbol
        return s
    }

    private var keySymbol: String {
        switch keyCode {
        case kVK_UpArrow:    return "↑"
        case kVK_DownArrow:  return "↓"
        case kVK_LeftArrow:  return "←"
        case kVK_RightArrow: return "→"
        case kVK_Return:     return "↩"
        case kVK_Escape:     return "⎋"
        case kVK_Tab:        return "⇥"
        case kVK_Space:      return "Space"
        case kVK_Delete:     return "⌫"
        case kVK_ForwardDelete: return "⌦"
        default:             return layoutChar ?? "[\(keyCode)]"
        }
    }

    private var layoutChar: String? {
        let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeRetainedValue()
        guard let dataRef = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(dataRef).takeUnretainedValue() as Data
        return data.withUnsafeBytes { ptr -> String? in
            guard let layout = ptr.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else { return nil }
            var dead: UInt32 = 0
            var len = 0
            var chars = [UniChar](repeating: 0, count: 4)
            let err = UCKeyTranslate(layout, UInt16(keyCode), UInt16(kUCKeyActionDisplay),
                                     0, UInt32(LMGetKbdType()),
                                     UInt32(kUCKeyTranslateNoDeadKeysBit),
                                     &dead, 4, &len, &chars)
            guard err == noErr, len > 0 else { return nil }
            return String(utf16CodeUnits: chars, count: len).uppercased()
        }
    }
}

// MARK: - HotkeyManager

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventHandlerRef: EventHandlerRef?
    private var registeredRefs: [UInt32: EventHotKeyRef] = [:]

    private init() {}

    func setup() {
        installEventHandler()
        reregisterAll()
    }

    func reregisterAll() {
        for (_, ref) in registeredRefs { UnregisterEventHotKey(ref) }
        registeredRefs = [:]
        let p = Preferences.shared
        register(id: 1, config: p.hotkeyStart)
        register(id: 2, config: p.hotkeyPause)
        register(id: 3, config: p.hotkeyResume)
    }

    private func register(id: UInt32, config: HotkeyConfig) {
        let hkID = EventHotKeyID(signature: pomFourCC, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(config.keyCode), UInt32(config.modifiers),
            hkID, GetApplicationEventTarget(), 0, &ref
        )
        if status == noErr, let ref { registeredRefs[id] = ref }
    }

    private func installEventHandler() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            pomHotKeyCallback,
            1, &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    fileprivate func handleHotkey(id: UInt32) {
        let t = PomodoroTimer.shared
        switch id {
        case 1: if t.state == .idle || t.state == .finished { t.start() }
        case 2: if t.state == .running { t.pause() }
        case 3: if t.state == .paused  { t.start() }
        default: break
        }
    }
}

// MARK: - C callback (must be top-level, non-capturing)

private let pomFourCC: FourCharCode = {
    "POMR".unicodeScalars.reduce(0) { ($0 << 8) + FourCharCode($1.value) }
}()

private func pomHotKeyCallback(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hkID = EventHotKeyID()
    GetEventParameter(event, UInt32(kEventParamDirectObject), UInt32(typeEventHotKeyID),
                      nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
    let mgr = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async { mgr.handleHotkey(id: hkID.id) }
    return noErr
}
