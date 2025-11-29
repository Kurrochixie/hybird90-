# Cline CLI Setup Guide for Flutter Fire Alarm System

## Overview
Cline CLI is now successfully installed and configured for your Flutter fire alarm system project. This guide will help you use the command-line interface for AI-assisted development.

## Installation Status ✅
- **Cline CLI**: Successfully installed globally
- **Configuration**: Initialized with default settings
- **MCP Integration**: Firebase server configured and ready
- **Workspace**: Flutter project detected and ready
- **⚠️ API Configuration**: Required for CLI functionality

## API Configuration Required

The Cline CLI requires an API key to function. You need to configure one of the following AI providers:

### Option 1: Anthropic Claude (Recommended)
```bash
# Set environment variable
set OPENAI_API_KEY=your-anthropic-api-key

# Or add to your system environment variables
```

### Option 2: OpenAI
```bash
# Set environment variable
set OPENAI_API_KEY=your-openai-api-key
```

### Option 3: Configure in Settings File
Edit `c:\Users\melin\.cline_cli\cline_cli_settings.json`:
```json
{
  "globalState": {
    "apiProvider": "anthropic",
    "apiModelId": "claude-3-5-sonnet-20241022",
    "anthropicBaseUrl": "https://api.anthropic.com"
  }
}
```

### Getting API Keys
- **Anthropic**: https://console.anthropic.com/
- **OpenAI**: https://platform.openai.com/api-keys

## Configuration Files Created
- **Settings**: `c:\Users\melin\.cline_cli\cline_cli_settings.json`
- **MCP Settings**: `c:\Users\melin\.cline_cli\storage\settings\cline_mcp_settings.json`
- **Storage**: `c:\Users\melin\.cline_cli\storage\`

## Available Commands

### 1. Initialize Cline CLI
```bash
cline-cli init
```
*Already completed - sets up configuration files*

### 2. Execute Tasks
```bash
# Basic task execution
cline-cli task "your task description"

# With workspace specification
cline-cli task --workspace "d:\01_DATA CODING DDS MOBILE\RAR\test\flutter_application_1" "analyze code"

# With custom instructions
cline-cli task --custom-instructions "focus on performance" "optimize app"

# With auto-approval for safer operations
cline-cli task --auto-approve-mcp "test firebase connection"

# Resume previous task
cline-cli task --resume
```

### 3. Advanced Options
```bash
# Specify visible files for AI context
cline-cli task --visible-files "lib/main.dart,lib/services/" "review main service"

# Full auto mode (use with caution)
cline-cli task --full-auto "implement new feature"

# Resume or create new task
cline-cli task --resume-or-new "continue previous work"
```

## Project-Specific Usage

### For Flutter Development
```bash
# Analyze Flutter code
cline-cli task --workspace . "analyze Flutter architecture and suggest improvements"

# Debug issues
cline-cli task --visible-files "lib/services/" "debug zone parser issues"

# Add new features
cline-cli task --custom-instructions "follow Flutter best practices" "add new alarm type"
```

### For Firebase Integration
```bash
# Test Firebase connection
cline-cli task --auto-approve-mcp "test Firebase real-time database connection"

# Analyze Firebase data structure
cline-cli task --auto-approve-mcp "analyze Firebase data schema for fire alarm system"
```

### For ESP32 Integration
```bash
# Review ESP32 communication
cline-cli task --visible-files "EPS TESTING/" "analyze ESP32 bridge code"

# Debug communication issues
cline-cli task "debug ESP32 data parsing issues"
```

## MCP Integration Status

### Firebase Server ✅ Configured
- **Database URL**: `https://testing1do-default-rtdb.asia-southeast1.firebasedatabase.app`
- **Project ID**: `testing1do`
- **Auto-approved tools**: `search_firebase_field`, `get_document`
- **Server path**: `C:\Users\melin\Documents\Cline\MCP\firebase-server\build\index.js`

## Recommended Workflows

### 1. Code Analysis Workflow
```bash
# Analyze entire project
cline-cli task --workspace . "perform comprehensive code analysis of Flutter fire alarm system"

# Focus on specific modules
cline-cli task --visible-files "lib/services/" "analyze service layer architecture"
```

### 2. Bug Fixing Workflow
```bash
# Debug specific issues
cline-cli task --visible-files "lib/services/esp32_zone_parser.dart" "fix zone parsing bugs"

# Test fixes
cline-cli task --custom-instructions "test the fixes thoroughly" "verify zone parser works correctly"
```

### 3. Feature Development Workflow
```bash
# Plan new features
cline-cli task "plan new notification system features"

# Implement features
cline-cli task --custom-instructions "implement with proper error handling" "add push notification support"
```

### 4. Documentation Workflow
```bash
# Generate documentation
cline-cli task --workspace . "generate comprehensive documentation for the fire alarm system"

# Update guides
cline-cli task --visible-files "EPS TESTING/GUIDE FILE/" "update installation guides"
```

## Best Practices

### 1. Task Specification
- Be specific in your task descriptions
- Use `--visible-files` to focus on relevant code
- Provide context with `--custom-instructions`

### 2. Safety Measures
- Use `--auto-approve-mcp` only for trusted operations
- Review AI suggestions before applying
- Test changes in a controlled environment

### 3. Project Context
- Always specify workspace for project-specific tasks
- Include relevant files in `--visible-files`
- Provide project-specific context in custom instructions

## Example Tasks for Your Project

### Performance Optimization
```bash
cline-cli task --visible-files "lib/services/" "analyze and optimize notification service performance"
```

### Code Quality
```bash
cline-cli task --workspace . "review code quality and suggest improvements for Flutter best practices"
```

### Security Analysis
```bash
cline-cli task --visible-files "lib/services/auth_service.dart" "analyze authentication security and suggest improvements"
```

### Testing Enhancement
```bash
cline-cli task --workspace . "improve test coverage for critical alarm system components"
```

## Troubleshooting

### Common Issues
1. **API Key Missing Error**: 
   ```
   [Error]: The OPENAI_API_KEY environment variable is missing or empty
   ```
   **Solution**: Set the OPENAI_API_KEY environment variable with your API key

2. **MCP Server Not Found**: Ensure Firebase server is built at the specified path

3. **Permission Issues**: Run command prompt as administrator if needed

4. **Workspace Issues**: Use full path to Flutter project directory

### API Configuration Quick Fix
```bash
# For current session only
set OPENAI_API_KEY=your-api-key-here

# Verify it's set
echo %OPENAI_API_KEY%

# Then test Cline CLI
cline-cli task --workspace . "test configuration"
```

### Getting Help
```bash
cline-cli --help
cline-cli task --help
cline-cli init --help
```

## Next Steps

1. **Test Basic Functionality**: Try a simple analysis task
2. **Explore MCP Integration**: Test Firebase connectivity
3. **Customize Settings**: Modify auto-approval settings as needed
4. **Integrate into Workflow**: Use for regular development tasks

## Integration with Existing Tools

Cline CLI complements your existing development environment:
- **VS Code**: Continue using VS Code extension for interactive development
- **Cline CLI**: Use for automated tasks and batch processing
- **Firebase MCP**: Seamlessly integrated for database operations
- **Flutter CLI**: Continue using for building and testing

This setup provides you with both interactive (VS Code) and command-line (CLI) AI assistance options for maximum flexibility in your Flutter fire alarm system development.
