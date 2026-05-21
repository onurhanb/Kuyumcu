import AVFoundation
import Combine

enum SoundEffect: String, CaseIterable {
    case buttonTap = "sfx_button_tap"
    case dealSuccess = "sfx_deal_success"
    case dealFail = "sfx_deal_fail"
    case bargain = "sfx_bargain"
    case purchase = "sfx_purchase"
    case passiveCollect = "sfx_passive_collect"
}

/// Merkezi müzik yöneticisi.
/// Genel tema müziği (music_general) ve tezgah müziği (music_counter) olmak üzere
/// iki ayrı parça çalar. Profil ekranındaki toggle'lardan kontrol edilir.
class AudioManager: ObservableObject {

    static let shared = AudioManager()

    // MARK: - Published

    @Published var isGeneralMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGeneralMusicEnabled, forKey: "gdl_generalMusic")
            if isGeneralMusicEnabled {
                if !isOnCounterScreen { generalPlayer?.play() }
            } else {
                if !isOnCounterScreen { generalPlayer?.pause() }
            }
        }
    }

    @Published var isCounterMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCounterMusicEnabled, forKey: "gdl_counterMusic")
            if isOnCounterScreen {
                if isCounterMusicEnabled { counterPlayer?.play() }
                else                     { counterPlayer?.pause() }
            }
        }
    }

    @Published var isSoundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEffectsEnabled, forKey: "gdl_soundEffects")
        }
    }

    // MARK: - Private

    private var generalPlayer: AVAudioPlayer?
    private var counterPlayer: AVAudioPlayer?
    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var isOnCounterScreen = false

    // MARK: - Init

    private init() {
        // İlk kurulumda her iki müzik de açık başlar
        isGeneralMusicEnabled = UserDefaults.standard.object(forKey: "gdl_generalMusic") as? Bool ?? true
        isCounterMusicEnabled = UserDefaults.standard.object(forKey: "gdl_counterMusic") as? Bool ?? true
        isSoundEffectsEnabled = UserDefaults.standard.object(forKey: "gdl_soundEffects") as? Bool ?? true

        configureAudioSession()
        setupPlayers()
    }

    // MARK: - Setup

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func setupPlayers() {
        generalPlayer = makePlayer(resource: "music_general", volume: 0.15, loops: -1)
        counterPlayer = makePlayer(resource: "music_counter",  volume: 0.20, loops: -1)

        for effect in SoundEffect.allCases {
            effectPlayers[effect] = makePlayer(
                resource: effect.rawValue,
                volume: volume(for: effect),
                loops: 0
            )
        }
    }

    private func makePlayer(resource: String, volume: Float, loops: Int) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3")
                     ?? Bundle.main.url(forResource: resource, withExtension: "m4a")
                     ?? Bundle.main.url(forResource: resource, withExtension: "wav")
        else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = loops
        player?.volume = volume
        player?.prepareToPlay()
        return player
    }

    private func volume(for effect: SoundEffect) -> Float {
        switch effect {
        case .buttonTap:      return 0.20
        case .dealSuccess:    return 0.38
        case .dealFail:       return 0.34
        case .bargain:        return 0.30
        case .purchase:       return 0.36
        case .passiveCollect: return 0.38
        }
    }

    // MARK: - Public API

    /// Ana ekranlar açıldığında çağrılır (tezgah dışı tüm sekmeler).
    func enterGeneralScreen() {
        isOnCounterScreen = false
        counterPlayer?.pause()
        counterPlayer?.currentTime = 0
        if isGeneralMusicEnabled { generalPlayer?.play() }
    }

    /// Tezgah (CounterView) açıldığında çağrılır.
    func enterCounterScreen() {
        isOnCounterScreen = true
        generalPlayer?.pause()
        if isCounterMusicEnabled { counterPlayer?.play() }
    }

    /// Tezgah (CounterView) kapandığında çağrılır.
    func exitCounterScreen() {
        isOnCounterScreen = false
        counterPlayer?.pause()
        counterPlayer?.currentTime = 0
        if isGeneralMusicEnabled { generalPlayer?.play() }
    }

    func playEffect(_ effect: SoundEffect) {
        guard isSoundEffectsEnabled, let player = effectPlayers[effect] else { return }
        player.currentTime = 0
        player.play()
    }
}
