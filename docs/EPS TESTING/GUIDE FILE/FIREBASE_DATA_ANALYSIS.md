# Firebase Data Analysis - Fire Alarm Monitoring System

## Overview
This document explains the Firebase data structure in the `all_slave_data/raw_data` node and how the unified parser interprets this data to provide meaningful zone status information.

## Data Format Structure

### 1. Raw Data Format
The fire alarm system transmits data in a structured hexadecimal format:

```
<STX>[Device Data][Device Data]...[Device Data]<ETX>
```

Where:
- **STX** (0x02 or `<STX>`): Start of Text marker
- **ETX** (0x03 or `<ETX>`): End of Text marker
- Each device transmits 6 characters minimum:
  - 2 characters: Device address (hexadecimal)
  - 4+ characters: Zone status data (hexadecimal)

### 2. Device Addressing
- Total devices: 63 (addresses 01-3F in hex)
- Each device manages 5 zones
- Total zones in system: 63 × 5 = 315 zones

### 3. Zone Mapping Logic
```
Device 01 → Zones 1-5
Device 02 → Zones 6-10
Device 03 → Zones 11-15
...
Device 63 → Zones 311-315
```

Formula to calculate zone number:
```
Global Zone Number = ((Device Number - 1) × 5) + Zone In Device
```

### 4. Status Byte Decoding
Each device's status is transmitted as hexadecimal bytes. Each byte contains information for 2 zones:

**Single Status Byte (8 bits):**
```
Bit 7: Zone 4 Trouble
Bit 6: Zone 4 Alarm
Bit 5: Zone 3 Trouble
Bit 4: Zone 3 Alarm
Bit 3: Zone 2 Trouble
Bit 2: Zone 2 Alarm
Bit 1: Zone 1 Trouble
Bit 0: Zone 1 Alarm
```

### 5. Example Data Parsing

Let's analyze sample raw data:
```
<STX>0100FF0200AA0300CC...<ETX>
```

Breakdown:
- `01`: Device 01 address
- `00FF`: Status bytes for Device 01
  - `00`: Zones 1-2 status (00h = 00000000b) → All normal
  - `FF`: Zones 3-4 status (FFh = 11111111b) → All zones have alarm AND trouble
- `02`: Device 02 address
- `00AA`: Status bytes for Device 02
  - `00`: Zones 1-2 normal
  - `AA`: Zones 3-4 status (AAh = 10101010b)
    - Zone 3: Trouble (bit 5=1)
    - Zone 4: Alarm (bit 6=1)
- ... and so on for all 63 devices

## Status Interpretation

### Zone Status Types
1. **ALARM** (Red)
   - Alarm bit is set (1)
   - Indicates fire/smoke detection
   - Highest priority

2. **TROUBLE** (Orange)
   - Trouble bit is set (1)
   - Indicates device fault, wiring issue, or maintenance needed
   - Second priority

3. **ACTIVE** (Light Blue)
   - Zone is active but no alarm/trouble
   - Normal monitoring state

4. **NORMAL** (White)
   - No active conditions
   - All bits cleared (0)

5. **OFFLINE** (Grey)
   - Device not responding
   - No data received from device

### System Context Determination
The system evaluates overall status based on all zones:

1. **SYSTEM OFFLINE**
   - Connected devices = 0
   - No communication from any device

2. **ALARM ACTIVE**
   - Total alarm zones > 0
   - Total trouble zones = 0

3. **ALARM WITH TROUBLE CONDITION**
   - Total alarm zones > 0
   - Total trouble zones > 0

4. **TROUBLE CONDITION**
   - Total alarm zones = 0
   - Total trouble zones > 0

5. **PARTIAL CONNECTION**
   - Some devices offline (connected < 63)
   - No active alarms or troubles

6. **SYSTEM NORMAL**
   - All devices connected
   - No alarms or troubles

## Unified Parser Implementation

The `UnifiedFireAlarmParser` processes the raw data through these steps:

### 1. Data Cleaning
```dart
// Remove STX/ETX markers
cleanData = rawData.replaceAll(RegExp(r'\x02'), ''); // Remove STX
cleanData = cleanData.replaceAll(RegExp(r'\x03'), ''); // Remove ETX
```

### 2. Device Parsing Loop
```dart
for (int deviceIndex = 0; deviceIndex < 63; deviceIndex++) {
  // Extract 6 characters per device
  final deviceData = cleanData.substring(deviceIndex * 6, deviceIndex * 6 + 6);
  final deviceAddress = deviceData.substring(0, 2);
  final statusHex = deviceData.substring(2);
  final statusByte = int.parse(statusHex, radix: 16);

  // Parse each of the 5 zones
  for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
    // Map bits to zone status
    bool hasAlarm = (statusByte & alarmBitMask) != 0;
    bool hasTrouble = (statusByte & troubleBitMask) != 0;
    // ... determine final status
  }
}
```

### 3. Bit Masking Logic
```dart
switch (zoneIndex) {
  case 0: // Zone 1
    hasAlarm = (statusByte & 0x01) != 0;  // Bit 0
    hasTrouble = (statusByte & 0x02) != 0; // Bit 1
    break;
  case 1: // Zone 2
    hasAlarm = (statusByte & 0x04) != 0;  // Bit 2
    hasTrouble = (statusByte & 0x08) != 0; // Bit 3
    break;
  // ... etc for zones 3-5
}
```

## Real-World Examples

### Example 1: Normal System
```
Raw Data: <STX>010000020000030000...630000<ETX>
```
Interpretation:
- All devices reporting 00h status
- All zones normal
- System context: SYSTEM NORMAL

### Example 2: Single Zone Alarm
```
Raw Data: <STX>010100020000030000...630000<ETX>
```
Interpretation:
- Device 01, Zone 1 has alarm (01h = 00000001b)
- All other zones normal
- System context: ALARM ACTIVE

### Example 3: Multiple Conditions
```
Raw Data: <STX>01030202AAAA03FF00...630000<ETX>
```
Interpretation:
- Device 01:
  - Zone 1: Trouble (bit 1=1)
  - Zone 2: Alarm (bit 2=1)
- Device 02:
  - Zone 1: Trouble (bit 1=1)
  - Zone 2: Alarm (bit 2=1)
  - Zone 3: Trouble (bit 5=1)
  - Zone 4: Alarm (bit 6=1)
- Device 03:
  - Zone 1: Alarm (bit 0=1)
  - Zone 2: Alarm (bit 2=1)
  - Zone 3: Alarm (bit 4=1)
  - Zone 4: Alarm (bit 6=1)
- System context: ALARM WITH TROUBLE CONDITION

## Best Practices for Data Interpretation

1. **Always validate data length** before parsing
2. **Check for STX/ETX markers** to ensure complete transmission
3. **Handle missing/partial data** gracefully - mark zones as OFFLINE
4. **Cache last known state** for offline zones
5. **Implement timeout logic** - if no data for 30+ seconds, mark as offline
6. **Use bit masking** for efficient status extraction
7. **Maintain device-to-zone mapping** consistency

## Troubleshooting Common Issues

### Issue: Garbled Data
- Check for non-hexadecimal characters
- Verify STX/ETX markers are present
- Ensure data length is multiple of 6 (63 devices × 6 chars)

### Issue: All Zones Offline
- Check Firebase connection
- Verify data path: `all_slave_data/raw_data`
- Check if system is actually offline

### Issue: Incorrect Zone Mapping
- Verify device address parsing (hex vs decimal)
- Check zone calculation formula
- Ensure consistent numbering (1-based vs 0-based)

### Issue: Status Not Updating
- Check Firebase listeners are active
- Verify data freshness timestamp
- Check if parser is being called

## Integration with UI

The parsed data is used to:
1. **Update zone colors** in the monitoring UI
2. **Display system status** with appropriate colors
3. **Show active alarms/troubles** in lists
4. **Trigger notifications** for status changes
5. **Log events** to history
6. **Update connection indicators**

## Summary

The Firebase `all_slave_data/raw_data` contains a compact binary representation of all 315 zones in the fire alarm system. The unified parser converts this raw hexadecimal data into meaningful zone status information that the application uses to display real-time monitoring data, trigger alarms, and maintain system awareness.

The key to understanding the data is recognizing that:
- Each device reports 5 zones in a compact byte format
- Bits within each byte represent alarm and trouble states
- The system aggregates all zone states to determine overall status
- The parser maintains mapping between device addresses and global zone numbers