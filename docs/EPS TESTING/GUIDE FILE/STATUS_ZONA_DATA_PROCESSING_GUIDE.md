🔍 SISTEM PENGOLAHAN DATA SERIAL & GENERASI OUTPUT - PENJELASAN KONSEPTUAL
📊 ALUR PENGOLAHAN DATA INPUT
1. SUMBER DATA & KARAKTERISTIK
Sistem menerima aliran data biner dari perangkat keras melalui koneksi serial dengan karakteristik:
bentuk data asli tanpa jawaban slave :
40DF 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63

contoh bentuk data dengan jawaban slave address 01
40DF 010000 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63

dan seterusnya...

Format: Data mentah berupa byte stream dengan protokol custom

Struktur: Terdiri dari beberapa jenis paket data yang berbeda

Frekuensi: Data datang secara real-time dengan interval reguler

Integritas: Memerlukan validasi dan error checking

2. JENIS-JENIS PAKET DATA YANG DIPROSES
A. PAKET STATUS ZONA DETEKSI
text
Struktur: [Start Byte] + [Alamat Perangkat] + [Status Trouble] + [Status Alarm]
Contoh:   [0x02]       + [01]              + [85]            + [A2]
Start Byte: Penanda awal paket (nilai hex 02)

Alamat Perangkat: Identifier unik untuk setiap modul deteksi

Status Trouble: Bitmask untuk 5 zona trouble

Status Alarm: Bitmask untuk 5 zona alarm

B. PAKET STATUS INDIKATOR PANEL
text
Struktur: [Start Byte] + [Data Status LED]
Contoh:   [0x03]       + [03BD]
Menunjukkan status visual panel kontrol utama

Setiap bit merepresentasikan indikator berbeda

C. PAKET SINYAL SIKLUS POLLING
Menandai berakhirnya satu siklus komunikasi dengan semua perangkat

Digunakan untuk monitoring health system

🔧 PROSES TRANSFORMASI DATA
3. TAHAP PENGOLAHAN DATA MENTAH
TAHAP 1 - EKSTRAKSI PAKET
plaintext
Input: Stream byte campuran
Proses: Memisahkan berdasarkan pola header yang dikenali
Output: Paket-paket terpisah berdasarkan jenisnya
TAHAP 2 - DECODING DATA HEKSADESIMAL
plaintext
Input: String heksadesimal (contoh: "0185A2")
Proses: Konversi heksadesimal → desimal → analisis bitwise
Output: Nilai numerik dan status bit individual
TAHAP 3 - INTERPRETASI BITWISE
Contoh decoding "85" heksadesimal:

text
Nilai: 133 desimal
Binary: 10000101
Interpretasi per bit:
  Bit 0: 1 → Zona 1: TROUBLE ACTIVE
  Bit 1: 0 → Zona 2: TROUBLE INACTIVE  
  Bit 2: 1 → Zona 3: TROUBLE ACTIVE
  Bit 3: 0 → Zona 4: TROUBLE INACTIVE
  Bit 4: 0 → Zona 5: TROUBLE INACTIVE
TAHAP 4 - MAPPING STATUS BERDASARKAN PRIORITAS
plaintext
Hierarki Status (tinggi ke rendah):
1. STATUS DARURAT     → Kondisi kritis memerlukan respons immediat
2. STATUS PERINGATAN  → Masalah yang perlu perhatian
3. STATUS NORMAL      → Operasi normal
4. STATUS KOMUNIKASI  → Masalah koneksi

A. INDIKATOR ZONA DETEKSI
Representasi: kotak zona dengan kode warna
Skema Warna:
  █ MERAH   : Kondisi darurat terdeteksi
  █ KUNING  : Peringatan/masalah terdeteksi  
  █ HIJAU   : Status normal
  █ ABU-ABU : Tidak ada komunikasi
  █ PUTIH   : Standby/tidak aktif
B. PANEL INDIKATOR SISTEM
LED Virtual status pada home dengan makna:
  ● DAYA UTAMA  : Status power supply utama
  ● DAYA CADANGAN: Status battery backup
  ● ALARM       : Sistem dalam kondisi alarm
  ● MASALAH     : Terdapat problem sistem
  ● SUPERVISI   : Monitoring aktif
  ● SILENCE     : Alarm didiamkan sementara
  ● DISABLED    : Fungsi non-aktif
C. TAMPILAN STATUS SISTEM
status warna box container zona dengan prioritas:
  "DARURAT"      → Kondisi kritis (warna merah)
  "MASALAH KONEKSI" → Gangguan komunikasi (warna kuning)
  "SISTEM NORMAL" → Operasi normal (warna hijau)
  "TERPUTUS"     → Tidak terkoneksi (warna abu-abu)

A. PENCATATAN EVENT REAL-TIME
plaintext
Format: [Timestamp] [Level] [Kategori] Deskripsi
Contoh:
  [2024-01-01 10:30:25] [ALARM] [ZONA] Darurat - Perangkat 01 - Zona 3
  [2024-01-01 10:30:26] [PERINGATAN] [ZONA] Masalah - Perangkat 02 - Zona 8
  [2024-01-01 10:30:27] [INFO] [SISTEM] Koneksi terestablish

 
8. SISTEM THRESHOLD & KONFIRMASI
A. DETEKSI BERUNTUN
plaintext
Logic: Membutuhkan multiple deteksi sebelum trigger aksi
Contoh: 
  - 3x deteksi darurat beruntun → trigger popup
  - Mencegah false positive dari noise sementara
B. AUTO-RECOVERY
plaintext
Mekanisme: 
  - Monitor perangkat yang pernah mengalami masalah
  - Jika normal selama beberapa siklus → reset status problem

9. MANAJEMEN STATUS KOMUNIKASI
A. POOLING CYCLE MANAGEMENT
plaintext
Konsep: Periodic check semua perangkat terdaftar
Proses:
  1. Inisiasi siklus polling
  2. Kumpulkan respons semua perangkat
  3. Identifikasi yang tidak merespons
  4. Update status komunikasi
  5. Generate report
B. GRACEful DEGRADATION
plaintext
Strategi ketika masalah terjadi:
  - Prioritas data: utamakan informasi darurat
  - Fallback visual: indikator komunikasi problem
  - Buffering: simpan data sementara jika possible
  - Auto-reconnect: attempt koneksi ulang otomatis
🛡️ MEKANISME KEAMANAN & RELIABILITAS
10. ERROR HANDLING
A. VALIDASI DATA INPUT
plaintext
Proteksi: 
  - Pattern matching untuk format data
  - Length validation
  - Checksum/integrity checking
  - Boundary checking untuk nilai
B. BUFFER MANAGEMENT
plaintext
Strategi:
  - Fixed-size buffer untuk mencegah memory exhaustion
  - Automatic cleanup ketika overflow
  - Priority-based data processing
11. PERFORMANCE OPTIMIZATION
A. BATCH PROCESSING
plaintext
Teknik: 
  - Kumpulkan multiple update sebelum render
  - Minimize UI refresh frequency
  - Prioritize critical updates

📈 DIAGRAM ALUR DATA KOMPLIT
text
DATA INPUT
    ↓
[Serial Stream Processing]
    ├── Paket Status Zona → Decoding Bitwise → Mapping Prioritas
    ├── Paket Status Panel → Decoding LED → Update Visual Indicator  
    └── Paket Sinyal Sistem → Health Checking → Status Reporting
    ↓
[Multi-Channel Output Generation]
    ├── VISUAL: Warna Zona, LED Panel, Status Text
    ├── TEXTUAL: File Logging, Real-time Monitoring
    ├── AUDIO: Alert Sounds, Notification Tones
   
    ↓
[Feedback & Control Loop]
    ├── Threshold Monitoring
    ├── Auto-recovery Triggers

---

## 🔄 LOGIC PENGOLAHAN DATA - IMPLEMENTASI DETAIL

### 3.1 **Proses Parsing dari ESP32**

#### **A. Serial Data Reception**
```dart
// Contoh implementasi parsing data serial
class Esp32DataParser {
  static const int START_BYTE = 0x02;
  static const int PANEL_STATUS_BYTE = 0x03;
  
  List<String> parseRawData(String rawData) {
    // Step 1: Split data berdasarkan header
    List<String> packets = _extractPackets(rawData);
    
    // Step 2: Validasi setiap paket
    List<String> validPackets = _validatePackets(packets);
    
    return validPackets;
  }
  
  List<String> _extractPackets(String data) {
    // Logic untuk memisahkan paket berdasarkan pattern
    // Contoh: "40DF 010000 02 03..." → ["010000", "02", "03", ...]
  }
}
```

#### **B. Packet Structure Recognition**
- **Zone Status Packet**: `[0x02][Alamat][Status Trouble][Status Alarm]`
- **Panel Indicator Packet**: `[0x03][LED Status Data]`
- **Polling Cycle Packet**: `[End of Cycle Marker]`

### 3.2 **Transformasi Data**

#### **A. Hexadecimal to Binary Conversion**
```dart
class DataTransformer {
  ZoneStatus transformHexToZoneStatus(String hexData) {
    int decimalValue = int.parse(hexData, radix: 16);
    String binary = decimalValue.toRadixString(2).padLeft(8, '0');
    
    return ZoneStatus(
      zone1: _getBitStatus(binary, 0),
      zone2: _getBitStatus(binary, 1),
      zone3: _getBitStatus(binary, 2),
      zone4: _getBitStatus(binary, 3),
      zone5: _getBitStatus(binary, 4),
    );
  }
  
  ZoneBitStatus _getBitStatus(String binary, int bitPosition) {
    bool isActive = binary[bitPosition] == '1';
    return isActive ? ZoneBitStatus.ACTIVE : ZoneBitStatus.INACTIVE;
  }
}
```

#### **B. Status Mapping & Prioritization**
```dart
enum ZonePriority {
  EMERGENCY,    // Darurat - Prioritas tertinggi
  WARNING,      // Peringatan
  NORMAL,       // Normal
  OFFLINE,      // Tidak terkoneksi
  STANDBY       // Standby
}

class StatusMapper {
  ZonePriority mapToPriority(bool hasAlarm, bool hasTrouble, bool isOnline) {
    if (hasAlarm) return ZonePriority.EMERGENCY;
    if (hasTrouble && isOnline) return ZonePriority.WARNING;
    if (!isOnline) return ZonePriority.OFFLINE;
    return ZonePriority.NORMAL;
  }
}
```

### 3.3 **Filter dan Sorting**

#### **A. Real-time Data Filtering**
```dart
class ZoneDataFilter {
  List<ZoneStatus> filterActiveZones(List<ZoneStatus> allZones) {
    return allZones.where((zone) => 
      zone.hasAlarm || zone.hasTrouble || !zone.isOnline
    ).toList();
  }
  
  List<ZoneStatus> sortByPriority(List<ZoneStatus> zones) {
    zones.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return zones;
  }
  
  List<ZoneStatus> filterByDevice(List<ZoneStatus> zones, String deviceId) {
    return zones.where((zone) => zone.deviceId == deviceId).toList();
  }
}
```

#### **B. Historical Data Management**
```dart
class HistoricalDataManager {
  static const int MAX_HISTORY_SIZE = 1000;
  
  void addHistoricalData(ZoneStatus status) {
    _historicalData.add(status);
    if (_historicalData.length > MAX_HISTORY_SIZE) {
      _historicalData.removeAt(0);
    }
  }
  
  List<ZoneStatus> getRecentData(Duration timeRange) {
    DateTime cutoff = DateTime.now().subtract(timeRange);
    return _historicalData.where((data) => 
      data.timestamp.isAfter(cutoff)
    ).toList();
  }
}
```

### 3.4 **Agregasi Data**

#### **A. System-wide Status Aggregation**
```dart
class SystemStatusAggregator {
  SystemOverview generateSystemOverview(List<ZoneStatus> allZones) {
    int totalZones = allZones.length;
    int emergencyZones = _countByPriority(allZones, ZonePriority.EMERGENCY);
    int warningZones = _countByPriority(allZones, ZonePriority.WARNING);
    int normalZones = _countByPriority(allZones, ZonePriority.NORMAL);
    int offlineZones = _countByPriority(allZones, ZonePriority.OFFLINE);
    
    return SystemOverview(
      totalZones: totalZones,
      emergencyCount: emergencyZones,
      warningCount: warningZones,
      normalCount: normalZones,
      offlineCount: offlineZones,
      systemHealth: _calculateSystemHealth(allZones),
    );
  }
  
  double _calculateSystemHealth(List<ZoneStatus> zones) {
    int onlineZones = zones.where((z) => z.isOnline).length;
    return zones.isEmpty ? 0.0 : (onlineZones / zones.length) * 100;
  }
}
```

#### **B. Device Grouping Analysis**
```dart
class DeviceGroupAnalyzer {
  Map<String, DeviceGroupSummary> analyzeByDevice(List<ZoneStatus> zones) {
    Map<String, List<ZoneStatus>> groupedZones = {};
    
    // Group by device
    for (var zone in zones) {
      if (!groupedZones.containsKey(zone.deviceId)) {
        groupedZones[zone.deviceId] = [];
      }
      groupedZones[zone.deviceId]!.add(zone);
    }
    
    // Generate summary for each device
    Map<String, DeviceGroupSummary> summaries = {};
    groupedZones.forEach((deviceId, deviceZones) {
      summaries[deviceId] = DeviceGroupSummary(
        deviceId: deviceId,
        totalZones: deviceZones.length,
        activeAlarms: _countActiveAlarms(deviceZones),
        activeTroubles: _countActiveTroubles(deviceZones),
        lastUpdate: _getLatestTimestamp(deviceZones),
      );
    });
    
    return summaries;
  }
}
```

### 3.5 **Optimization Strategies**

#### **A. Batch Processing**
```dart
class BatchProcessor {
  static const Duration BATCH_INTERVAL = Duration(milliseconds: 100);
  Timer? _batchTimer;
  List<ZoneStatus> _pendingUpdates = [];
  
  void scheduleUpdate(ZoneStatus status) {
    _pendingUpdates.add(status);
    
    _batchTimer?.cancel();
    _batchTimer = Timer(BATCH_INTERVAL, () {
      _processBatch();
    });
  }
  
  void _processBatch() {
    if (_pendingUpdates.isEmpty) return;
    
    // Process all pending updates at once
    List<ZoneStatus> batch = List.from(_pendingUpdates);
    _pendingUpdates.clear();
    
    // Apply optimizations
    List<ZoneStatus> optimizedBatch = _optimizeBatch(batch);
    
    // Send to UI
    _notifyUI(optimizedBatch);
  }
  
  List<ZoneStatus> _optimizeBatch(List<ZoneStatus> batch) {
    // Remove duplicates
    Map<String, ZoneStatus> latestByZone = {};
    for (var status in batch) {
      latestByZone[status.zoneId] = status;
    }
    
    return latestByZone.values.toList();
  }
}
```

#### **B. Memory Management**
```dart
class MemoryEfficientDataStore {
  static const int MAX_CACHED_ITEMS = 500;
  Queue<ZoneStatus> _dataCache = Queue();
  
  void addData(ZoneStatus data) {
    _dataCache.add(data);
    
    // Auto-cleanup when cache is full
    while (_dataCache.length > MAX_CACHED_ITEMS) {
      _dataCache.removeFirst();
    }
  }
  
  List<ZoneStatus> getRecentData(int count) {
    int startIndex = math.max(0, _dataCache.length - count);
    return _dataCache.toList().sublist(startIndex);
  }
}
```

---

## 🎯 **KEY IMPLEMENTATION POINTS**

### **Performance Considerations:**
1. **Debouncing**: Multiple rapid updates → single UI refresh
2. **Prioritized Processing**: Emergency data processed first
3. **Memory Limits**: Prevent memory leaks with bounded caches
4. **Batch Updates**: Reduce UI refresh frequency

### **Reliability Features:**
1. **Data Validation**: Ensure data integrity before processing
2. **Error Recovery**: Handle corrupted data gracefully
3. **Fallback Mechanisms**: Alternative data sources when primary fails
4. **Health Monitoring**: Track system performance metrics

### **Scalability Design:**
1. **Modular Architecture**: Easy to add new data types
2. **Configurable Parameters**: Adjust processing behavior without code changes
3. **Extensible Filters**: Add new filtering criteria as needed
4. **Plugin System**: Support custom data processors
