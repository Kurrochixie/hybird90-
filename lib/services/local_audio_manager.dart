import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAudioManager {
  static final LocalAudioManager _instance = LocalAudioManager._internal();
  factory LocalAudioManager() => _instance;
  LocalAudioManager._internal();

  // 🎯 MULTI-INSTANCE AUDIO ARCHITECTURE
  // Separate AudioPlayer instances for each audio type to prevent conflicts
  final AudioPlayer _alarmPlayer = AudioPlayer();     // Priority 1: Highest
  final AudioPlayer _troublePlayer = AudioPlayer();   // Priority 2: Medium
  final AudioPlayer _drillPlayer = AudioPlayer();     // Priority 3: Lowest

  Timer? _troubleTimer;
  bool _isInitialized = false;
  
  // Local mute states yang disimpan per device
  bool _isNotificationMuted = false;
  bool _isSoundMuted = false;
  bool _isBellMuted = false;
  
  // Audio status tracking untuk sync dengan button
  bool _isDrillActive = false;
  bool _isAlarmActive = false;
  bool _isTroubleActive = false;
  bool _isSilencedActive = false;
  
  // Stream controllers untuk real-time updates
  final _audioStatusController = StreamController<Map<String, bool>>.broadcast();
  Stream<Map<String, bool>> get audioStatusStream => _audioStatusController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 🎵 ENHANCED AUDIO SESSION CONFIGURATION
      // Using music mode for better audio mixing and priority handling
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      

      await _loadLocalSettings();

      // Test all audio players initialization
      try {
        await _alarmPlayer.setLoopMode(LoopMode.off);
        await _troublePlayer.setLoopMode(LoopMode.off);
        await _drillPlayer.setLoopMode(LoopMode.off);
        
      } catch (e) {
        
      }

      _isInitialized = true;
      
    } catch (e) {
      
    }
  }

  // Load local mute settings dari SharedPreferences
  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNotificationMuted = prefs.getBool('notification_muted') ?? false;
      _isSoundMuted = prefs.getBool('sound_muted') ?? false;
      _isBellMuted = prefs.getBool('bell_muted') ?? false;
      
      
    } catch (e) {
      
    }
  }

  // Save local mute settings ke SharedPreferences
  Future<void> _saveLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_muted', _isNotificationMuted);
      await prefs.setBool('sound_muted', _isSoundMuted);
      await prefs.setBool('bell_muted', _isBellMuted);
      
      
    } catch (e) {
      
    }
  }

  // 🎯 PRIORITY-BASED AUDIO STATUS UPDATE
  // Priority Order: Alarm (1) > Trouble (2) > Drill (3)
  void updateAudioStatusFromButtons({
    required bool isDrillActive,
    required bool isAlarmActive,
    required bool isTroubleActive,
    required bool isSilencedActive,
  }) {
    
    
    
    
    
    

    // Update logical states first
    _isDrillActive = isDrillActive;
    _isAlarmActive = isAlarmActive;
    _isSilencedActive = isSilencedActive;

    // Handle trouble state separately for priority logic
    bool wasTroubleActive = _isTroubleActive;
    _isTroubleActive = isTroubleActive;

    if (_isSoundMuted) {
      
      _stopAllAudioPlayback();
      return;
    }

    // 🚨 PRIORITY 1: ALARM (Highest Priority)
    if (isAlarmActive && !_isSilencedActive) {
      
      _stopDrillSound();
      _stopTroubleBeep();
      _playAlarmSound();
    }
    else if (wasTroubleActive != isTroubleActive) {
      // 🚨 PRIORITY 2: TROUBLE (Medium Priority - only if no alarm)
      if (isTroubleActive) {
        
        _stopDrillSound(); // Stop drill if trouble is active
        _startTroubleBeep();
      } else {
        
        _stopTroubleBeep();
      }
    }

    // 🚨 PRIORITY 3: DRILL (Lowest Priority - only if no alarm/trouble)
    if (isDrillActive && !isAlarmActive && !isTroubleActive) {
      
      _playDrillSound();
    } else if (_isDrillActive && (isAlarmActive || isTroubleActive)) {
      
      _stopDrillSound();
    } else if (!isDrillActive && _drillPlayer.playing) {
      
      _stopDrillSound();
    }

    // Handle Silence (affects alarm sound)
    if (isSilencedActive && _isAlarmActive) {
      
      _stopAlarmSound();
    } else if (!isSilencedActive && _isAlarmActive && !_isSoundMuted) {
      
      _playAlarmSound();
    }

    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  // 🎯 MULTI-INSTANCE AUDIO CONTROL METHODS

  void _playDrillSound() async {
    try {
      
      await _drillPlayer.setLoopMode(LoopMode.one);
      await _drillPlayer.setAsset('assets/sounds/alarm_clock.ogg');
      await _drillPlayer.play();
      
    } catch (e) {
      
    }
  }

  void _stopDrillSound() async {
    try {
      
      await _drillPlayer.stop();
      
    } catch (e) {
      
    }
  }

  void _playAlarmSound() async {
    try {
      
      await _alarmPlayer.setLoopMode(LoopMode.one);
      await _alarmPlayer.setAsset('assets/sounds/alarm_clock.ogg');
      await _alarmPlayer.play();
      
    } catch (e) {
      
    }
  }

  void _stopAlarmSound() async {
    try {
      
      await _alarmPlayer.stop();
      
    } catch (e) {
      
    }
  }

  void _startTroubleBeep() async {
    try {
      

      // Cancel existing timer
      _troubleTimer?.cancel();

      // Validate audio player is ready
      if (!_isInitialized) {
        await initialize();
      }

      // Validate asset exists before playing
      try {
        await _troublePlayer.setAsset('assets/sounds/beep_short.ogg');
        
      } catch (e) {
        
        return;
      }

      // Start periodic beep using dedicated trouble player
      _troubleTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          
          await _troublePlayer.setAsset('assets/sounds/beep_short.ogg');
          await _troublePlayer.play();
        } catch (e) {
          
        }
      });

      
    } catch (e) {
      
    }
  }

  void _stopTroubleBeep() async {
    try {
      
      _troubleTimer?.cancel();
      _troubleTimer = null;
      await _troublePlayer.stop();
      
    } catch (e) {
      
    }
  }

  // Local mute controls
  Future<void> toggleNotificationMute() async {
    _isNotificationMuted = !_isNotificationMuted;
    await _saveLocalSettings();
    
    
    
    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  Future<void> toggleSoundMute() async {
    _isSoundMuted = !_isSoundMuted;
    await _saveLocalSettings();

    

    // Stop all sounds if muted
    if (_isSoundMuted) {
      
      _stopAllAudioPlayback();
    } else {
      
      // 🔥 CRITICAL FIX: Use priority-based unmute logic instead of naive playback
      _handleAudioUnmuteWithPriority();
    }

    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  Future<void> toggleBellMute() async {
    _isBellMuted = !_isBellMuted;
    await _saveLocalSettings();
    
    
    
    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  void _stopAllAudioPlayback() {
    
    _stopDrillSound();
    _stopAlarmSound();
    _stopTroubleBeep();

    // 🔥 CRITICAL FIX: Preserve logical states for audio restoration
    // DO NOT reset _isDrillActive, _isAlarmActive, _isTroubleActive, _isSilencedActive
    // These states are needed to restart audio when unmuted

    
  }

  // 🎯 PRIORITY-BASED UNMUTE LOGIC
  // Ensures proper priority when restarting audio after mute
  void _handleAudioUnmuteWithPriority() {
    

    // 🚨 PRIORITY 1: ALARM (Highest Priority)
    if (_isAlarmActive && !_isSilencedActive) {
      
      _playAlarmSound();
      return; // Alarm takes priority, stop evaluating further
    }

    // ⚠️ PRIORITY 2: TROUBLE (Medium Priority - only if no alarm)
    if (_isTroubleActive) {
      
      _startTroubleBeep();
      return; // Trouble takes priority over drill
    }

    // 🔧 PRIORITY 3: DRILL (Lowest Priority - only if no alarm/trouble)
    if (_isDrillActive) {
      
      _playDrillSound();
      return; // Drill has lowest priority
    }

    
  }

  // Public method to stop all sounds immediately (used by system reset)
  void stopAllAudioImmediately() {
    
    _stopAllAudioPlayback();
  }

  // 🎵 SYSTEM SOUND EFFECTS (using alarm player for system sounds)
  Future<void> playSystemResetSound() async {
    try {
      
      await _alarmPlayer.setLoopMode(LoopMode.off);
      await _alarmPlayer.setAsset('assets/sounds/system reset.mp3');
      await _alarmPlayer.play();
      
    } catch (e) {
      
    }
  }

  Future<void> playSystemNormalSound() async {
    try {
      
      await _alarmPlayer.setLoopMode(LoopMode.off);
      await _alarmPlayer.setAsset('assets/sounds/system normal.mp3');
      await _alarmPlayer.play();
      
    } catch (e) {
      
    }
  }

  // Getters untuk current status
  bool get isNotificationMuted => _isNotificationMuted;
  bool get isSoundMuted => _isSoundMuted;
  bool get isBellMuted => _isBellMuted;
  bool get isDrillActive => _isDrillActive;
  bool get isAlarmActive => _isAlarmActive;
  bool get isTroubleActive => _isTroubleActive;
  bool get isSilencedActive => _isSilencedActive;

  // Get current audio status map
  Map<String, bool> getCurrentAudioStatus() {
    return {
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    };
  }

  void dispose() {
    
    _troubleTimer?.cancel();
    _alarmPlayer.dispose();
    _troublePlayer.dispose();
    _drillPlayer.dispose();
    _audioStatusController.close();
    
  }
}
