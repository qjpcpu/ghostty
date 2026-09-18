import Testing
@testable import Ghostty

struct IMECompositionStateTests {
    private let pinyin = "com.bytedance.inputmethod.doubaoime.pinyin"
    private let abc = "com.apple.keylayout.ABC"

    @Test func discardsUnconfirmedPinyinAfterSwitchingToABC() {
        var state = IMECompositionState()
        state.update(hasMarkedText: true, inputSourceID: pinyin)
        state.update(hasMarkedText: true, inputSourceID: pinyin)
        #expect(state.shouldDiscardCommit(currentInputSourceID: abc))
        state.reset()
        // Subsequent ordinary typing must not be swallowed.
        #expect(!state.shouldDiscardCommit(currentInputSourceID: abc))
    }

    @Test func preservesExplicitCandidateConfirmation() {
        var state = IMECompositionState()
        state.update(hasMarkedText: true, inputSourceID: pinyin)
        #expect(!state.shouldDiscardCommit(currentInputSourceID: pinyin))
        state.reset()
        state.update(hasMarkedText: true, inputSourceID: pinyin)
        #expect(!state.shouldDiscardCommit(currentInputSourceID: pinyin))
    }

    @Test func latePreeditUpdatesDoNotTransferOwnership() {
        var state = IMECompositionState()
        state.update(hasMarkedText: true, inputSourceID: pinyin)
        state.update(hasMarkedText: true, inputSourceID: abc)
        #expect(state.shouldDiscardCommit(currentInputSourceID: abc))
    }

    @Test func cancelledCompositionDoesNotAffectANewOne() {
        var state = IMECompositionState()
        state.update(hasMarkedText: true, inputSourceID: pinyin)
        state.update(hasMarkedText: false, inputSourceID: pinyin)
        #expect(!state.shouldDiscardCommit(currentInputSourceID: abc))
        state.update(hasMarkedText: true, inputSourceID: abc)
        #expect(!state.shouldDiscardCommit(currentInputSourceID: abc))
        #expect(state.shouldDiscardCommit(currentInputSourceID: pinyin))
    }

    @Test func preservesTextWhenSourceIdentityIsUnavailable() {
        var state = IMECompositionState()
        state.update(hasMarkedText: true, inputSourceID: nil)
        #expect(!state.shouldDiscardCommit(currentInputSourceID: abc))
        state.reset()
        state.update(hasMarkedText: true, inputSourceID: pinyin)
        #expect(!state.shouldDiscardCommit(currentInputSourceID: nil))
    }
}
