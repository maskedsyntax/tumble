import Testing
import Foundation
@testable import TumbleKit

struct PostcardTests {
    // MARK: Note limits

    @Test func noteClampsToMaxLength() {
        let long = String(repeating: "a", count: PostcardNote.maxLength + 20)
        #expect(PostcardNote.clamp(long).count == PostcardNote.maxLength)
    }

    @Test func noteFlattensNewlines() {
        #expect(PostcardNote.clamp("hello\nthere") == "hello there")
    }

    @Test func noteKeepsShortTextIntact() {
        #expect(PostcardNote.clamp("wish you were here") == "wish you were here")
    }

    // MARK: Frame style persistence + migration

    @Test func storedStyleDefaultsToNone() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        #expect(PostcardFrameStyle.stored(defaults: defaults) == .none)
    }

    @Test func storedStyleMigratesLegacyToggleOn() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defaults.set(true, forKey: "tumble.saveIncludesPostcardFrame")
        #expect(PostcardFrameStyle.stored(defaults: defaults) == .classicInstant)
        // Migration is one-shot: the legacy key is consumed.
        #expect(defaults.object(forKey: "tumble.saveIncludesPostcardFrame") == nil)
        #expect(defaults.string(forKey: PostcardFrameStyle.storageKey) == PostcardFrameStyle.classicInstant.rawValue)
    }

    @Test func storedStyleMigratesLegacyToggleOff() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defaults.set(false, forKey: "tumble.saveIncludesPostcardFrame")
        #expect(PostcardFrameStyle.stored(defaults: defaults) == .none)
    }

    @Test func storedStylePrefersCurrentKey() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defaults.set(true, forKey: "tumble.saveIncludesPostcardFrame")
        defaults.set(PostcardFrameStyle.vintagePostcard.rawValue, forKey: PostcardFrameStyle.storageKey)
        #expect(PostcardFrameStyle.stored(defaults: defaults) == .vintagePostcard)
    }

    // MARK: Stable seeds

    @Test func uuidSeedIsDeterministic() {
        let id = UUID()
        #expect(id.stableSeed == id.stableSeed)
    }

    @Test func uuidSeedDiffersAcrossIDs() {
        #expect(UUID().stableSeed != UUID().stableSeed)
    }

    @Test func stableRandomIsDeterministic() {
        var a = StableRandom(seed: 42)
        var b = StableRandom(seed: 42)
        #expect(a.next() == b.next())
        #expect(a.next() == b.next())
    }
}
