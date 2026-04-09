import Flutter
import UIKit
import Combine

/**
 * AppDelegate with Screen Protection implementation for iOS
 *
 * ARCHITECTURE:
 * - Uses UIScreen.capturedDidChangeNotification for screen recording detection
 * - Uses UIApplication.userDidTakeScreenshotNotification for screenshot detection
 * - Uses blur overlay views for app switcher protection
 * - Provides best-effort protection (iOS has no true blocking API)
 *
 * SECURITY LIMITATIONS (iOS):
 * - Screenshots cannot be blocked, only detected after the fact
 * - Screen recording cannot be blocked, only detected with ~1-2s latency
 * - App switcher thumbnail cannot be hidden, only blurred
 * - No hardware-level protection API exists on iOS
 *
 * PLATFORM CHANNELS:
 * - MethodChannel: com.learnoo.screen_protection (commands)
 * - EventChannel: com.learnoo.screen_protection/events (streaming events)
 */
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    
    // Screen protection handler
    private var screenProtection: ScreenProtectionManager?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize screen protection manager
        screenProtection = ScreenProtectionManager()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        
        // Setup screen protection channels after engine is ready
        screenProtection?.setupChannels(with: engineBridge.pluginRegistry as! FlutterPluginRegistry)
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        // App is about to become inactive (app switcher, call, etc.)
        screenProtection?.handleAppWillResignActive()
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        // App is back in foreground
        screenProtection?.handleAppDidBecomeActive()
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        // App is in background - show protection overlay
        screenProtection?.handleAppDidEnterBackground()
    }
    
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        // App is coming to foreground - hide protection overlay
        screenProtection?.handleAppWillEnterForeground()
    }
}

/**
 * ScreenProtectionManager handles all iOS screen protection logic
 */
class ScreenProtectionManager: NSObject {
    
    // Channel names
    private let methodChannelName = "com.learnoo.screen_protection"
    private let eventChannelName = "com.learnoo.screen_protection/events"
    
    // Channel references
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    // State tracking
    private var isGlobalEnabled = false
    private var localProtectionCount = 0
    private var isBlurOverlayEnabled = false
    private var blurRadius: CGFloat = 20.0
    
    // UI components
    private var protectionWindow: UIWindow?
    private var blurView: UIVisualEffectView?
    private var protectionLabel: UILabel?
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup
    
    func setupChannels(with registry: FlutterPluginRegistry) {
        guard let controller = registry.registrar(forPlugin: "ScreenProtection")?.messenger() else {
            print("[ScreenProtection] Failed to get messenger")
            return
        }
        
        // Setup method channel
        methodChannel = FlutterMethodChannel(
            name: methodChannelName,
            binaryMessenger: controller
        )
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }
        
        // Setup event channel
        eventChannel = FlutterEventChannel(
            name: eventChannelName,
            binaryMessenger: controller
        )
        eventChannel?.setStreamHandler(self)
        
        // Setup notification observers
        setupNotificationObservers()
        
        print("[ScreenProtection] iOS Screen Protection initialized")
    }
    
    private func setupNotificationObservers() {
        // Screenshot detection
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.handleScreenshot()
            }
            .store(in: &cancellables)
        
        // Screen recording detection
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleCapturedDidChange()
            }
            .store(in: &cancellables)
        
        // App state notifications
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.sendEvent(name: "app_switcher_entered")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.sendEvent(name: "app_switcher_exited")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Method Handlers
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableGlobalProtection":
            enableGlobalProtection()
            result(true)
            
        case "disableGlobalProtection":
            disableGlobalProtection()
            result(true)
            
        case "enableLocalProtection":
            enableLocalProtection()
            result(true)
            
        case "disableLocalProtection":
            disableLocalProtection()
            result(true)
            
        case "enableBlurOverlay":
            if let args = call.arguments as? [String: Any],
               let radius = args["blurRadius"] as? CGFloat {
                blurRadius = radius
            }
            isBlurOverlayEnabled = true
            result(true)
            
        case "disableBlurOverlay":
            isBlurOverlayEnabled = false
            result(true)
            
        case "getProtectionStatus":
            result(getProtectionStatus())
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Protection Logic
    
    private func enableGlobalProtection() {
        isGlobalEnabled = true
        showProtectionOverlayIfNeeded()
        print("[ScreenProtection] Global protection enabled")
    }
    
    private func disableGlobalProtection() {
        isGlobalEnabled = false
        // Only hide if no local protection active
        if localProtectionCount <= 0 {
            hideProtectionOverlay()
        }
        print("[ScreenProtection] Global protection disabled")
    }
    
    private func enableLocalProtection() {
        localProtectionCount += 1
        showProtectionOverlayIfNeeded()
        print("[ScreenProtection] Local protection enabled (count: \(localProtectionCount))")
    }
    
    private func disableLocalProtection() {
        if localProtectionCount > 0 {
            localProtectionCount -= 1
        }
        // Only hide if count is 0 and global is disabled
        if localProtectionCount <= 0 && !isGlobalEnabled {
            hideProtectionOverlay()
        }
        print("[ScreenProtection] Local protection disabled (count: \(localProtectionCount))")
    }
    
    // MARK: - Overlay Management
    
    private func showProtectionOverlayIfNeeded() {
        guard isProtectionActive else { return }
        
        // Show overlay when app becomes inactive or in background
        if UIApplication.shared.applicationState != .active {
            showProtectionOverlay()
        }
    }
    
    private func showProtectionOverlay() {
        guard protectionWindow == nil else { return }
        
        // Create protection window overlay
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
            as? UIWindowScene else {
            return
        }
        
        let protectionWindow = UIWindow(windowScene: windowScene)
        protectionWindow.windowLevel = .statusBar + 100 // Above everything
        protectionWindow.backgroundColor = .clear
        
        // Create blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = protectionWindow.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add protection label
        let label = UILabel()
        label.text = "Content Protected"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Add icon
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "lock.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        blurView.contentView.addSubview(stackView)
        protectionWindow.addSubview(blurView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: blurView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalToConstant: 48)
        ])
        
        protectionWindow.isHidden = false
        self.protectionWindow = protectionWindow
        self.blurView = blurView
        self.protectionLabel = label
        
        print("[ScreenProtection] Protection overlay shown")
    }
    
    private func hideProtectionOverlay() {
        protectionWindow?.isHidden = true
        protectionWindow = nil
        blurView = nil
        protectionLabel = nil
        print("[ScreenProtection] Protection overlay hidden")
    }
    
    // MARK: - Event Handlers
    
    func handleAppWillResignActive() {
        sendEvent(name: "app_switcher_entered")
        if isProtectionActive {
            showProtectionOverlay()
        }
    }
    
    func handleAppDidBecomeActive() {
        sendEvent(name: "app_switcher_exited")
        hideProtectionOverlay()
    }
    
    func handleAppDidEnterBackground() {
        if isProtectionActive {
            showProtectionOverlay()
        }
    }
    
    func handleAppWillEnterForeground() {
        hideProtectionOverlay()
    }
    
    private func handleScreenshot() {
        print("[ScreenProtection] Screenshot detected")
        sendEvent(name: "screenshot")
    }
    
    private func handleCapturedDidChange() {
        let isCaptured = UIScreen.main.isCaptured
        print("[ScreenProtection] Screen recording state changed: \(isCaptured)")
        
        if isCaptured {
            sendEvent(name: "recording_started")
        } else {
            sendEvent(name: "recording_stopped")
        }
    }
    
    // MARK: - Helpers
    
    private var isProtectionActive: Bool {
        return isGlobalEnabled || localProtectionCount > 0
    }
    
    private func sendEvent(name: String, metadata: [String: Any]? = nil) {
        var eventData: [String: Any] = ["event": name]
        if let metadata = metadata {
            eventData["metadata"] = metadata
        }
        eventSink?(eventData)
    }
    
    private func getProtectionStatus() -> [String: Any] {
        return [
            "platform": "ios",
            "isGlobalEnabled": isGlobalEnabled,
            "localProtectionCount": localProtectionCount,
            "isProtectionActive": isProtectionActive,
            "isBlurOverlayEnabled": isBlurOverlayEnabled,
            "isScreenRecording": UIScreen.main.isCaptured,
            "systemVersion": UIDevice.current.systemVersion
        ]
    }
}

// MARK: - FlutterStreamHandler
extension ScreenProtectionManager: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
