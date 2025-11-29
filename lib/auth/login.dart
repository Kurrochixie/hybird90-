import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../utils/validation_helpers.dart';
import 'forgot_password.dart';
import '../config.dart';
import '../core/offline_config_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegisterClicked;
  final VoidCallback? onLoginSuccess;
  final bool isOfflineMode;

  const LoginPage({super.key, this.onRegisterClicked, this.onLoginSuccess, this.isOfflineMode = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Firebase Database reference
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  
  // Auth service instance
  final AuthService _authService = AuthService();
  
  // Loading state
  bool _isLoading = false;
  
  // Password visibility toggle
  bool _obscureText = true;
  
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Error state for connectivity
  bool hasError = false;
  String? errorMessage;

  // Connectivity timer and subscription
  Timer? _connectivityTimer;
  StreamSubscription? _connectivitySubscription;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _connectivityTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
    
  // Restart login process
  void _restartLogin() {
    setState(() {
      hasError = false;
      errorMessage = null;
      _isLoading = false;
    });
    _verifyLogin();
  }

  // Verify login credentials with Firebase
  Future<void> _verifyLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      hasError = false;
      errorMessage = null;
    });

    // Check initial connectivity
    var connectivityResults = await Connectivity().checkConnectivity();
    bool hasInternet = !connectivityResults.contains(ConnectivityResult.none);

    if (hasInternet) {
      await _performLogin();
    } else {
      // No internet, set up listener and timer
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
        if (!result.contains(ConnectivityResult.none) && mounted) {
          // Internet available, cancel timer and proceed
          _connectivityTimer?.cancel();
          _performLogin();
        }
      });

      // Start 20 second timer for connection timeout
      _connectivityTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = 'Check your internet connection..';
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Check your internet connection..')),
            );
          }
        }
      });
    }
  }

  Future<void> _performLogin() async {
    // Cancel connectivity listener and timer when proceeding
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();

    try {
      

      // Handle offline mode login
      if (widget.isOfflineMode) {
        await _performOfflineLogin();
        return;
      }
      
      // Sign in with Firebase Auth
      UserCredential userCredential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
      );
      
      

      // Fetch user data from database
      final userSnapshot = await _databaseRef.child('users/${userCredential.user!.uid}').get();

      if (!userSnapshot.exists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User data not found. Please contact support.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      final userData = userSnapshot.value as Map<dynamic, dynamic>;

      // Check if account is active
      if (userData['isActive'] != true) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account is inactive. Please contact support.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        return;
      }

      // Update last login time
      await _databaseRef.child('users/${userCredential.user!.uid}/lastLogin')
          .set(DateTime.now().toIso8601String());

      // Save session login ke local storage
      await _authService.saveLoginSession(
        userId: userCredential.user!.uid,
        email: userCredential.user!.email!,
        username: userData['username'] ?? '',
        phone: userData['phone'] ?? '',
        configDone: true,
        settingsDone: true,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Clear form
        _emailController.clear();
        _passwordController.clear();

        // Navigate to next screen first, then show success message
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
          
          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${userData['username']}!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        } else {
          // Show success message if no navigation callback
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${userData['username']}!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'invalid-email':
          errorMsg = 'Please enter a valid email address.';
          break;
        case 'wrong-password':
          errorMsg = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          errorMsg = 'No account found with this email.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          errorMsg = 'Invalid email or password. Please check your credentials and try again.';
          break;
        default:
          errorMsg = 'Login failed: ${e.message}';
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Navigate to Forgot Password page
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordPage(),
      ),
    );
  }

  // Navigate to Settings/Configuration page
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfigPage(),
      ),
    );
  }

  // Navigate to Offline Configuration page
  void _navigateToOfflineConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OfflineConfigPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Error screen with retry
    if (hasError && errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 60,
          leading: const SizedBox(width: 48), // Space to balance with settings button
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _navigateToSettings,
                icon: Icon(
                  Icons.settings,
                  color: Colors.grey[700],
                  size: 24,
                ),
                tooltip: 'Settings',
              ),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/data/images/LOGO TEXT.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 98, 98, 98),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _restartLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 35, 141, 39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        leading: const SizedBox(width: 48), // Space to balance with settings button
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _navigateToSettings,
              icon: Icon(
                Icons.settings,
                color: Colors.grey[700],
                size: 24,
              ),
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                  MediaQuery.of(context).padding.vertical,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20),
                  Column(
                    children: const [
                      Text(
                        'MONITORING APPS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'MAKE IT SECURE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'LOG IN',
                          style: TextStyle(
                            fontSize: 18,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'E-mail',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: ValidationHelpers.validateEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, 
                              vertical: 8
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureText,
                          validator: (value) => ValidationHelpers.validatePassword(value, isLogin: true),
                        ),
                        const SizedBox(height: 8),
                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _navigateToForgotPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double width = constraints.maxWidth * 0.4;
                            if (width < 120) width = 120;
                            if (width > 250) width = 250;
                            return SizedBox(
                              width: width,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255, 
                                    35, 
                                    141, 
                                    39
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15
                                  ),
                                  elevation: 4,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Login'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                        const SizedBox(height: 16),
                        // Full Offline Mode Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _navigateToOfflineConfig,
                            icon: const Icon(
                              Icons.wifi_off,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Full Offline Mode',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Divider with text
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : widget.onRegisterClicked,
                    child: const Text(
                      'Don\'t have an account? Register',
                      style: TextStyle(color: Color.fromARGB(255, 31, 116, 34)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Image.asset(
                      'assets/data/images/LOGO TEXT.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Handle offline mode login simulation
  Future<void> _performOfflineLogin() async {
    

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // For offline mode, we'll simulate a successful login
      // In real implementation, you might check local cache or offline credentials
      if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline login successful. Limited functionality available.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Simulate successful login in offline mode
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // Call onLoginSuccess to navigate to next screen
          widget.onLoginSuccess?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter email and password.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
