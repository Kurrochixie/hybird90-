# BASELINE APPLICATION FUNCTIONALITY

## 🔥 **Core Application: Fire Alarm Monitoring System**

### **Main Features:**
1. **User Authentication** (Firebase Auth)
   - Login/Register with email, password, phone
   - Session management with SharedPreferences
   - User profile with photo upload

2. **Real-time Monitoring** (Firebase Realtime Database)
   - 315 zones monitoring (63 modules × 5 zones)
   - ESP32 data parsing with LED status decoding
   - Bell trouble detection
   - Color-coded status visualization

3. **System Control**
   - System Reset functionality
   - Drill mode activation
   - Alarm acknowledgment
   - Audio control (mute/unmute)
   - Local notifications with wake lock

4. **Historical Data**
   - Status logs
   - Connection logs
   - Trouble logs
   - Fire event logs

5. **Configuration Management**
   - Project settings (name, panel type, modules)
   - Zone naming (315 zones configurable)
   - Firebase configuration
   - Interface settings

### **Technical Architecture:**
- **State Management**: Provider pattern
- **Database**: Firebase Realtime Database
- **Authentication**: Firebase Auth
- **Notifications**: Firebase Messaging + Local Notifications
- **Audio**: Custom audio player with background support
- **Real-time**: ESP32 integration via Firebase

### **Security Status (Baseline):**
- ⚠️ **VULNERABLE**: Hardcoded Firebase credentials
- ⚠️ **VULNERABLE**: FCM server key in source code
- ⚠️ **VULNERABLE**: Password storage in plain text
- ✅ **SECURE**: Firebase Auth integration
- ✅ **SECURE**: Session management
- ✅ **SECURE**: Input validation

### **Performance Status:**
- ✅ **Compilation**: No errors or warnings
- ✅ **Dependencies**: All packages compatible
- ✅ **Code Quality**: Well-structured, maintainable
- ⚠️ **Updates**: 40 packages have newer versions

### **User Flow:**
1. **Launch** → Authentication check → Login/Register
2. **Login** → Main Dashboard (4 tabs: Home, Monitoring, Control, History)
3. **Configuration** → Project setup → Zone naming → Main app
4. **Monitoring** → Real-time data → Alert system → Control actions

### **Integration Points:**
- Firebase (Auth, Database, Messaging, Storage, Analytics)
- ESP32 Hardware (Real-time zone data)
- Local Audio System (Notifications)
- Background Services (Persistent monitoring)

---

*Documentation created on: $(date)*
*Status: Ready for security refactoring*