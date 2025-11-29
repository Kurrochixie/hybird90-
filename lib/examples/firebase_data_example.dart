import 'dart:developer' as developer;
import '../unified_fire_alarm_parser.dart';

/// Example demonstrating how to parse Firebase data using the unified parser
class FirebaseDataExample {
  /// Example 1: Normal system data
  static const String normalSystemData = '<STX>0100000200000300000400000500000600000700000800000900000A00000B00000C00000D00000E00000F00001000001100001200001300001400001500001600001700001800001900001A00001B00001C00001D00001E00001F00002000002100002200002300002400002500002600002700002800002900002A00002B00002C00002D00002E00002F00003000003100003200003300003400003500003600003700003800003900003A00003B00003C00003D00003E00003F0000<ETX>';

  /// Example 2: Single alarm zone
  static const String singleAlarmData = '<STX>0101000200000300000400000500000600000700000800000900000A00000B00000C00000D00000E00000F00001000001100001200001300001400001500001600001700001800001900001A00001B00001C00001D00001E00001F00002000002100002200002300002400002500002600002700002800002900002A00002B00002C00002D00002E00002F00003000003100003200003300003400003500003600003700003800003900003A00003B00003C00003D00003E00003F0000<ETX>';

  /// Example 3: Multiple alarms and troubles
  static const String multipleAlarmsData = '<STX>01030202AAAA03FF000400000500000600000700000800000900000A00000B00000C00000D00000E00000F00001000001100001200001300001400001500001600001700001800001900001A00001B00001C00001D00001E00001F00002000002100002200002300002400002500002600002700002800002900002A00002B00002C00002D00002E00002F00003000003100003200003300003400003500003600003700003800003900003A00003B00003C00003D00003E00003F0000<ETX>';

  /// Parse and display example data
  static Future<void> demonstrateParsing() async {
    developer.log('🔥 FIRE ALARM DATA PARSING EXAMPLES\n');
    developer.log('=' * 60);

    // Example 1: Normal System
    await parseAndDisplay('NORMAL SYSTEM', normalSystemData);

    // Example 2: Single Alarm
    await parseAndDisplay('SINGLE ALARM ZONE', singleAlarmData);

    // Example 3: Multiple Conditions
    await parseAndDisplay('MULTIPLE ALARMS & TROUBLES', multipleAlarmsData);
  }

  static Future<void> parseAndDisplay(String title, String rawData) async {
    developer.log('\n📊 $title');
    developer.log('-' * 40);

    try {
      // Parse using unified parser
      final result = await UnifiedFireAlarmAPI.parse(rawData);

      if (result.hasError) {
        developer.log('❌ Error: ${result.errorMessage}');
        return;
      }

      // Display system status
      final status = result.systemStatus;
      developer.log('System Context: ${status.systemContext}');
      developer.log('Connected Devices: ${status.connectedDevices}/63');
      developer.log('Alarm Zones: ${status.totalAlarmZones}');
      developer.log('Trouble Zones: ${status.totalTroubleZones}');

      // Show first few zones with non-normal status
      final activeZones = result.zones.values
          .where((z) => z.status != 'Normal')
          .take(10)
          .toList();

      if (activeZones.isNotEmpty) {
        developer.log('\nActive Zones:');
        for (final zone in activeZones) {
          developer.log('  Zone ${zone.zoneNumber}: ${zone.status} - ${zone.description}');
        }
      }

    } catch (e) {
      developer.log('❌ Parsing failed: $e');
    }
  }

  /// Explain the data format
  static void explainDataFormat() {
    developer.log('\n${'=' * 60}');
    developer.log('📚 DATA FORMAT EXPLANATION');
    developer.log('=' * 60);
    developer.log('''
1. DEVICE STRUCTURE:
   • Each device has a 2-character hex address (01-3F = 1-63)
   • Followed by 4 characters of status data (hexadecimal)
   • Total: 6 characters per device

2. ZONE MAPPING:
   • Device 01 = Zones 1-5
   • Device 02 = Zones 6-10
   • ...
   • Device 63 = Zones 311-315

3. STATUS BYTE DECODING (Example: 0x55 = 01010101):
   Bit 7: Zone 4 Trouble
   Bit 6: Zone 4 Alarm
   Bit 5: Zone 3 Trouble
   Bit 4: Zone 3 Alarm
   Bit 3: Zone 2 Trouble
   Bit 2: Zone 2 Alarm
   Bit 1: Zone 1 Trouble
   Bit 0: Zone 1 Alarm

4. EXAMPLE DECODING:
   Device Data: "01AA"
   - "01" = Device address 1
   - "AA" = 10101010 in binary
   - Zone 1: Trouble (bit 1=1)
   - Zone 2: Alarm (bit 2=1)
   - Zone 3: Trouble (bit 5=1)
   - Zone 4: Alarm (bit 6=1)

5. COLOR CODING:
   • RED: Zone in ALARM
   • ORANGE: Zone in TROUBLE
   • BLUE: Zone ACTIVE
   • WHITE: Zone NORMAL
   • GREY: Zone OFFLINE
''');
  }
}

/// Main function to run the example
void main() async {
  await FirebaseDataExample.demonstrateParsing();
  FirebaseDataExample.explainDataFormat();
}