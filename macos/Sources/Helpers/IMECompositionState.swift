/// Tracks the input source that owns an unfinished IME composition.
/// A commit from that composition after switching sources is cancellation,
/// rather than text that should be sent to the terminal.
struct IMECompositionState {
    private var isComposing = false
    private var inputSourceID: String?

    mutating func update(hasMarkedText: Bool, inputSourceID: String?) {
        guard hasMarkedText else {
            reset()
            return
        }

        // Keep the original source across candidate/preedit updates, including
        // updates delivered while the system is switching input sources.
        if !isComposing {
            self.inputSourceID = inputSourceID
            isComposing = true
        }
    }

    func shouldDiscardCommit(currentInputSourceID: String?) -> Bool {
        guard isComposing,
              let inputSourceID,
              let currentInputSourceID else { return false }
        return inputSourceID != currentInputSourceID
    }

    mutating func reset() {
        isComposing = false
        inputSourceID = nil
    }
}
