import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../home/interface_settings.dart';
import '../services/auth_service.dart';
import 'auth/login.dart';

class ConfigPage extends StatefulWidget {
  final VoidCallback? onConfigDone;
  final VoidCallback? onBackPressed;

  const ConfigPage({super.key, this.onConfigDone, this.onBackPressed});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  late final TextEditingController apiKeyController;
  late final TextEditingController appIdController;
  late final TextEditingController messagingSenderIdController;
  late final TextEditingController projectIdController;
  late final TextEditingController databaseURLController;
  late final TextEditingController serverKeyController;

  final AuthService _authService = AuthService();
  bool _isSaving = false;
  bool _noInternet = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with environment variables
    try {
      // Check if dotenv is initialized
      if (!dotenv.isInitialized) {
        dotenv.load(fileName: ".env");
      }
    } catch (e) {
      // Ignore dotenv initialization errors - use fallback values
    }

    // Initialize controllers with safe access
    apiKeyController = TextEditingController(text: dotenv.env['FIREBASE_API_KEY'] ?? '');
    appIdController = TextEditingController(text: dotenv.env['FIREBASE_APP_ID'] ?? '');
    messagingSenderIdController = TextEditingController(text: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '');
    projectIdController = TextEditingController(text: dotenv.env['FIREBASE_PROJECT_ID'] ?? '');
    databaseURLController = TextEditingController(text: dotenv.env['FIREBASE_DATABASE_URL'] ?? '');
    serverKeyController = TextEditingController(text: dotenv.env['FCM_SERVER_KEY'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        title: const Text(
          'CONFIGURATION',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLabeledTextField('API Key', apiKeyController),
                    const SizedBox(height: 20),
                    _buildLabeledTextField('App ID', appIdController),
                    const SizedBox(height: 20),
                    _buildLabeledTextField('Messaging Sender ID', messagingSenderIdController),
                    const SizedBox(height: 20),
                    _buildLabeledTextField('Project ID', projectIdController),
                    const SizedBox(height: 20),
                    _buildLabeledTextField('Database URL', databaseURLController),
                    const SizedBox(height: 20),
                    _buildLabeledTextField('FCM Server Key', serverKeyController),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _noInternet ? Colors.grey : const Color.fromARGB(255, 26, 117, 29),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_noInternet ? 'Retry' : 'SAVE'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InterfaceSettingsPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 226, 226, 226),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('PANEL SETTINGS'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfig() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    bool hasInternet = !connectivityResults.contains(ConnectivityResult.none);

    if (!hasInternet) {
      setState(() {
        _noInternet = true;
        _isSaving = false;
      });
      return;
    }

    setState(() {
      _noInternet = false;
      _isSaving = true;
    });

    try {
      await _authService.updateConfigStatus(
        configDone: true,
        settingsDone: true,
      );

      if (widget.onConfigDone != null) {
        widget.onConfigDone!();
      }

      if (!mounted) return;

      // SECURITY FIX: Navigate back to login page, not bypass authentication
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving config: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildLabeledTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}