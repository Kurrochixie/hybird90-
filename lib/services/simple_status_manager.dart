class SimpleStatusManager {
  // Essential state only
  int _alarmCount = 0;
  int _troubleCount = 0;
  bool _hasData = false;
  bool _hasActiveZones = false;

  // Accumulated counts for LED-based tracking
  int _accumulatedAlarmCount = 0;
  int _accumulatedTroubleCount = 0;
  bool _isAccumulationMode = false;

  // 🔔 Bell accumulation for LED-based tracking (SAME AS ZONE)
  int _accumulatedBellCount = 0;
  bool _isBellAccumulationMode = false;

  /// 🎯 PURE COUNT LOGIC - Your 4 Rules + All Zones Offline Detection
  String getStatus() {
    // Rule 4: no data = NO DATA (Firebase disconnected)
    if (!_hasData) return 'NO DATA';

    // Rule 4b: all zones offline = NO DATA (Firebase connected but no active zones)
    if (!_hasActiveZones) return 'NO DATA';

    // 🔄 NEW: In accumulation mode, use accumulated counts for status determination
    if (_isAccumulationMode) {
      // Rule 1: accumulated alarm > 0 = ALARM (highest priority)
      if (_accumulatedAlarmCount > 0) return 'ALARM';

      // Rule 2: accumulated trouble > 0 = SYSTEM TROUBLE
      if (_accumulatedTroubleCount > 0) return 'SYSTEM TROUBLE';

      // Rule 3: accumulated counts == 0 && hasActiveZones = SYSTEM NORMAL
      return 'SYSTEM NORMAL';
    }

    // Rule 1: alarm > 0 = ALARM (highest priority)
    if (_alarmCount > 0) return 'ALARM';

    // Rule 2: trouble > 0 = SYSTEM TROUBLE
    if (_troubleCount > 0) return 'SYSTEM TROUBLE';

    // Rule 3: alarm && trouble == 0 && hasActiveZones = SYSTEM NORMAL
    return 'SYSTEM NORMAL';
  }

  /// Update counts from parsing (simple and direct)
  void updateCounts({
    required int alarmCount,
    required int troubleCount,
    required bool hasData,
    required bool hasActiveZones,
  }) {
    _alarmCount = alarmCount;
    _troubleCount = troubleCount;
    _hasData = hasData;
    _hasActiveZones = hasActiveZones;
  }

  /// Update accumulated counts from zone accumulator
  void updateAccumulatedCounts({
    required int accumulatedAlarmCount,
    required int accumulatedTroubleCount,
    required bool isAccumulationMode,
  }) {
    _accumulatedAlarmCount = accumulatedAlarmCount;
    _accumulatedTroubleCount = accumulatedTroubleCount;
    _isAccumulationMode = isAccumulationMode;
  }

  /// 🔔 Update bell accumulated counts from bell accumulator (SAME AS ZONE)
  void updateBellAccumulatedCounts({
    required int accumulatedBellCount,
    required bool isBellAccumulationMode,
  }) {
    _accumulatedBellCount = accumulatedBellCount;
    _isBellAccumulationMode = isBellAccumulationMode;
  }

  /// Simple getters
  int get alarmCount => _alarmCount;
  int get troubleCount => _troubleCount;
  bool get hasData => _hasData;
  bool get hasActiveZones => _hasActiveZones;

  // Accumulated counts getters
  int get accumulatedAlarmCount => _accumulatedAlarmCount;
  int get accumulatedTroubleCount => _accumulatedTroubleCount;
  bool get isAccumulationMode => _isAccumulationMode;

  // 🔔 Bell accumulated counts getters (SAME AS ZONE)
  int get accumulatedBellCount => _accumulatedBellCount;
  bool get isBellAccumulationMode => _isBellAccumulationMode;

  /// Direct color mapping
  String getColor() {
    final status = getStatus();
    switch (status) {
      case 'ALARM': return 'Alarm';
      case 'SYSTEM TROUBLE': return 'Trouble';
      case 'SYSTEM NORMAL': return 'Normal';
      case 'NO DATA': return 'Disabled';
      default: return 'Normal';
    }
  }

  /// Reset all counts and states
  void reset() {
    _alarmCount = 0;
    _troubleCount = 0;
    _hasData = false;
    _hasActiveZones = false;
    _accumulatedAlarmCount = 0;
    _accumulatedTroubleCount = 0;
    _isAccumulationMode = false;
    // 🔔 Reset bell accumulation (SAME AS ZONE)
    _accumulatedBellCount = 0;
    _isBellAccumulationMode = false;
  }

  /// Reset only accumulated counts (when LED turns off)
  void resetAccumulatedCounts() {
    _accumulatedAlarmCount = 0;
    _accumulatedTroubleCount = 0;
    _isAccumulationMode = false;
    // 🔔 Reset bell accumulation (SAME AS ZONE)
    _accumulatedBellCount = 0;
    _isBellAccumulationMode = false;
  }
}