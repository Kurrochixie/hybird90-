# Panduan Praktis Claude Code CLI untuk Flutter Fire Alarm System

## Status Instalasi ✅

Claude Code CLI sudah berhasil terinstall dan dikonfigurasi dengan:
- **CLI Version**: Terinstall global ✓
- **Firebase MCP**: Terkonfigurasi dengan auto-approval ✓
- **Workspace**: Flutter project detected ✓
- **Command Parsing**: Berfungsi dengan benar ✓
- **⚠️ API Key**: Diperlukan untuk menjalankan tasks

## Konfigurasi API Key (Langkah Penting!)

### ✅ Z.ai GLM-4.5 (Recommended untuk Bahasa Indonesia)
Claude Code CLI sudah dikonfigurasi untuk Z.ai GLM-4.5:

1. **Dapatkan API Key**: https://z.ai/
2. **Set Environment Variable**:
   ```cmd
   set OPENAI_API_KEY=your-z-ai-api-key-here
   ```

### 📋 Other Providers (Optional)
- **Anthropic Claude**: https://console.anthropic.com/
- **OpenAI**: https://platform.openai.com/api-keys

### 2. Set Environment Variable (Windows)
```cmd
# Untuk session saat ini
set OPENAI_API_KEY=your-api-key-here

# Verifikasi
echo %OPENAI_API_KEY%

# Untuk permanen (System Properties)
# 1. Buka System Properties → Advanced → Environment Variables
# 2. Add new variable: OPENAI_API_KEY
# 3. Value: your-api-key-here
```

### 📖 Panduan Lengkap Z.ai
Lihat `PANDUAN_Z_AI_CONFIGURATION.md` untuk konfigurasi detail Z.ai GLM-4.5

## Cara Penggunaan Dasar

### 1. Analisis Project
```cmd
# Analisis seluruh project Flutter
cline-cli task --workspace . "analisis arsitektur Flutter fire alarm system"

# Analisis file spesifik
cline-cli task --visible-files "lib/main.dart,lib/services/" "review service layer"
```

### 2. Debug dan Fix Bug
```cmd
# Debug spesifik file
cline-cli task --visible-files "lib/services/esp32_zone_parser.dart" "fix parsing bugs"

# Test Firebase connection
cline-cli task --auto-approve-mcp "test Firebase connection"
```

### 3. Development Feature
```cmd
# Tambah fitur baru
cline-cli task --custom-instructions "follow Flutter best practices" "add new notification type"

# Optimasi performa
cline-cli task --visible-files "lib/services/" "optimize notification service performance"
```

## Command Options Lengkap

### Options Penting:
- `--workspace .` : Gunakan current directory
- `--visible-files "file1,file2"` : Fokus ke file tertentu
- `--auto-approve-mcp` : Auto approve Firebase operations
- `--custom-instructions "text"` : Instruksi kustom
- `--resume` : Lanjutkan task sebelumnya

### Contoh Penggunaan Advanced:

#### 1. Code Review Komprehensif
```cmd
cline-cli task --workspace . --custom-instructions "focus on security, performance, and Flutter best practices" "perform comprehensive code review of fire alarm system"
```

#### 2. Firebase Data Analysis
```cmd
cline-cli task --auto-approve-mcp --visible-files "lib/services/auth_service.dart" "analyze Firebase authentication security and suggest improvements"
```

#### 3. ESP32 Integration Debug
```cmd
cline-cli task --visible-files "EPS TESTING/esp32_bridge_ultimate_fix.ino,lib/services/esp32_zone_parser.dart" "debug ESP32 communication issues"
```

## Workflow Recommendasi untuk Project Anda

### 1. Daily Development Workflow
```cmd
# Morning: Check project health
cline-cli task --workspace . "check for any compilation errors or warnings"

# During development: Feature implementation
cline-cli task --visible-files "lib/services/enhanced_notification_service.dart" "implement new notification feature"

# End of day: Code quality check
cline-cli task --workspace . "review today's changes for code quality"
```

### 2. Bug Fixing Workflow
```cmd
# Identify issue
cline-cli task --visible-files "lib/services/zone_data_processor.dart" "identify zone processing issues"

# Fix and test
cline-cli task --visible-files "lib/services/zone_data_processor.dart" --custom-instructions "include comprehensive error handling" "fix zone processing bugs"

# Verify fix
cline-cli task --auto-approve-mcp "test zone data processing with Firebase"
```

### 3. Feature Development Workflow
```cmd
# Planning phase
cline-cli task --workspace . "plan new alarm system features for next sprint"

# Implementation phase
cline-cli task --custom-instructions "implement with proper testing and documentation" "add silent alarm feature"

# Testing phase
cline-cli task --workspace . "create unit tests for new alarm features"
```

## Tips dan Best Practices

### 1. Efficient Task Specification
```cmd
# ❌ Kurang spesifik
cline-cli task "fix bugs"

# ✅ Lebih spesifik
cline-cli task --visible-files "lib/services/esp32_zone_parser.dart" "fix zone parsing issues where zone status is not correctly decoded from ESP32 data packets"
```

### 2. Use Visible Files untuk Focus
```cmd
# Fokus ke service layer
cline-cli task --visible-files "lib/services/" "review service architecture"

# Fokus ke UI components
cline-cli task --visible-files "lib/widgets/,lib/home.dart,lib/monitoring.dart" "improve UI responsiveness"
```

### 3. Security dengan MCP
```cmd
# Safe: Read operations
cline-cli task --auto-approve-mcp "analyze Firebase data structure"

# Caution: Write operations
cline-cli task --visible-files "lib/services/auth_service.dart" "review authentication security"
```

## Integration dengan Development Workflow

### 1. Sebelum Git Commit
```cmd
cline-cli task --workspace . "review staged changes for code quality and potential issues"
```

### 2. Sebelum Build APK
```cmd
cline-cli task --workspace . "check for any issues that might prevent successful APK build"
```

### 3. Documentation Updates
```cmd
cline-cli task --workspace . "update documentation for recent changes"
```

## Troubleshooting Common Issues

### 1. API Key Error
```
Error: The OPENAI_API_KEY environment variable is missing or empty
```
**Solution**: Set environment variable seperti di atas

### 2. MCP Server Issues
```
Error: MCP server not found
```
**Solution**: Pastikan Firebase server terbuild di path yang benar

### 3. Workspace Issues
```
Error: Workspace not found
```
**Solution**: Gunakan full path atau pastikan di directory yang benar

## Quick Start Commands

### Test Basic Functionality:
```cmd
# Test configuration
cline-cli task --workspace . "test Claude Code CLI configuration"

# Simple analysis
cline-cli task --visible-files "pubspec.yaml" "analyze Flutter dependencies"
```

### Real Project Tasks:
```cmd
# Analyze architecture
cline-cli task --workspace . "analyze Flutter fire alarm system architecture"

# Check Firebase integration
cline-cli task --auto-approve-mcp "verify Firebase integration status"

# Review ESP32 code
cline-cli task --visible-files "EPS TESTING/" "review ESP32 bridge implementation"
```

## Monitoring dan Logging

Claude Code CLI akan:
- Menyimpan task history di `~/.cline_cli/storage/`
- Menyediakan real-time progress updates
- Memberikan detailed output untuk setiap task
- Auto-resume interrupted tasks dengan `--resume`

## Next Steps

1. **Configure API Key** - Langkah pertama yang harus dilakukan
2. **Test Simple Task** - Coba command basic untuk verifikasi
3. **Integrate Daily** - Gunakan untuk daily development tasks
4. **Explore MCP** - Test Firebase integration capabilities

## Support Commands

```cmd
# Help commands
cline-cli --help
cline-cli task --help
cline-cli init --help

# Version check
cline-cli --version
```

---

**Ready to Use!** Claude Code CLI Anda sudah terinstall dan siap digunakan. Langkah berikutnya adalah mengkonfigurasi API key dan mencoba task pertama Anda.
