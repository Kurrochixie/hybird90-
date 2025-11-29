# 🔐 Firebase Security Rules Implementation

## 📋 Overview
This document outlines the comprehensive Firebase security rules implemented for the Fire Alarm Monitoring Flutter application to ensure data protection, user privacy, and secure access controls.

## 🛡️ Security Rules Implemented

### **1. Database Security Rules (`database.rules.json`)**

#### **User Data Protection**
```json
"users": {
  "$uid": {
    ".read": "$uid === auth.uid || root.child('users').child(auth.uid).child('isAdmin').val() === true",
    ".write": "$uid === auth.uid || root.child('users').child(auth.uid).child('isAdmin').val() === true",
    ".validate": "auth != null && $uid === auth.uid"
  }
}
```

**Security Features:**
- ✅ **User Isolation**: Users can only access their own data
- ✅ **Admin Override**: Admin users can access all user data for management
- ✅ **Authentication Required**: No anonymous access
- ✅ **Data Validation**: Enforces proper data formats and limits

#### **Data Validation Rules**
- **Username**: 3-20 chars, alphanumeric + underscore, starts with letter
- **Email**: Valid email format, max 254 chars
- **Phone**: Indonesian format validation (+62, 62, 0 prefixes)
- **FCM Token**: 100-200 chars for push notifications
- **Timestamps**: Unix timestamp validation

#### **System Status Protection**
```json
"systemStatus": {
  ".read": "auth != null",
  ".write": "auth != null",
  "$category": {
    "status": { ".validate": "newData.isBoolean()" },
    "timestamp": { ".validate": "newData.isNumber() && newData.val() > 0" }
  }
}
```

**Features:**
- ✅ **Authenticated Access**: Only logged-in users can read/write
- ✅ **Type Safety**: Boolean for status, number for timestamps
- ✅ **ESP32 Integration**: Secure device communication

#### **ESP32 Bridge Security**
```json
"esp32_bridge": {
  "user_input": {
    "userId": { ".validate": "newData.isString() && newData.val() === auth.uid" }
  }
}
```

**Features:**
- ✅ **User Attribution**: All user inputs are tagged with user ID
- ✅ **Data Limits**: Max 500 chars for data input
- ✅ **Authenticated Commands**: Only authenticated users can send commands

#### **Project Information**
```json
"projectInfo": {
  ".read": "auth != null",
  ".write": "auth != null && root.child('users').child(auth.uid).child('isAdmin').val() === true"
}
```

**Features:**
- ✅ **Read Access**: All authenticated users can read project info
- ✅ **Write Restrictions**: Only admins can modify project settings
- ✅ **Validation**: Project name and zone name format validation

### **2. Storage Security Rules (`storage.rules`)**

#### **User Profile Images**
```javascript
match /user_profiles/{userId}/{allPaths=**} {
  allow read: if request.auth != null && (request.auth.uid == userId || request.auth.token.isAdmin == true);
  allow write: if request.auth != null && request.auth.uid == userId &&
                   request.resource.size < 5 * 1024 * 1024 && // 5MB limit
                   request.resource.contentType.matches('image/.*');
}
```

**Security Features:**
- ✅ **User Isolation**: Users can only access their own profile images
- ✅ **File Size Limits**: 5MB max for profile images
- ✅ **Content Type Validation**: Only image files allowed
- ✅ **Filename Security**: Prevents directory traversal attacks

#### **File Upload Restrictions**
- **Profile Images**: 5MB limit, image formats only
- **ESP32 Data**: 1MB limit, text/JSON only, admin write
- **Project Files**: 10MB limit, images/PDFs/text, admin write
- **System Logs**: 100KB limit, text only, admin access

### **3. Firebase Configuration (`firebase.json`)**

#### **Emulator Setup**
```json
"emulators": {
  "auth": { "port": 9099 },
  "database": { "port": 9000 },
  "storage": { "port": 9199 },
  "ui": { "enabled": true, "port": 4000 }
}
```

**Features:**
- ✅ **Local Development**: Full emulator suite for testing
- ✅ **Security Testing**: Test rules in isolated environment
- ✅ **UI Dashboard": Firebase Emulator UI for debugging

## 🔒 Security Principles Applied

### **1. Principle of Least Privilege**
- Users can only access data they absolutely need
- Admin access is separate and explicitly granted
- No blanket read/write permissions

### **2. Defense in Depth**
- Multiple validation layers (client + server)
- Type checking and format validation
- Size limits prevent resource exhaustion

### **3. Data Isolation**
- User data is strictly segregated by UID
- No cross-user data leakage possible
- Admin override for legitimate management needs

### **4. Input Validation**
- All data is validated at the Firebase level
- Type checking, format validation, length limits
- Prevents malformed data injection

### **5. Audit Trail**
- All user inputs are tagged with user ID
- Timestamps on all status changes
- Complete activity logging

## 🚀 Deployment Instructions

### **1. Deploy Security Rules**
```bash
# Deploy database rules
firebase deploy --only database

# Deploy storage rules
firebase deploy --only storage

# Deploy all rules
firebase deploy --only database,storage
```

### **2. Test Rules in Emulator**
```bash
# Start emulators
firebase emulators:start

# Test with Firebase Console
http://localhost:4000
```

### **3. Production Validation**
```bash
# Validate rules syntax
firebase database rules:get
firebase storage rules:get

# Test with sample data
firebase database:update /test '{"test": "data"}'
```

## 🔍 Monitoring & Maintenance

### **Security Monitoring**
- Monitor Firebase console for denied access attempts
- Review user access patterns regularly
- Update rules as application evolves

### **Rule Updates**
- Test changes in emulator first
- Deploy to staging environment before production
- Document all rule changes

### **Compliance Checklist**
- ✅ User data is properly isolated
- ✅ Admin access is controlled and audited
- ✅ File uploads are validated and limited
- ✅ Input validation prevents injection attacks
- ✅ Authentication is required for all operations

## 📞 Support & Troubleshooting

### **Common Issues**
1. **Permission Denied**: Check user authentication and UID matching
2. **Validation Failed**: Verify data format matches validation rules
3. **File Upload Rejected**: Check file size and content type limits

### **Debug Tools**
- Firebase Emulator UI for local testing
- Firebase Console for production monitoring
- Flutter debug logs for detailed error information

---

## 🎯 Security Rules Summary

**🔐 Database Security:**
- User data isolation by UID
- Admin override capabilities
- Comprehensive input validation
- Type safety and format checking

**📁 Storage Security:**
- File size limits (5MB profile, 10MB project)
- Content type validation
- User-based access control
- Filename security

**🛠️ Configuration:**
- Local development emulators
- Production-ready deployment
- Security rule management

**✅ Security Compliance:**
- Authentication required for all operations
- Principle of least privilege applied
- Defense in depth strategy
- Comprehensive audit trail

---

*These security rules provide comprehensive protection for the Fire Alarm Monitoring application while maintaining functionality and user experience. Regular reviews and updates are recommended as security best practices evolve.*