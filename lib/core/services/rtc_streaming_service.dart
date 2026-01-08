import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// flutter_webrtc exposes a top-level navigator factory which clashes with GetX's
// navigation extension. Importing as `rtc` keeps the namespace explicit.
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

/// High level phases for a WebRTC session.
enum RtcStreamingPhase { idle, acquiringMedia, signaling, connected, error }

/// Metadata that should accompany a WebRTC negotiation cycle.
///
/// In production this model will be serialized and transported via the
/// signaling channel (Firestore, WebSocket, etc.).
class RtcSessionMetadata {
  const RtcSessionMetadata({
    required this.tripId,
    required this.driverId,
    required this.parentId,
    required this.sessionId,
    this.customData,
  });

  final String tripId;
  final String driverId;
  final String parentId;
  final String sessionId;
  final Map<String, dynamic>? customData;

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'driverId': driverId,
    'parentId': parentId,
    'sessionId': sessionId,
    if (customData != null) 'customData': customData,
  };
}

/// Default ICE configuration. Replace with project specific TURN credentials
/// once the backend is provisioned.
class RtcPeerConfig {
  RtcPeerConfig({List<Map<String, dynamic>>? iceServers})
    : iceServers = iceServers ?? _defaultIceServers;

  final List<Map<String, dynamic>> iceServers;

  /// Default ICE servers with working TURN configurations.
  ///
  /// For production, consider:
  /// 1. Using Metered.ca API to fetch dynamic credentials (see fetchMeteredTurnCredentials)
  /// 2. Setting up your own Coturn server
  /// 3. Using Twilio/Xirsys TURN services
  ///
  /// Note: Android emulators may have network restrictions that prevent TURN connections.
  /// If you see "No relay candidates generated" on an emulator, this is expected.
  /// Test on real devices for full TURN functionality.
  static final List<Map<String, dynamic>> _defaultIceServers = [
    // STUN server from Metered.ca
    {'urls': 'stun:stun.relay.metered.ca:80'},

    // TURN servers from Metered.ca (dedicated credentials)
    // Status: Active
    // Configuration from Metered dashboard ICE Servers Array
    // IMPORTANT: Metered.ca TURN credentials removed for security.
    // Configure credentials via environment variables or use fetchMeteredTurnCredentials().
    // To add your own credentials, use the following format:
    // {
    //   'urls': 'turn:standard.relay.metered.ca:80',
    //   'username': String.fromEnvironment('METERED_TURN_USERNAME'),
    //   'credential': String.fromEnvironment('METERED_TURN_CREDENTIAL'),
    // },

    // Twilio STUN/TURN servers (static fallback - credentials are now fetched dynamically via API)
    // Note: Dynamic credentials are preferred and fetched automatically via fetchTwilioTurnCredentials()
    // This static configuration is kept as a last-resort fallback
    // IMPORTANT: Twilio TURN credentials removed for security.
    // Use fetchTwilioTurnCredentials() to get dynamic credentials instead.
    // Static fallback configuration should be set via environment variables:
    // {
    //   'urls': [
    //     'turn:global.turn.twilio.com:3478?transport=udp',
    //     'turn:global.turn.twilio.com:3478?transport=tcp',
    //     'turn:global.turn.twilio.com:443?transport=tcp',
    //   ],
    //   'username': String.fromEnvironment('TWILIO_TURN_USERNAME'),
    //   'credential': String.fromEnvironment('TWILIO_TURN_CREDENTIAL'),
    // },
  ];

  /// Fetches dynamic TURN credentials from Metered.ca API.
  ///
  /// To use this:
  /// 1. Sign up at https://www.metered.ca/
  /// 2. Get your API key from the dashboard
  /// 3. Call this method and pass the credentials to RtcPeerConfig
  ///
  /// Example:
  /// ```dart
  /// final turnCredentials = await RtcPeerConfig.fetchMeteredTurnCredentials(
  ///   apiKey: 'your-api-key',
  /// );
  /// final config = RtcPeerConfig(iceServers: turnCredentials);
  /// ```
  static Future<List<Map<String, dynamic>>> fetchMeteredTurnCredentials({
    required String apiKey,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📹 RTC: Fetching TURN credentials from Metered API...');
      }

      final response = await http
          .get(
            Uri.parse(
              'https://kidscar.metered.live/api/v1/turn/credentials?apiKey=$apiKey',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('TURN credentials fetch timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final iceServers = data
            .map((server) => server as Map<String, dynamic>)
            .toList();

        if (kDebugMode) {
          debugPrint(
            '📹 RTC: ✅ Successfully fetched ${iceServers.length} TURN servers',
          );
          for (var i = 0; i < iceServers.length; i++) {
            final server = iceServers[i];
            final urls = server['urls'];
            final username = server['username'];
            final credential = server['credential'];
            debugPrint(
              '📹 RTC:   Server $i: urls=$urls, username=${username != null ? "${username.toString().substring(0, 10)}..." : "none"}, credential=${credential != null ? "***" : "none"}',
            );

            // Validate TURN server format
            if (urls != null) {
              final urlsStr = urls is String
                  ? urls
                  : (urls is List ? urls.join(', ') : urls.toString());
              if (urlsStr.toString().contains('turn:') ||
                  urlsStr.toString().contains('turns:')) {
                if (username == null || credential == null) {
                  debugPrint(
                    '📹 RTC: ⚠️ WARNING: TURN server $i missing username or credential!',
                  );
                }
              }
            }
          }
        }

        return iceServers;
      } else {
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: ⚠️ TURN API returned status ${response.statusCode}',
          );
          debugPrint('📹 RTC: Response: ${response.body}');
          debugPrint('📹 RTC: Falling back to default TURN servers');
        }
        return _defaultIceServers;
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ⚠️ Timeout fetching TURN credentials: $e');
        debugPrint('📹 RTC: Falling back to default TURN servers');
      }
      return _defaultIceServers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ⚠️ Error fetching TURN credentials: $e');
        debugPrint('📹 RTC: Falling back to default TURN servers');
      }
      return _defaultIceServers;
    }
  }

  /// Fetches dynamic TURN credentials from Twilio API.
  ///
  /// Twilio provides temporary TURN credentials (valid for 24 hours) via their REST API.
  /// This is more secure than using static Account SID/Auth Token directly.
  ///
  /// To use this:
  /// 1. Sign up at https://www.twilio.com/
  /// 2. Get your Account SID and Auth Token from the console
  /// 3. Call this method and pass the credentials to RtcPeerConfig
  ///
  /// Example:
  /// ```dart
  /// final turnCredentials = await RtcPeerConfig.fetchTwilioTurnCredentials(
  ///   accountSid: 'AC...',
  ///   authToken: 'your-auth-token',
  /// );
  /// final config = RtcPeerConfig(iceServers: turnCredentials);
  /// ```
  static Future<List<Map<String, dynamic>>> fetchTwilioTurnCredentials({
    required String accountSid,
    required String authToken,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📹 RTC: Fetching TURN credentials from Twilio API...');
      }

      // Twilio API endpoint for creating TURN tokens
      final uri = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Tokens.json',
      );

      // Use Basic Auth with Account SID as username and Auth Token as password
      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Basic $credentials',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Twilio TURN credentials fetch timed out');
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final iceServers = data['ice_servers'] as List<dynamic>?;

        if (iceServers != null && iceServers.isNotEmpty) {
          final servers = iceServers
              .map((server) => server as Map<String, dynamic>)
              .toList();

          if (kDebugMode) {
            debugPrint(
              '📹 RTC: ✅ Successfully fetched ${servers.length} Twilio TURN servers',
            );
            final username = data['username'] as String?;
            final ttl = data['ttl'] as String?;
            if (username != null) {
              debugPrint(
                '📹 RTC:   Username: ${username.substring(0, 10)}... (TTL: ${ttl ?? "N/A"})',
              );
            }
            for (var i = 0; i < servers.length; i++) {
              final server = servers[i];
              final urls = server['urls'];
              debugPrint('📹 RTC:   Server $i: urls=$urls');
            }
          }

          return servers;
        } else {
          if (kDebugMode) {
            debugPrint('📹 RTC: ⚠️ Twilio API returned empty ice_servers');
            debugPrint('📹 RTC: Falling back to default TURN servers');
          }
          return _defaultIceServers;
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: ⚠️ Twilio API returned status ${response.statusCode}',
          );
          debugPrint('📹 RTC: Response: ${response.body}');
          debugPrint('📹 RTC: Falling back to default TURN servers');
        }
        return _defaultIceServers;
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ⚠️ Timeout fetching Twilio TURN credentials: $e');
        debugPrint('📹 RTC: Falling back to default TURN servers');
      }
      return _defaultIceServers;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ⚠️ Error fetching Twilio TURN credentials: $e');
        debugPrint('📹 RTC: Falling back to default TURN servers');
      }
      return _defaultIceServers;
    }
  }

  Map<String, dynamic> toJson() => {
    'iceServers': iceServers,
    'sdpSemantics': 'unified-plan',
    // Pre-fetch ICE candidates to improve connection reliability
    // Higher value = more candidates pre-fetched, better for NAT traversal
    'iceCandidatePoolSize': 10,
    // Use 'all' to allow host, srflx, and relay candidates
    // This ensures TURN servers are tried even if direct connection seems possible
    // For maximum reliability across VPNs/NATs, we want relay candidates
    'iceTransportPolicy': 'all',
    // Additional configuration to help with TURN connectivity
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    // Enable continuous gathering to keep trying TURN servers
    'continualGatheringPolicy': 'gather_continually',
  };
}

/// Encapsulates core WebRTC primitives and exposes reactive state so the UI
/// can reflect connection progress while we finish the backend integration.
class RtcStreamingService extends GetxService {
  /// Metered.ca API key for fetching TURN server credentials dynamically.
  /// Set this before starting a broadcast or viewer session.
  /// IMPORTANT: Set this value from your environment or configuration.
  /// Get your API key from https://www.metered.ca/
  /// DO NOT hardcode API keys in source code.
  static const String meteredApiKey = String.fromEnvironment(
    'METERED_API_KEY',
    defaultValue: '', // Empty by default - must be configured
  );

  /// Twilio Account SID for fetching TURN server credentials dynamically.
  String twilioAccountSid = String.fromEnvironment('TWILIO_ACCOUNT_SID');

  /// Twilio Auth Token for fetching TURN server credentials dynamically.
  static const String twilioAuthToken = String.fromEnvironment(
    'TWILIO_AUTH_TOKEN',
  );
  final Rx<RtcStreamingPhase> phase = RtcStreamingPhase.idle.obs;
  final Rx<rtc.MediaStream?> localStream = Rx<rtc.MediaStream?>(null);
  final Rx<rtc.MediaStream?> remoteStream = Rx<rtc.MediaStream?>(null);
  final RxBool streamingActive = false.obs;
  final StreamController<rtc.RTCIceCandidate> _iceCandidateStreamController =
      StreamController.broadcast();

  rtc.RTCPeerConnection? _peerConnection;
  rtc.RTCDataChannel? _dataChannel;
  RtcPeerConfig _config = RtcPeerConfig();
  RtcSessionMetadata? _activeSession;
  final List<rtc.RTCIceCandidate> _pendingIceCandidates = [];
  bool _credentialsFetched = false;

  // Track ICE candidate types for diagnostics
  int _hostCandidates = 0;
  int _srflxCandidates = 0;
  int _relayCandidates = 0;
  int _prflxCandidates = 0;

  Stream<rtc.RTCIceCandidate> get onIceCandidate =>
      _iceCandidateStreamController.stream;

  Future<void> configure({RtcPeerConfig? config}) async {
    _config = config ?? _config;
  }

  /// Fetches TURN credentials from Metered API and updates the configuration.
  ///
  /// This should be called before starting a broadcast or viewer session
  /// to ensure fresh TURN credentials are used.
  ///
  /// [apiKey] - Your Metered.ca API key
  ///
  /// Returns true if credentials were successfully fetched, false otherwise.
  /// Falls back to default credentials if the API call fails.
  Future<bool> fetchAndConfigureTurnCredentials({
    required String apiKey,
  }) async {
    try {
      final iceServers = await RtcPeerConfig.fetchMeteredTurnCredentials(
        apiKey: apiKey,
      );
      _config = RtcPeerConfig(iceServers: iceServers);

      if (kDebugMode) {
        debugPrint('📹 RTC: ✅ TURN credentials configured');
        debugPrint('📹 RTC: Using ${iceServers.length} ICE servers');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: Error in fetchAndConfigureTurnCredentials: $e');
      }
      return false;
    }
  }

  /// Fetches TURN credentials from Twilio API and updates the configuration.
  ///
  /// This should be called before starting a broadcast or viewer session
  /// to ensure fresh TURN credentials are used.
  ///
  /// [accountSid] - Your Twilio Account SID
  /// [authToken] - Your Twilio Auth Token
  ///
  /// Returns true if credentials were successfully fetched, false otherwise.
  /// Falls back to default credentials if the API call fails.
  Future<bool> fetchAndConfigureTwilioTurnCredentials({
    required String accountSid,
    required String authToken,
  }) async {
    try {
      final iceServers = await RtcPeerConfig.fetchTwilioTurnCredentials(
        accountSid: accountSid,
        authToken: authToken,
      );
      _config = RtcPeerConfig(iceServers: iceServers);

      if (kDebugMode) {
        debugPrint('📹 RTC: ✅ Twilio TURN credentials configured');
        debugPrint('📹 RTC: Using ${iceServers.length} ICE servers');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '📹 RTC: Error in fetchAndConfigureTwilioTurnCredentials: $e',
        );
      }
      return false;
    }
  }

  /// Fetches TURN credentials from ALL available providers and combines them.
  ///
  /// This provides maximum redundancy - if one TURN provider is blocked
  /// by network/VPN, another might work. Uses both Metered and Twilio
  /// simultaneously for best connectivity across all network conditions.
  ///
  /// Returns true if credentials were successfully fetched from any provider.
  Future<bool> fetchAndConfigureTurnCredentialsWithFallback() async {
    final List<Map<String, dynamic>> allIceServers = [];
    int providersAdded = 0;

    // Try Metered first
    if (kDebugMode) {
      debugPrint(
        '📹 RTC: Attempting to fetch TURN credentials from Metered...',
      );
    }
    try {
      final meteredServers = await RtcPeerConfig.fetchMeteredTurnCredentials(
        apiKey: meteredApiKey,
      );
      if (meteredServers.isNotEmpty) {
        allIceServers.addAll(meteredServers);
        providersAdded++;
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: ✅ Added ${meteredServers.length} Metered TURN servers',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ⚠️ Metered fetch failed: $e');
      }
    }

    // Try Twilio (add to the list, don't replace)
    if (kDebugMode) {
      debugPrint('📹 RTC: Attempting to fetch TURN credentials from Twilio...');
    }
    try {
      final twilioServers = await RtcPeerConfig.fetchTwilioTurnCredentials(
        accountSid: twilioAccountSid,
        authToken: twilioAuthToken,
      );
      if (twilioServers.isNotEmpty) {
        allIceServers.addAll(twilioServers);
        providersAdded++;
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: ✅ Added ${twilioServers.length} Twilio TURN servers',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ⚠️ Twilio fetch failed: $e');
      }
    }

    // If we got any servers, use them
    if (allIceServers.isNotEmpty) {
      _config = RtcPeerConfig(iceServers: allIceServers);
      if (kDebugMode) {
        debugPrint(
          '📹 RTC: ✅ Using ${allIceServers.length} total TURN servers from $providersAdded provider(s)',
        );
        debugPrint(
          '📹 RTC: This provides redundancy - if one provider is blocked by network/VPN, others may work',
        );
      }
      return true;
    }

    // Both failed, use defaults
    if (kDebugMode) {
      debugPrint('📹 RTC: ⚠️ All providers failed, using default TURN servers');
    }
    _config = RtcPeerConfig(); // Use defaults
    return false;
  }

  Future<rtc.RTCSessionDescription?> startDriverBroadcast(
    RtcSessionMetadata metadata,
  ) async {
    if (streamingActive.value) {
      return await _peerConnection?.getLocalDescription();
    }

    // Fetch TURN credentials from API if not already fetched
    // Tries Metered first, then Twilio as fallback
    if (!_credentialsFetched) {
      if (kDebugMode) {
        debugPrint(
          '📹 RTC: Fetching TURN credentials before starting broadcast...',
        );
      }
      await fetchAndConfigureTurnCredentialsWithFallback();
      _credentialsFetched = true;
    }

    phase.value = RtcStreamingPhase.acquiringMedia;
    _activeSession = metadata;

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'facingMode': 'user', // Use front camera instead of back camera
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 24},
      },
    };

    final stream = await rtc.navigator.mediaDevices.getUserMedia(
      mediaConstraints,
    );
    localStream.value = stream;

    phase.value = RtcStreamingPhase.signaling;
    final configJson = _config.toJson();
    if (kDebugMode) {
      debugPrint('📹 RTC: Creating peer connection with ICE servers:');
      final iceServers = configJson['iceServers'] as List?;
      if (iceServers != null) {
        for (var i = 0; i < iceServers.length; i++) {
          final server = iceServers[i] as Map<String, dynamic>;
          final urls = server['urls'];
          final username = server['username'];
          final credential = server['credential'];
          debugPrint(
            '📹 RTC:   Server $i: urls=$urls, username=${username != null ? "${username.toString().substring(0, 10)}..." : "none"}, credential=${credential != null ? "***" : "none"}',
          );
        }
      }
    }
    _peerConnection = await rtc.createPeerConnection(configJson);

    // Use addTrack instead of addStream for Unified Plan SDP semantics
    for (final track in stream.getTracks()) {
      await _peerConnection!.addTrack(track, stream);
    }

    // Reset candidate counters
    _hostCandidates = 0;
    _srflxCandidates = 0;
    _relayCandidates = 0;
    _prflxCandidates = 0;

    _peerConnection!.onIceCandidate = (candidate) {
      if (kDebugMode) {
        try {
          final candidateStr = candidate.candidate ?? '';
          if (candidateStr.isNotEmpty) {
            final candidateParts = candidateStr.split(' ');
            final candidateType = candidateParts.length > 7
                ? candidateParts[7]
                : 'unknown';
            final isUdp = candidateStr.toLowerCase().contains('udp');
            final isTcp = candidateStr.toLowerCase().contains('tcp');
            final protocol = isUdp ? 'UDP' : (isTcp ? 'TCP' : 'unknown');
            final preview = candidateStr.length > 100
                ? '${candidateStr.substring(0, 100)}...'
                : candidateStr;

            // Track candidate types
            if (candidateType == 'host') {
              _hostCandidates++;
            } else if (candidateType == 'srflx') {
              _srflxCandidates++;
            } else if (candidateType == 'relay') {
              _relayCandidates++;
            } else if (candidateType == 'prflx') {
              _prflxCandidates++;
            }

            debugPrint(
              '📹 RTC: Local ICE candidate: type=$candidateType, protocol=$protocol, candidate=$preview',
            );

            // Warn if we see relay candidates (good sign!)
            if (candidateType == 'relay') {
              debugPrint(
                '📹 RTC: ✅ TURN server working! Relay candidate generated.',
              );
            }
          } else {
            debugPrint(
              '📹 RTC: Local ICE candidate generated (empty candidate string)',
            );
          }
        } catch (e) {
          debugPrint(
            '📹 RTC: Local ICE candidate generated (parsing error: $e)',
          );
        }
      }
      _iceCandidateStreamController.add(candidate);
    };

    // Monitor ICE gathering state
    _peerConnection!.onIceGatheringState = (state) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ICE gathering state: $state');
        if (state == rtc.RTCIceGatheringState.RTCIceGatheringStateComplete) {
          final total =
              _hostCandidates +
              _srflxCandidates +
              _relayCandidates +
              _prflxCandidates;
          debugPrint('📹 RTC: ICE gathering complete! Summary:');
          debugPrint('📹 RTC:   - Host candidates: $_hostCandidates');
          debugPrint('📹 RTC:   - Server reflexive (srflx): $_srflxCandidates');
          debugPrint('📹 RTC:   - Relay candidates: $_relayCandidates');
          debugPrint('📹 RTC:   - Peer reflexive (prflx): $_prflxCandidates');
          debugPrint('📹 RTC:   - Total: $total');
          if (_relayCandidates == 0) {
            debugPrint('📹 RTC: ⚠️ WARNING: No relay candidates generated!');
            debugPrint(
              '📹 RTC: ⚠️ TURN servers may not be working or are blocked.',
            );
            debugPrint(
              '📹 RTC: ⚠️ Connection may fail if both devices are behind NAT/VPN.',
            );
          } else {
            debugPrint(
              '📹 RTC: ✅ TURN servers are working! Relay candidates available.',
            );
          }
        }
      }
    };

    _peerConnection!.onAddStream = (stream) {
      remoteStream.value = stream;
    };

    // Also listen for tracks (Unified Plan)
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStream.value = event.streams[0];
      }
    };

    // Monitor connection state changes
    _peerConnection!.onIceConnectionState = (state) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ICE connection state: $state');
      }
      if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == rtc.RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ✅ ICE connection established!');
        }
        phase.value = RtcStreamingPhase.connected;
      } else if (state ==
              rtc.RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state ==
              rtc.RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ❌ ICE connection failed or disconnected: $state');
          debugPrint(
            '📹 RTC: This usually indicates network/TURN server issues',
          );
        }
        phase.value = RtcStreamingPhase.error;
      } else if (state ==
          rtc.RTCIceConnectionState.RTCIceConnectionStateChecking) {
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: 🔍 ICE connection checking (NAT traversal in progress)',
          );
          // Log current ICE gathering state
          final gatheringState = _peerConnection?.iceGatheringState;
          debugPrint('📹 RTC: Current ICE gathering state: $gatheringState');
        }
        // Keep in signaling phase while checking
      } else if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateNew) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ICE connection state: NEW');
        }
      } else if (state ==
          rtc.RTCIceConnectionState.RTCIceConnectionStateClosed) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ICE connection state: CLOSED');
        }
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (kDebugMode) {
        debugPrint('📹 RTC: Connection state: $state');
      }
      if (state == rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ✅ Peer connection established!');
        }
        phase.value = RtcStreamingPhase.connected;
      } else if (state ==
              rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state ==
              rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: ❌ Peer connection failed or disconnected: $state',
          );
          debugPrint('📹 RTC: Possible causes:');
          debugPrint('📹 RTC:   - Network connectivity issues');
          debugPrint('📹 RTC:   - TURN server not working or rate-limited');
          debugPrint('📹 RTC:   - Firewall/NAT blocking connection');
          debugPrint('📹 RTC:   - Devices on incompatible networks');
        }
        phase.value = RtcStreamingPhase.error;
      } else if (state ==
          rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        if (kDebugMode) {
          debugPrint('📹 RTC: 🔄 Peer connection connecting...');
        }
        // Keep in signaling phase while connecting
      }
    };

    _dataChannel = await _peerConnection!.createDataChannel(
      'telemetry',
      rtc.RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = -1,
    );

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    streamingActive.value = true;
    return offer;
  }

  Future<void> completeDriverBroadcast(rtc.RTCSessionDescription answer) async {
    if (_peerConnection == null) {
      throw StateError('Peer connection not initialised. Call start first.');
    }

    // Check if remote description is already set
    final currentRemoteDescription = await _peerConnection!
        .getRemoteDescription();
    if (currentRemoteDescription != null) {
      if (kDebugMode) {
        debugPrint(
          '📹 RTC: Remote description already set, skipping duplicate answer',
        );
      }
      // Process any pending ICE candidates anyway
      await _processPendingIceCandidates();
      return;
    }

    await _peerConnection!.setRemoteDescription(answer);

    // Process any ICE candidates that arrived before peer connection was ready
    await _processPendingIceCandidates();

    phase.value = RtcStreamingPhase.connected;
  }

  Future<void> addRemoteIceCandidate(rtc.RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      if (kDebugMode) {
        debugPrint(
          '📹 RTC: Buffering ICE candidate (peer connection not ready)',
        );
        debugPrint(
          '📹 RTC: Total buffered candidates: ${_pendingIceCandidates.length + 1}',
        );
      }
      _pendingIceCandidates.add(candidate);
      return;
    }
    if (kDebugMode) {
      try {
        final candidateStr = candidate.candidate ?? '';
        if (candidateStr.isNotEmpty) {
          final candidateParts = candidateStr.split(' ');
          final candidateType = candidateParts.length > 7
              ? candidateParts[7]
              : 'unknown';
          final isUdp = candidateStr.toLowerCase().contains('udp');
          final isTcp = candidateStr.toLowerCase().contains('tcp');
          final protocol = isUdp ? 'UDP' : (isTcp ? 'TCP' : 'unknown');
          final sdpMid = candidate.sdpMid ?? 'null';
          final sdpMLineIndex = candidate.sdpMLineIndex ?? -1;

          // Extract IP address if available
          String? ipAddress;
          if (candidateParts.length > 4) {
            ipAddress = candidateParts[4];
          }

          debugPrint(
            '📹 RTC: Adding remote ICE candidate: type=$candidateType, protocol=$protocol, sdpMid=$sdpMid, sdpMLineIndex=$sdpMLineIndex${ipAddress != null ? ", ip=$ipAddress" : ""}',
          );

          // Log relay candidates specifically (important for TURN verification)
          if (candidateType == 'relay') {
            debugPrint(
              '📹 RTC: ✅ Remote RELAY candidate received! TURN server is working on peer side.',
            );
          }
        } else {
          debugPrint(
            '📹 RTC: Adding remote ICE candidate (empty candidate string)',
          );
        }
      } catch (e) {
        debugPrint('📹 RTC: Adding remote ICE candidate (parsing error: $e)');
      }
    }
    try {
      await _peerConnection!.addCandidate(candidate);
      if (kDebugMode) {
        debugPrint('📹 RTC: Successfully added remote ICE candidate');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ❌ Error adding remote ICE candidate: $e');
        debugPrint(
          '📹 RTC: Candidate details: sdpMid=${candidate.sdpMid}, sdpMLineIndex=${candidate.sdpMLineIndex}',
        );
        debugPrint(
          '📹 RTC: This may indicate a duplicate candidate or connection state issue',
        );
      }
      // Don't rethrow - some candidates may fail (e.g., duplicates) which is normal
    }
  }

  /// Process any buffered ICE candidates that arrived before peer connection was ready
  Future<void> _processPendingIceCandidates() async {
    if (_peerConnection == null || _pendingIceCandidates.isEmpty) {
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '📹 RTC: Processing ${_pendingIceCandidates.length} buffered ICE candidates',
      );
    }
    int successCount = 0;
    int failureCount = 0;
    for (final candidate in _pendingIceCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
        successCount++;
      } catch (e) {
        failureCount++;
        if (kDebugMode) {
          debugPrint('📹 RTC: Error adding buffered candidate: $e');
        }
      }
    }
    if (kDebugMode) {
      debugPrint(
        '📹 RTC: Buffered candidates processed: $successCount succeeded, $failureCount failed',
      );
    }
    _pendingIceCandidates.clear();
  }

  Future<void> requestParentViewer(
    RtcSessionMetadata metadata,
    rtc.RTCSessionDescription offer,
  ) async {
    if (kDebugMode) {
      debugPrint('📹 RTC: Starting parent viewer request');
      debugPrint('📹 RTC: Session ID: ${metadata.sessionId}');
    }

    // Fetch TURN credentials from API if not already fetched
    // Tries Metered first, then Twilio as fallback
    if (!_credentialsFetched) {
      if (kDebugMode) {
        debugPrint(
          '📹 RTC: Fetching TURN credentials before starting viewer...',
        );
      }
      await fetchAndConfigureTurnCredentialsWithFallback();
      _credentialsFetched = true;
    }

    phase.value = RtcStreamingPhase.signaling;
    _activeSession = metadata;

    // Reset candidate counters
    _hostCandidates = 0;
    _srflxCandidates = 0;
    _relayCandidates = 0;
    _prflxCandidates = 0;

    final configJson = _config.toJson();
    if (kDebugMode) {
      debugPrint('📹 RTC: Creating peer connection with ICE servers:');
      final iceServers = configJson['iceServers'] as List?;
      if (iceServers != null) {
        for (var i = 0; i < iceServers.length; i++) {
          final server = iceServers[i] as Map<String, dynamic>;
          final urls = server['urls'];
          final username = server['username'];
          final credential = server['credential'];
          debugPrint(
            '📹 RTC:   Server $i: urls=$urls, username=${username != null ? "${username.toString().substring(0, 10)}..." : "none"}, credential=${credential != null ? "***" : "none"}',
          );
        }
      }
    }
    _peerConnection = await rtc.createPeerConnection(configJson);

    // Give TURN servers a moment to establish connections before ICE gathering
    // This is especially important for emulators which may have network restrictions
    await Future.delayed(const Duration(milliseconds: 100));

    _peerConnection!.onIceCandidate = (candidate) {
      if (kDebugMode) {
        try {
          final candidateStr = candidate.candidate ?? '';
          if (candidateStr.isNotEmpty) {
            final candidateParts = candidateStr.split(' ');
            final candidateType = candidateParts.length > 7
                ? candidateParts[7]
                : 'unknown';
            final isUdp = candidateStr.toLowerCase().contains('udp');
            final isTcp = candidateStr.toLowerCase().contains('tcp');
            final protocol = isUdp ? 'UDP' : (isTcp ? 'TCP' : 'unknown');
            final preview = candidateStr.length > 100
                ? '${candidateStr.substring(0, 100)}...'
                : candidateStr;

            // Track candidate types
            if (candidateType == 'host') {
              _hostCandidates++;
            } else if (candidateType == 'srflx') {
              _srflxCandidates++;
            } else if (candidateType == 'relay') {
              _relayCandidates++;
            } else if (candidateType == 'prflx') {
              _prflxCandidates++;
            }

            debugPrint(
              '📹 RTC: Local ICE candidate: type=$candidateType, protocol=$protocol, candidate=$preview',
            );

            // Warn if we see relay candidates (good sign!)
            if (candidateType == 'relay') {
              debugPrint(
                '📹 RTC: ✅ TURN server working! Relay candidate generated.',
              );
            }
          } else {
            debugPrint(
              '📹 RTC: Local ICE candidate generated (empty candidate string)',
            );
          }
        } catch (e) {
          debugPrint(
            '📹 RTC: Local ICE candidate generated (parsing error: $e)',
          );
        }
      }
      _iceCandidateStreamController.add(candidate);
    };

    // Monitor ICE gathering state
    _peerConnection!.onIceGatheringState = (state) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ICE gathering state: $state');
        if (state == rtc.RTCIceGatheringState.RTCIceGatheringStateComplete) {
          final total =
              _hostCandidates +
              _srflxCandidates +
              _relayCandidates +
              _prflxCandidates;
          debugPrint('📹 RTC: ICE gathering complete! Summary:');
          debugPrint('📹 RTC:   - Host candidates: $_hostCandidates');
          debugPrint('📹 RTC:   - Server reflexive (srflx): $_srflxCandidates');
          debugPrint('📹 RTC:   - Relay candidates: $_relayCandidates');
          debugPrint('📹 RTC:   - Peer reflexive (prflx): $_prflxCandidates');
          debugPrint('📹 RTC:   - Total: $total');
          if (_relayCandidates == 0) {
            debugPrint('📹 RTC: ⚠️ WARNING: No relay candidates generated!');
            debugPrint(
              '📹 RTC: ⚠️ TURN servers may not be working or are blocked.',
            );
            debugPrint(
              '📹 RTC: ⚠️ Connection may fail if both devices are behind NAT/VPN.',
            );
          } else {
            debugPrint(
              '📹 RTC: ✅ TURN servers are working! Relay candidates available.',
            );
          }
        }
      }
    };
    _peerConnection!.onAddStream = (stream) {
      if (kDebugMode) {
        debugPrint('📹 RTC: Remote stream received!');
      }
      remoteStream.value = stream;
    };

    // Also listen for tracks (Unified Plan)
    _peerConnection!.onTrack = (event) {
      if (kDebugMode) {
        debugPrint('📹 RTC: Remote track received!');
      }
      if (event.streams.isNotEmpty) {
        remoteStream.value = event.streams[0];
      }
    };

    // Monitor connection state changes
    _peerConnection!.onIceConnectionState = (state) {
      if (kDebugMode) {
        debugPrint('📹 RTC: ICE connection state: $state');
      }
      if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == rtc.RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ✅ ICE connection established!');
        }
        phase.value = RtcStreamingPhase.connected;
      } else if (state ==
              rtc.RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state ==
              rtc.RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ❌ ICE connection failed or disconnected: $state');
          debugPrint(
            '📹 RTC: This usually indicates network/TURN server issues',
          );
        }
        phase.value = RtcStreamingPhase.error;
      } else if (state ==
          rtc.RTCIceConnectionState.RTCIceConnectionStateChecking) {
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: 🔍 ICE connection checking (NAT traversal in progress)',
          );
          // Log current ICE gathering state
          final gatheringState = _peerConnection?.iceGatheringState;
          debugPrint('📹 RTC: Current ICE gathering state: $gatheringState');
        }
        // Keep in signaling phase while checking
      } else if (state == rtc.RTCIceConnectionState.RTCIceConnectionStateNew) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ICE connection state: NEW');
        }
      } else if (state ==
          rtc.RTCIceConnectionState.RTCIceConnectionStateClosed) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ICE connection state: CLOSED');
        }
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (kDebugMode) {
        debugPrint('📹 RTC: Connection state: $state');
      }
      if (state == rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (kDebugMode) {
          debugPrint('📹 RTC: ✅ Peer connection established!');
        }
        phase.value = RtcStreamingPhase.connected;
      } else if (state ==
              rtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state ==
              rtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        if (kDebugMode) {
          debugPrint(
            '📹 RTC: ❌ Peer connection failed or disconnected: $state',
          );
          debugPrint('📹 RTC: Possible causes:');
          debugPrint('📹 RTC:   - Network connectivity issues');
          debugPrint('📹 RTC:   - TURN server not working or rate-limited');
          debugPrint('📹 RTC:   - Firewall/NAT blocking connection');
          debugPrint('📹 RTC:   - Devices on incompatible networks');
        }
        phase.value = RtcStreamingPhase.error;
      } else if (state ==
          rtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        if (kDebugMode) {
          debugPrint('📹 RTC: 🔄 Peer connection connecting...');
        }
        // Keep in signaling phase while connecting
      }
    };

    if (kDebugMode) {
      debugPrint('📹 RTC: Setting remote description (offer)');
    }
    await _peerConnection!.setRemoteDescription(offer);

    // Process any ICE candidates that arrived before peer connection was ready
    await _processPendingIceCandidates();

    if (kDebugMode) {
      debugPrint('📹 RTC: Creating answer');
    }
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    streamingActive.value = true;
    // Don't set phase to connected here - wait for actual connection state
    // The connection state handlers will update the phase when connection is established

    if (kDebugMode) {
      debugPrint('📹 RTC: Answer created and set, waiting for connection...');
    }
  }

  Future<void> stopStreaming() async {
    try {
      // Stop all tracks on local stream first to release camera immediately
      final local = localStream.value;
      if (local != null) {
        local.getTracks().forEach((track) {
          track.stop();
        });
      }

      // Stop all tracks on remote stream
      final remote = remoteStream.value;
      if (remote != null) {
        remote.getTracks().forEach((track) {
          track.stop();
        });
      }

      await _dataChannel?.close();
      await _peerConnection?.close();
      await localStream.value?.dispose();
      await remoteStream.value?.dispose();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to stop RTC stream: $e');
      }
    } finally {
      _dataChannel = null;
      _peerConnection = null;
      localStream.value = null;
      remoteStream.value = null;
      streamingActive.value = false;
      _pendingIceCandidates.clear();
      // Reset candidate counters
      _hostCandidates = 0;
      _srflxCandidates = 0;
      _relayCandidates = 0;
      _prflxCandidates = 0;
      phase.value = RtcStreamingPhase.idle;
      _activeSession = null;
      // Reset credentials flag so fresh credentials are fetched for next session
      _credentialsFetched = false;
    }
  }

  @override
  void onClose() {
    _iceCandidateStreamController.close();
    super.onClose();
  }

  Future<Map<String, dynamic>> buildSignalingPayload({
    Map<String, dynamic>? extra,
  }) async {
    final description = await _peerConnection?.getLocalDescription();
    return {
      if (description != null) ...{
        'sdp': description.sdp,
        'type': description.type,
      },
      if (_activeSession != null) ..._activeSession!.toJson(),
      if (extra != null) ...extra,
    };
  }
}
