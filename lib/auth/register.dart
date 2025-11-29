import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../utils/validation_helpers.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onLoginClicked;
  final VoidCallback? onRegisterSuccess;

  const RegisterPage({super.key, this.onLoginClicked, this.onRegisterSuccess});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Firebase Database reference
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  
  // Auth service instance
  final AuthService _authService = AuthService();
  
  // Loading state
  bool _isLoading = false;
  
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _connectivityTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  
  // Restart register process
  void _restartRegister() {
    setState(() {
      hasError = false;
      errorMessage = null;
      _isLoading = false;
    });
    _saveUserToFirebase();
  }
  

  
  // Check if phone number already exists in Firebase
  Future<bool> _isPhoneExists(String phone) async {
    try {
      final snapshot = await _databaseRef.child('users').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        for (var userData in users.values) {
          if (userData['phone'] == phone.trim()) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if username already exists in Firebase
  Future<bool> _isUsernameExists(String username) async {
    try {
      final snapshot = await _databaseRef.child('users').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        String normalizedUsername = username.trim().toUpperCase();
        for (var userData in users.values) {
          if (userData['username'] == normalizedUsername) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Save user data to Firebase
  Future<void> _saveUserToFirebase() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passwords do not match!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
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
      await _performSave();
    } else {
      // No internet, set up listener and timer
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
        if (!result.contains(ConnectivityResult.none) && mounted) {
          // Internet available, cancel timer and proceed
          _connectivityTimer?.cancel();
          _performSave();
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Check your internet connection..')),
              );
            }
          });
        }
      });
    }
  }

  Future<void> _performSave() async {
    // Cancel connectivity listener and timer when proceeding
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();

    try {
      // Check if username already exists
      bool usernameExists = await _isUsernameExists(_usernameController.text);
      if (usernameExists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Username already exists! Please choose another.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          });
        }
        return;
      }

      // Check if phone number already exists
      bool phoneExists = await _isPhoneExists(_phoneController.text);
      if (phoneExists) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number already registered! Please use another number.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          });
        }
        return;
      }

      // Create user in Firebase Auth
      UserCredential userCredential = await _authService.createUserWithEmailAndPassword(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
      );

      // Create user data object (without password)
      Map<String, dynamic> userData = {
        'username': _usernameController.text.trim().toUpperCase(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        'registeredAt': DateTime.now().toIso8601String(),
        'lastLogin': null,
        'isActive': true,
      };

      // Save to Firebase Database under 'users' node with uid as key
      await _databaseRef.child('users/${userCredential.user!.uid}').set(userData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });

        // Clear form
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _phoneController.clear();

        // Show additional message to guide user
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login with your registered credentials'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        });

        // Navigate back to login screen
        if (widget.onRegisterSuccess != null) {
          widget.onRegisterSuccess!();
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'This email is already registered. Please use a different email or login instead.';
          break;
        case 'weak-password':
          errorMsg = 'Password is too weak. Please use a stronger password (at least 6 characters).';
          break;
        case 'invalid-email':
          errorMsg = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          errorMsg = 'Email/password accounts are not enabled. Please contact support.';
          break;
        default:
          errorMsg = 'Registration failed: ${e.message}';
      }
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = errorMsg;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'Registration failed: ${e.toString()}';
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('An unexpected error occurred. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error screen with retry
    if (hasError && errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
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
                onPressed: _restartRegister,
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

    return PopScope(
      canPop: widget.onLoginClicked == null,
      onPopInvokedWithResult: (didPop, result) {
        // When physical back button is pressed on register page, navigate back to login
        if (!didPop && widget.onLoginClicked != null) {
          widget.onLoginClicked!();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
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
                            'REGISTER',
                            style: TextStyle(
                              fontSize: 18,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            validator: ValidationHelpers.validateUsername,
                          ),
                          const SizedBox(height: 12),
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
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: ValidationHelpers.validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: ValidationHelpers.validatePhone,
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
                                vertical: 8,
                              ),
                            ),
                            obscureText: true,
                            validator: ValidationHelpers.validatePassword,
                          ),
                          // Password strength indicator
                          ValueListenableBuilder(
                            valueListenable: _passwordController,
                            builder: (context, value, child) {
                              return PasswordStrengthIndicator(password: value.text);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            obscureText: true,
                            validator: (value) => ValidationHelpers.validateConfirmPassword(value, _passwordController.text),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double width = constraints.maxWidth * 0.4;
                              if (width < 120) width = 120;
                              if (width > 250) width = 250;
                              return SizedBox(
                                width: width,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveUserToFirebase,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      35,
                                      141,
                                      39,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
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
                                      : const Text('Register'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onLoginClicked,
                      child: const Text(
                        'Already have an account? Login',
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
      ),
    );
  }
}
