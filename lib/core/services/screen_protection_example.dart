// lib/core/services/screen_protection_example.dart
// Example usage of the screen protection system
//
// This file demonstrates all the ways to use the screen protection system.
// Copy the patterns you need into your actual screens.

import 'package:flutter/material.dart';
import 'screen_protection_service.dart';
import '../widgets/protected_screen.dart';

// ============================================================================
// EXAMPLE 1: Global Protection (App-wide)
// ============================================================================
// In your main.dart:
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize screen protection service
  final screenProtection = ScreenProtectionService();
  await screenProtection.initialize();
  
  // Enable global protection (protects entire app)
  await screenProtection.enableGlobalProtection();
  
  runApp(const MyApp());
}
*/

// ============================================================================
// EXAMPLE 2: ProtectedScreen Widget (Declarative)
// ============================================================================
class BankingScreen extends StatelessWidget {
  const BankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap sensitive screens with ProtectedScreen
    return ProtectedScreen(
      // Optional: Use strict mode for additional Flutter-level blur
      mode: ProtectionMode.strict,
      
      // Optional: Custom callbacks for detection events (iOS only)
      onScreenshotAttempt: () {
        // Show warning dialog, log event, etc.
        debugPrint('Screenshot attempted on banking screen!');
      },
      onRecordingStarted: () {
        debugPrint('Screen recording started!');
      },
      
      // Optional: Custom protection message
      protectionMessage: 'Banking Data Protected',
      
      // The actual screen content
      child: Scaffold(
        appBar: AppBar(title: const Text('Banking')),
        body: const Center(
          child: Text('Sensitive banking information'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Using the Mixin (Imperative)
// ============================================================================
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen>
    with ScreenProtectionMixin {
  
  @override
  void initState() {
    super.initState();
    
    // Enable protection when screen is created
    enableScreenProtection();
    
    // Optional: Listen to protection events
    listenToProtectionEvents((event) {
      debugPrint('Protection event: ${event.event}');
      
      if (event.event == ScreenProtectionEvent.screenshotAttempted) {
        // Handle screenshot
        _showScreenshotWarning();
      }
    });
  }

  @override
  void dispose() {
    // IMPORTANT: Always disable protection when screen is disposed
    disableScreenProtection();
    cancelProtectionEventSubscription();
    super.dispose();
  }

  void _showScreenshotWarning() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Screenshots Not Allowed'),
        content: const Text('Taking screenshots of documents is prohibited.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Document Viewer')),
      body: const Center(
        child: Text('Sensitive document content'),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Service API Direct Usage
// ============================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScreenProtectionService _protection = ScreenProtectionService();
  bool _isGlobalEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await _protection.getProtectionStatus();
    setState(() {
      _isGlobalEnabled = status['isGlobalEnabled'] ?? false;
    });
  }

  Future<void> _toggleGlobalProtection() async {
    if (_isGlobalEnabled) {
      await _protection.disableGlobalProtection();
    } else {
      await _protection.enableGlobalProtection();
    }
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Global Screen Protection'),
            subtitle: const Text('Protect entire app from screenshots'),
            value: _isGlobalEnabled,
            onChanged: (_) => _toggleGlobalProtection(),
          ),
          ListTile(
            title: const Text('Check Protection Status'),
            onTap: () async {
              final status = await _protection.getProtectionStatus();
              debugPrint('Protection status: $status');
              
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Platform: ${status['platform']}'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Navigation with Protected Screens
// ============================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Banking (Protected)'),
            subtitle: const Text('Uses ProtectedScreen widget'),
            trailing: const Icon(Icons.lock),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BankingScreen()),
            ),
          ),
          ListTile(
            title: const Text('Documents (Protected via Mixin)'),
            subtitle: const Text('Uses ScreenProtectionMixin'),
            trailing: const Icon(Icons.lock),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentViewerScreen()),
            ),
          ),
          ListTile(
            title: const Text('Settings (Service API)'),
            subtitle: const Text('Direct service usage'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          // This screen has NO protection
          ListTile(
            title: const Text('Public Content (No Protection)'),
            subtitle: const Text('Normal unprotected screen'),
            trailing: const Icon(Icons.public),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublicContentScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// Unprotected screen for comparison
class PublicContentScreen extends StatelessWidget {
  const PublicContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Public Content')),
      body: const Center(
        child: Text('This screen can be screenshotted'),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 6: Debug Mode for Development
// ============================================================================
class DebugProtectedScreen extends StatelessWidget {
  const DebugProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProtectedScreen(
      // Debug mode shows a visual indicator
      mode: ProtectionMode.debug,
      showDebugIndicator: true,
      
      child: Scaffold(
        appBar: AppBar(title: const Text('Debug Mode')),
        body: const Center(
          child: Text('This screen has debug indicators'),
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 7: Event Stream Listener (App-wide)
// ============================================================================
class AppWithEventListener extends StatefulWidget {
  final Widget child;
  
  const AppWithEventListener({super.key, required this.child});

  @override
  State<AppWithEventListener> createState() => _AppWithEventListenerState();
}

class _AppWithEventListenerState extends State<AppWithEventListener> {
  final ScreenProtectionService _protection = ScreenProtectionService();

  @override
  void initState() {
    super.initState();
    
    // Listen to all protection events app-wide
    _protection.onEvent.listen((event) {
      debugPrint('[App-wide] Protection event: ${event.event} at ${event.timestamp}');
      
      // Handle specific events
      switch (event.event) {
        case ScreenProtectionEvent.screenshotAttempted:
          _logSecurityEvent('screenshot_attempted');
          break;
        case ScreenProtectionEvent.recordingStarted:
          _logSecurityEvent('recording_started');
          break;
        case ScreenProtectionEvent.recordingStopped:
          _logSecurityEvent('recording_stopped');
          break;
        default:
          break;
      }
    });
  }

  void _logSecurityEvent(String eventType) {
    // Send to analytics, backend, etc.
    debugPrint('Security event logged: $eventType');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
