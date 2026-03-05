import SwiftUI
import Carbon.HIToolbox

/// A button that records the next key combination pressed by the user.
/// Click once to enter recording mode; press any key+modifier combo to set it,
/// or press Escape to cancel.
struct KeyRecorderButton: View {
    @Binding var config: HotkeyConfig

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(isRecording ? "Press shortcut…" : config.displayString)
                .monospacedDigit()
                .frame(minWidth: 80)
        }
        .buttonStyle(.bordered)
        .foregroundColor(isRecording ? .accentColor : .primary)
        .onDisappear(perform: stopRecording)
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }
            let mods = carbonModifiers(from: event.modifierFlags)
            guard mods != 0 else { return event }  // require at least one modifier
            config = HotkeyConfig(keyCode: Int(event.keyCode), modifiers: mods)
            stopRecording()
            HotkeyManager.shared.reregisterAll()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var mods = 0
        if flags.contains(.command) { mods |= cmdKey }
        if flags.contains(.option)  { mods |= optionKey }
        if flags.contains(.control) { mods |= controlKey }
        if flags.contains(.shift)   { mods |= shiftKey }
        return mods
    }
}
