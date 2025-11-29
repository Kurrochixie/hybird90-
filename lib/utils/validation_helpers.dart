import 'package:flutter/material.dart';

/// Helper class for form validation across the application
class ValidationHelpers {
  // Email validation regex - more strict than basic
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );

  // Indonesian phone number validation regex
  static final RegExp _phoneRegex = RegExp(
    r'^(\+62|62|0)[0-9]{9,12}$'
  );

  // Username validation - alphanumeric with underscores, starting with letter
  static final RegExp _usernameRegex = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*$'
  );

  // Password strength validation
  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasNumbers = RegExp(r'[0-9]');
  static final RegExp _hasSpecialCharacters = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // Project name validation
  static final RegExp _projectNameRegex = RegExp(
    r'^[a-zA-Z0-9\s\-_]+$'
  );

  // Zone name validation
  static final RegExp _zoneNameRegex = RegExp(
    r'^[a-zA-Z0-9\s\-_()]+$'
  );

  /// Enhanced email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim().toLowerCase();

    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Additional validation checks
    if (email.length > 254) {
      return 'Email address is too long';
    }

    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Email address cannot start or end with a dot';
    }

    if (email.contains('..')) {
      return 'Email address cannot contain consecutive dots';
    }

    return null;
  }

  /// Enhanced password validation with strength requirements
  static String? validatePassword(String? value, {bool isLogin = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }

    final password = value.trim();

    // Basic length check
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // For registration, enforce stronger requirements
    if (!isLogin) {
      if (!_hasUppercase.hasMatch(password)) {
        return 'Password must contain at least one uppercase letter (A-Z)';
      }

      if (!_hasLowercase.hasMatch(password)) {
        return 'Password must contain at least one lowercase letter (a-z)';
      }

      if (!_hasNumbers.hasMatch(password)) {
        return 'Password must contain at least one number (0-9)';
      }

      if (!_hasSpecialCharacters.hasMatch(password)) {
        return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
      }

      // Additional security checks
      if (password.contains('password') ||
          password.contains('123456') ||
          password.contains('qwerty')) {
        return 'Password is too common. Please choose a more secure password';
      }

      if (password.length > 128) {
        return 'Password is too long (maximum 128 characters)';
      }
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Enhanced username validation
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    final username = value.trim();

    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (username.length > 20) {
      return 'Username must be less than 20 characters';
    }

    if (!_usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores, and must start with a letter';
    }

    // Prevent common usernames
    final commonUsernames = ['admin', 'user', 'test', 'guest', 'root', 'system'];
    if (commonUsernames.contains(username.toLowerCase())) {
      return 'This username is not available. Please choose another';
    }

    return null;
  }

  /// Enhanced phone number validation (Indonesian format)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and other formatting characters
    String cleanPhone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!_phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid Indonesian phone number (e.g., +628123456789, 08123456789)';
    }

    // Additional validation
    if (cleanPhone.startsWith('0') && cleanPhone.length < 10) {
      return 'Phone number is too short';
    }

    if (cleanPhone.startsWith('0') && cleanPhone.length > 13) {
      return 'Phone number is too long';
    }

    if ((cleanPhone.startsWith('+62') || cleanPhone.startsWith('62')) && cleanPhone.length < 11) {
      return 'Phone number is too short';
    }

    if ((cleanPhone.startsWith('+62') || cleanPhone.startsWith('62')) && cleanPhone.length > 14) {
      return 'Phone number is too long';
    }

    return null;
  }

  /// Project name validation
  static String? validateProjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name is required';
    }

    final projectName = value.trim();

    if (projectName.length < 3) {
      return 'Project name must be at least 3 characters long';
    }

    if (projectName.length > 50) {
      return 'Project name must be less than 50 characters';
    }

    if (!_projectNameRegex.hasMatch(projectName)) {
      return 'Project name can only contain letters, numbers, spaces, hyphens, and underscores';
    }

    return null;
  }

  /// Zone name validation
  static String? validateZoneName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Zone names can be empty (will get defaults)
    }

    final zoneName = value.trim();

    if (zoneName.length > 50) {
      return 'Zone name must be less than 50 characters';
    }

    if (!_zoneNameRegex.hasMatch(zoneName)) {
      return 'Zone name can only contain letters, numbers, spaces, hyphens, underscores, and parentheses';
    }

    return null;
  }

  /// System data validation
  static String? validateSystemData(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter some data';
    }

    final data = value.trim();

    if (data.length > 500) {
      return 'Data must be less than 500 characters';
    }

    // Basic JSON validation (assuming JSON format)
    if (data.startsWith('{') && data.endsWith('}')) {
      try {
        // This is a basic check - in production, you'd want more robust validation
        if (!data.contains('"') || !data.contains(':')) {
          return 'Invalid JSON format';
        }
      } catch (e) {
        return 'Invalid data format';
      }
    }

    return null;
  }

  /// Firebase API Key validation
  static String? validateAPIKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'API Key is required';
    }

    final apiKey = value.trim();

    if (!apiKey.startsWith('AIza')) {
      return 'Invalid Firebase API Key format - must start with "AIza"';
    }

    if (apiKey.length != 39) {
      return 'Invalid Firebase API Key length - must be 39 characters';
    }

    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(apiKey)) {
      return 'API Key contains invalid characters';
    }

    return null;
  }

  /// Database URL validation
  static String? validateDatabaseURL(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Database URL is required';
    }

    final url = value.trim();

    if (!url.startsWith('https://') || !url.endsWith('.firebaseio.com') && !url.endsWith('.firebaseio.com/')) {
      return 'Invalid Firebase Database URL format';
    }

    return null;
  }

  /// FCM Server Key validation
  static String? validateFCMServerKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'FCM Server Key is required';
    }

    final serverKey = value.trim();

    // FCM server keys are typically 168 characters long
    if (serverKey.length < 100 || serverKey.length > 200) {
      return 'Invalid FCM Server Key length';
    }

    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(serverKey)) {
      return 'FCM Server Key contains invalid characters';
    }

    return null;
  }

  /// Password strength indicator helper
  static PasswordStrength getPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (_hasUppercase.hasMatch(password)) score++;
    if (_hasLowercase.hasMatch(password)) score++;
    if (_hasNumbers.hasMatch(password)) score++;
    if (_hasSpecialCharacters.hasMatch(password)) score++;

    switch (score) {
      case 0:
      case 1:
        return PasswordStrength.veryWeak;
      case 2:
        return PasswordStrength.weak;
      case 3:
        return PasswordStrength.fair;
      case 4:
        return PasswordStrength.good;
      case 5:
        return PasswordStrength.strong;
      case 6:
        return PasswordStrength.veryStrong;
      default:
        return PasswordStrength.veryWeak;
    }
  }

  /// Get password strength color
  static Color getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
      case PasswordStrength.veryWeak:
        return Colors.red;
      case PasswordStrength.weak:
        return Colors.orange;
      case PasswordStrength.fair:
        return Colors.yellow[700]!;
      case PasswordStrength.good:
        return Colors.lightGreen;
      case PasswordStrength.strong:
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  /// Get password strength text
  static String getPasswordStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.veryWeak:
        return 'Very Weak';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }
}

/// Password strength enum
enum PasswordStrength {
  empty,
  veryWeak,
  weak,
  fair,
  good,
  strong,
  veryStrong,
}

/// Password strength indicator widget
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showText;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = ValidationHelpers.getPasswordStrength(password);
    final color = ValidationHelpers.getPasswordStrengthColor(strength);
    final text = ValidationHelpers.getPasswordStrengthText(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength.index / PasswordStrength.values.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (password.isNotEmpty)
          Text(
            'Use 8+ characters with uppercase, lowercase, numbers, and symbols',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  /// IP Address validation
  static String? validateIpAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IP address is required';
    }

    final ip = value.trim();

    // IPv4 address regex validation
    final ipv4Regex = RegExp(
      r'^^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );

    if (!ipv4Regex.hasMatch(ip)) {
      return 'Please enter a valid IPv4 address (e.g., 192.168.1.100)';
    }

    return null;
  }

  /// Port validation
  static String? validatePort(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Port is required';
    }

    final port = value.trim();
    final portNumber = int.tryParse(port);

    if (portNumber == null) {
      return 'Port must be a valid number';
    }

    if (portNumber < 1 || portNumber > 65535) {
      return 'Port must be between 1 and 65535';
    }

    return null;
  }

  /// Module count validation
  static String? validateModuleCount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Number of modules is required';
    }

    final moduleCount = value.trim();
    final count = int.tryParse(moduleCount);

    if (count == null) {
      return 'Module count must be a valid number';
    }

    if (count < 1) {
      return 'Module count must be at least 1';
    }

    if (count > 255) {
      return 'Module count cannot exceed 255';
    }

    return null;
  }
}