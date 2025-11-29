import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/websocket_mode_manager.dart';
import '../services/logger.dart';
import '../constants/app_constants.dart';

/// ESP32 IP Configuration Dialog untuk setting dan validasi ESP32 IP address
/// Accessible via tap on ESP32 IP display or settings menu
class ESP32IPDialog extends StatefulWidget {
  final WebSocketModeManager manager;
  final String? title;
  final bool showConnectionStatus;

  const ESP32IPDialog({
    super.key,
    required this.manager,
    this.title,
    this.showConnectionStatus = true,
  });

  @override
  State<ESP32IPDialog> createState() => _ESP32IPDialogState();
}

class _ESP32IPDialogState extends State<ESP32IPDialog> {
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late FocusNode _ipFocusNode;
  late FocusNode _portFocusNode;

  bool _isValidating = false;
  bool _isConnecting = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.manager.esp32IP);
    _portController = TextEditingController(text: WebSocketConstants.defaultPort.toString());
    _ipFocusNode = FocusNode();
    _portFocusNode = FocusNode();

    _validateIP(widget.manager.esp32IP);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _ipFocusNode.dispose();
    _portFocusNode.dispose();
    super.dispose();
  }

  
  void _validateIP(String ip) {
    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    if (ip.isEmpty) {
      setState(() {
        _validationError = 'IP address is required';
        _isValidating = false;
      });
      return;
    }

    // Basic IP format validation
    final parts = ip.split('.');
    if (parts.length != 4) {
      setState(() {
        _validationError = 'IP must have exactly 4 parts (e.g., 192.168.0.2)';
        _isValidating = false;
      });
      return;
    }

    // Validate each octet
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (part.isEmpty) {
        setState(() {
          _validationError = 'IP part ${i + 1} cannot be empty';
          _isValidating = false;
        });
        return;
      }

      // Allow leading zeros for flexibility (e.g., "001", "09" should be parsed as 1 and 9)
      // This allows users to edit more freely

      try {
        final value = int.parse(part);
        if (value < 0 || value > 255) {
          setState(() {
            _validationError = 'IP part ${i + 1} must be between 0 and 255';
            _isValidating = false;
          });
          return;
        }
      } catch (e) {
        setState(() {
          _validationError = 'IP part ${i + 1} must be a valid number';
          _isValidating = false;
        });
        return;
      }
    }

    // Check for special addresses
    if (ip == '0.0.0.0') {
      setState(() {
        _validationError = '0.0.0.0 is reserved, use another IP';
        _isValidating = false;
      });
      return;
    }

    if (ip == '255.255.255.255') {
      setState(() {
        _validationError = '255.255.255.255 is broadcast address, use another IP';
        _isValidating = false;
      });
      return;
    }

    // Check if it's a private IP (show warning but allow)
    if (_isPrivateIP(ip)) {
      // Private IP is valid for ESP32, but we can add warning if needed
      setState(() {
        _isValidating = false;
        _validationError = null; // Clear error for valid private IPs
      });
      return;
    }

    setState(() {
      _isValidating = false;
      _validationError = null; // Clear error for valid IPs
    });
  }

  /// Check if IP is in private ranges
  bool _isPrivateIP(String ip) {
    final parts = ip.split('.').map((e) => int.parse(e)).toList();

    // 10.0.0.0 - 10.255.255.255
    if (parts[0] == 10) return true;

    // 172.16.0.0 - 172.31.255.255
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;

    // 192.168.0.0 - 192.168.255.255
    if (parts[0] == 192 && parts[1] == 168) return true;

    return false;
  }

  
  Future<void> _saveAndConnect() async {
    final ip = _ipController.text.trim();

    if (_validationError != null || ip.isEmpty) {
      _showErrorSnackBar('Please fix IP address errors first');
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      AppLogger.info('Saving ESP32 IP: $ip', tag: 'ESP32_IP_DIALOG');

      // Update IP in manager
      final success = await widget.manager.updateESP32IP(ip);

      if (success) {
        _showSuccessSnackBar('ESP32 IP updated successfully!');
        if (mounted) {
          Navigator.of(context).pop(true); // Return success
        }
      } else {
        _showErrorSnackBar('Failed to update ESP32 IP');
      }

    } catch (e, stackTrace) {
      AppLogger.error('Error saving ESP32 IP', tag: 'ESP32_IP_DIALOG', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Icon(
                    Icons.settings_ethernet,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'ESP32 Configuration',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure ESP32 WebSocket connection',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Connection status (if enabled)
            if (widget.showConnectionStatus) ...[
              _buildConnectionStatus(),
              const SizedBox(height: 20),
            ],

            // IP Address Input
            _buildIPInputSection(),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return AnimatedBuilder(
      animation: widget.manager,
      builder: (context, child) {
        final isConnected = widget.manager.isConnected;
        final isConnecting = widget.manager.isConnecting;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected
                ? Colors.green.shade50
                : (isConnecting ? Colors.orange.shade50 : Colors.red.shade50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConnected
                  ? Colors.green.shade200
                  : (isConnecting ? Colors.orange.shade200 : Colors.red.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConnected
                    ? Icons.wifi
                    : (isConnecting ? Icons.wifi_off : Icons.wifi_off),
                color: isConnected
                    ? Colors.green.shade700
                    : (isConnecting ? Colors.orange.shade700 : Colors.red.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isConnected
                            ? Colors.green.shade700
                            : (isConnecting ? Colors.orange.shade700 : Colors.red.shade700),
                      ),
                    ),
                    Text(
                      widget.manager.getStatusText(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIPInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ESP32 IP Address',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ipController,
          focusNode: _ipFocusNode,
          keyboardType: TextInputType.text, // Changed to text to allow dots
          inputFormatters: [
            // Custom IP address formatter untuk validasi real-time
            _IPAddressInputFormatter(),
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          maxLength: 15,
          onChanged: (value) {
            // Debounced validation untuk mengurangi aggressive validation
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_ipController.text == value) {
                _validateIP(value);
              }
            });
          },
          decoration: InputDecoration(
            hintText: '192.168.1.100',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400),
            ),
            prefixIcon: const Icon(Icons.wifi_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isValidating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_ipController.text.isNotEmpty && !_isValidating)
                  IconButton(
                    onPressed: () {
                      _ipController.clear();
                      _validateIP('');
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    tooltip: 'Clear IP address',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
            errorText: _validationError,
            helperText: 'WebSocket will connect to: ws://[IP]:80',
          ),
        ),
      ],
    );
  }

  
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: OutlinedButton(
            onPressed: _isConnecting ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Save Button
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: (_validationError != null || _isConnecting) ? null : _saveAndConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isConnecting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Connecting...'),
                    ],
                  )
                : const Text(
                    'Save & Connect',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Custom IP Address Input Formatter untuk validasi format real-time
class _IPAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Hanya izinkan karakter 0-9 dan .
    if (!RegExp(r'^[0-9.]*$').hasMatch(text)) {
      return oldValue;
    }

    // Prevent multiple consecutive dots
    if (text.contains('..')) {
      return oldValue;
    }

    // Prevent dots at the beginning or end (except when user is actively editing)
    if (text.startsWith('.')) {
      if (text.length > 1 && text[1] != '.') {
        return TextEditingValue(
          text: text.substring(1),
          selection: TextSelection.collapsed(offset: text.length - 1),
        );
      }
      return oldValue;
    }

    if (text.endsWith('.') && text.length > 1) {
      // Allow trailing dot during editing (user might be typing next octet)
      // But don't allow if it's just a single dot
      return text == '.' ? oldValue : newValue;
    }

    // Validasi setiap octet untuk range 0-255
    final parts = text.split('.');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;

      // REMOVED: Leading zero restriction during editing
      // User should be able to edit freely, validation will happen on save

      // Convert to integer untuk check range
      try {
        final value = int.parse(parts[i]);
        if (value > 255) {
          return oldValue;
        }
      } catch (e) {
        // If parsing fails, it might be because user is still typing
        // Allow intermediate values like "0", "00", "01" during editing
        if (parts[i].length > 3) {
          return oldValue; // But limit length to prevent unreasonable inputs
        }
      }
    }

    // Prevent lebih dari 4 octets
    if (parts.length > 4) {
      return oldValue;
    }

    return newValue;
  }
}

/// Quick IP selector for inline editing
class QuickIPSelector extends StatelessWidget {
  final WebSocketModeManager manager;
  final String? currentIP;
  final Function(String)? onIPSelected;

  const QuickIPSelector({
    super.key,
    required this.manager,
    this.currentIP,
    this.onIPSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showIPDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_outlined,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              currentIP ?? manager.esp32IP,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showIPDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ESP32IPDialog(manager: manager),
    );

    if (result == true && onIPSelected != null) {
      onIPSelected!(manager.esp32IP);
    }
  }
}