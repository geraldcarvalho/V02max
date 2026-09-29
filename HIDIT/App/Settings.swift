import Foundation
import HIDITCore

enum SoundMode: String, CaseIterable {
    case on
    case off
    case voice
}

/// Persisted user settings and workout choices.
@MainActor
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var sound: SoundMode { didSet { defaults.set(sound.rawValue, forKey: Keys.sound) } }
    @Published var haptics: Bool { didSet { defaults.set(haptics, forKey: Keys.haptics) } }
    @Published var volumeBoost: Bool { didSet { defaults.set(volumeBoost, forKey: Keys.boost) } }
    @Published var countdownTicks: Bool { didSet { defaults.set(countdownTicks, forKey: Keys.ticks) } }
    @Published var countdownLength: Int { didSet { defaults.set(countdownLength, forKey: Keys.countdown) } }
    @Published var selectedPreset: Preset { didSet { defaults.set(selectedPreset.rawValue, forKey: Keys.preset) } }
    @Published var hidit: HIDITConfig { didSet { save(hidit, Keys.hidit) } }
    @Published var custom: CustomConfig { didSet { save(custom, Keys.custom) } }
    @Published var hasSeenHealthNote: Bool { didSet { defaults.set(hasSeenHealthNote, forKey: Keys.health) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sound = SoundMode(rawValue: defaults.string(forKey: Keys.sound) ?? "") ?? .on
        haptics = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        volumeBoost = defaults.object(forKey: Keys.boost) as? Bool ?? false
        countdownTicks = defaults.object(forKey: Keys.ticks) as? Bool ?? true
        let cd = defaults.object(forKey: Keys.countdown) as? Int ?? 10
        countdownLength = Schedule.allowedCountdowns.contains(cd) ? cd : 10
        selectedPreset = Preset(rawValue: defaults.string(forKey: Keys.preset) ?? "") ?? .hidit
        hidit = Self.load(HIDITConfig.self, Keys.hidit, defaults)?.clamped() ?? .default
        custom = Self.load(CustomConfig.self, Keys.custom, defaults)?.clamped() ?? .default
        hasSeenHealthNote = defaults.bool(forKey: Keys.health)
    }

    var intervals: [Interval] { selectedPreset.intervals(hidit: hidit, custom: custom) }

    private func save<T: Encodable>(_ value: T, _ key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, _ key: String, _ defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private enum Keys {
        static let sound = "sound"
        static let haptics = "haptics"
        static let boost = "volumeBoost"
        static let ticks = "countdownTicks"
        static let countdown = "countdownLength"
        static let preset = "selectedPreset"
        static let hidit = "hiditConfig"
        static let custom = "customConfig"
        static let health = "hasSeenHealthNote"
    }
}
