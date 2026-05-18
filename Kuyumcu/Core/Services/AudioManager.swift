import AVFoundation
import Combine

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

    // MARK: - Private

    private var generalPlayer: AVAudioPlayer?
    private var counterPlayer: AVAudioPlayer?
    private var isOnCounterScreen = false

    // MARK: - Init

    private init() {
        // İlk kurulumda her iki müzik de açık başlar
        isGeneralMusicEnabled = UserDefaults.standard.object(forKey: "gdl_generalMusic") as? Bool ?? true
        isCounterMusicEnabled = UserDefaults.standard.object(forKey: "gdl_counterMusic") as? Bool ?? true

        configureAudioSession()
        setupPlayers()
    }

    // MARK: - Setup

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func setupPlayers() {
        generalPlayer = makePlayer(resource: "music_general", volume: 0.40)
        counterPlayer = makePlayer(resource: "music_counter",  volume: 0.50)
    }

    private func makePlayer(resource: String, volume: Float) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3")
                     ?? Bundle.main.url(forResource: resource, withExtension: "m4a")
                     ?? Bundle.main.url(forResource: resource, withExtension: "wav")
        else { return nil }
        let player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1   // sonsuz döngü
        player?.volume = volume
        player?.prepareToPlay()
        return player
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
}
