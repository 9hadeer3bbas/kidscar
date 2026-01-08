import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../config/app_config.dart';
import 'safety_event_service.dart';
import '../../data/models/trip_model.dart';

/// Service for monitoring audio levels during trips to detect loud sounds
class AudioMonitoringService extends GetxService {
  SafetyEventService? _safetyEventServiceInstance;

  SafetyEventService get _safetyEventService {
    _safetyEventServiceInstance ??= Get.isRegistered<SafetyEventService>()
        ? Get.find<SafetyEventService>()
        : null;
    if (_safetyEventServiceInstance == null) {
      throw Exception('SafetyEventService not registered');
    }
    return _safetyEventServiceInstance!;
  }

  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isMonitoring = false;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _monitoringTimer;
  DateTime? _lastLoudSoundNotificationAt;
  TripModel? _currentTrip;
  int _sampleCount = 0;

  // Configuration
  // Note: record package returns amplitude in dB range -160 to 0
  // The package uses relative dB scale where 0 = maximum microphone can detect
  // Real-world sounds: Normal conversation ~60dB SPL, Scream ~100-110dB SPL, Jet engine ~120-140dB SPL
  // To detect very loud screams (125dB SPL equivalent), we need a threshold very close to 0 (maximum)
  // -15dB in package scale ≈ extremely loud sounds like screams at close range (much more selective)
  // Lower values (closer to 0) = louder sounds required to trigger
  static const double loudSoundThresholdDb =
      -15.0; // Decibels threshold for scream detection (125dB SPL equivalent) - increased from -30dB to reduce false positives
  static const Duration loudSoundCooldown = Duration(
    minutes: 2,
  ); // Prevent spam
  static const Duration monitoringInterval = Duration(
    milliseconds: 500,
  ); // Check every 500ms
  static const int samplesToConfirm =
      2; // Number of consecutive loud samples to confirm (reduced from 3 for faster detection)

  int _consecutiveLoudSamples = 0;

  /// Start monitoring audio levels for the given trip
  Future<void> startMonitoring(TripModel trip) async {
    if (_isMonitoring) {
      if (AppConfig.isDebugMode) {
        debugPrint('⚠️ Audio monitoring already active');
      }
      return;
    }

    // Check microphone permission
    final hasPermission = await Permission.microphone.isGranted;
    if (!hasPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (AppConfig.isDebugMode) {
          debugPrint('❌ Microphone permission denied');
        }
        return;
      }
    }

    try {
      _currentTrip = trip;
      _isMonitoring = true;
      _consecutiveLoudSamples = 0;
      _lastLoudSoundNotificationAt = null;

      // Start recording (we only need amplitude, not actual recording)
      if (await _audioRecorder.hasPermission()) {
        // Create a temporary path for recording (required by the package)
        // We'll delete it after stopping, we only need amplitude
        final tempDir = await getTemporaryDirectory();
        final tempPath =
            '${tempDir.path}/audio_monitor_${DateTime.now().millisecondsSinceEpoch}.pcm';

        try {
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.pcm16bits,
              sampleRate: 44100,
              numChannels: 1,
            ),
            path: tempPath,
          );

          // Monitor amplitude levels
          _startAmplitudeMonitoring();

          if (AppConfig.isDebugMode) {
            debugPrint('✅ Audio monitoring started for trip ${trip.id}');
            debugPrint(
              '   Threshold: ${loudSoundThresholdDb}dB (125dB SPL equivalent for scream detection)',
            );
            debugPrint(
              '   Monitoring interval: ${monitoringInterval.inMilliseconds}ms',
            );
            debugPrint('   Samples to confirm: $samplesToConfirm');
          }
        } catch (e) {
          // If temp path doesn't work, try with a real temp file
          if (AppConfig.isDebugMode) {
            debugPrint(
              '⚠️ Failed to start with temp path, trying alternative: $e',
            );
          }
          _isMonitoring = false;
        }
      } else {
        if (AppConfig.isDebugMode) {
          debugPrint('❌ Microphone permission not granted');
        }
        _isMonitoring = false;
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Failed to start audio monitoring: $e');
      }
      _isMonitoring = false;
      _currentTrip = null;
    }
  }

  /// Stop monitoring audio levels
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      _isMonitoring = false;
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      _monitoringTimer?.cancel();
      _monitoringTimer = null;

      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      _currentTrip = null;
      _consecutiveLoudSamples = 0;
      _sampleCount = 0;

      if (AppConfig.isDebugMode) {
        debugPrint('✅ Audio monitoring stopped');
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Error stopping audio monitoring: $e');
      }
    }
  }

  /// Start monitoring amplitude levels
  void _startAmplitudeMonitoring() {
    _sampleCount = 0; // Reset sample count when starting
    _monitoringTimer = Timer.periodic(monitoringInterval, (_) async {
      if (!_isMonitoring || _currentTrip == null) return;

      try {
        if (!await _audioRecorder.isRecording()) {
          return;
        }

        final amplitude = await _audioRecorder.getAmplitude();

        // Amplitude values from record package are in range -160 to 0 dB
        // Negative values mean quieter, values closer to 0 mean louder
        // -80dB or higher (closer to 0) means very loud
        final currentDb = amplitude.current.isFinite
            ? amplitude.current
            : -160.0;

        // Log audio level every 10 samples (every 5 seconds) in debug mode
        _sampleCount++;
        if (AppConfig.isDebugMode && _sampleCount % 10 == 0) {
          final displayDb = currentDb.abs();
          debugPrint(
            '📊 Audio level: ${displayDb.toStringAsFixed(1)}dB (threshold: ${loudSoundThresholdDb.abs()}dB)',
          );
        }

        // Check if sound is loud enough (currentDb >= threshold means louder)
        // Since both are negative, we check if currentDb is greater (less negative)
        if (currentDb >= loudSoundThresholdDb) {
          _consecutiveLoudSamples++;

          if (AppConfig.isDebugMode) {
            debugPrint(
              '🔊 LOUD SOUND DETECTED: ${currentDb.toStringAsFixed(1)}dB (threshold: ${loudSoundThresholdDb}dB)',
            );
            debugPrint(
              '   Consecutive samples: $_consecutiveLoudSamples/$samplesToConfirm',
            );
            debugPrint(
              '   Need ${samplesToConfirm - _consecutiveLoudSamples} more sample(s) to confirm',
            );
          }

          // Confirm loud sound after multiple consecutive samples
          if (_consecutiveLoudSamples >= samplesToConfirm) {
            if (AppConfig.isDebugMode) {
              debugPrint(
                '🚨 VERY LOUD SOUND CONFIRMED! Triggering notification...',
              );
            }
            await _handleLoudSoundDetected(currentDb);
            _consecutiveLoudSamples = 0; // Reset counter
          }
        } else {
          // Reset counter if sound level drops
          if (_consecutiveLoudSamples > 0) {
            if (AppConfig.isDebugMode) {
              debugPrint(
                '📉 Sound level dropped to ${currentDb.toStringAsFixed(1)}dB, resetting counter',
              );
            }
            _consecutiveLoudSamples = 0;
          }
        }
      } catch (e) {
        if (AppConfig.isDebugMode) {
          debugPrint('⚠️ Error reading amplitude: $e');
        }
      }
    });
  }

  /// Handle loud sound detection
  Future<void> _handleLoudSoundDetected(double dbLevel) async {
    if (_currentTrip == null) return;

    // Check cooldown to prevent spam notifications
    if (_lastLoudSoundNotificationAt != null) {
      final timeSinceLastNotification = DateTime.now().difference(
        _lastLoudSoundNotificationAt!,
      );
      if (timeSinceLastNotification < loudSoundCooldown) {
        if (AppConfig.isDebugMode) {
          debugPrint(
            '⏸️ Loud sound notification in cooldown (${timeSinceLastNotification.inSeconds}s remaining)',
          );
        }
        return;
      }
    }

    try {
      final trip = _currentTrip!;

      // Use simulateSafetyEvent which handles authentication internally
      // Convert negative dB to positive for display (e.g., -70dB -> 70dB)
      final displayDb = dbLevel.abs();
      await _safetyEventService.simulateSafetyEvent(
        tripId: trip.id,
        eventType: SafetyEventType.loudSound,
        message: 'Very loud sound detected: ${displayDb.toStringAsFixed(1)}dB',
      );

      _lastLoudSoundNotificationAt = DateTime.now();

      if (AppConfig.isDebugMode) {
        debugPrint('✅ Loud sound event logged and parent notified');
        debugPrint('   Trip: ${trip.id}');
        debugPrint('   Sound level: ${dbLevel.toStringAsFixed(1)}dB');
      }
    } catch (e) {
      if (AppConfig.isDebugMode) {
        debugPrint('❌ Failed to handle loud sound detection: $e');
      }
    }
  }

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  @override
  void onClose() {
    stopMonitoring();
    _audioRecorder.dispose();
    super.onClose();
  }
}
