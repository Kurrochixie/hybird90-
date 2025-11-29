import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../di/service_locator.dart';
import 'home/home.dart';
import 'monitoring/monitoring.dart';
import 'monitoring/control.dart';
import 'history/history.dart';
import 'core/fire_alarm_data.dart';
import '../config.dart';
import 'auth/auth_navigation.dart';
import 'monitoring/full_monitoring_page.dart';
import 'monitoring/zone_monitoring.dart';
import 'monitoring/tab_monitoring.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/background_notification_service.dart' as bg_notification;
import '../services/local_audio_manager.dart';
import 'auth/profile_page.dart';
import 'home/zone_name_settings.dart';
import 'monitoring/websocket_debug_page.dart';
import '../services/bell_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv first
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Ignore dotenv loading errors - will use environment defaults
  }

  // Initialize Firebase with custom configuration
  try {
    // Try to initialize with a custom name to avoid conflicts
    await Firebase.initializeApp(
      name: 'fireAlarmApp',
      options: FirebaseOptions(
        // SECURITY FIX: Use environment variables instead of hardcoded credentials
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
        databaseURL: dotenv.env['FIREBASE_DATABASE_URL'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
      ),
    );
    
    
  } catch (e) {
    // Try to use the default app if it exists
    try {
      final app = Firebase.app();

      final dbURL = app.options.databaseURL;
      print('Using existing Firebase app with database URL: ${dbURL ?? 'undefined'}');
    } catch (e2) {
      // Firebase initialization failed - app will work with local storage only
      print('Warning: Firebase initialization failed: $e2');
      print('App will continue with offline functionality');
    }
  }

  // 🔒 NEW: Configure Firebase Auth Persistence for Persistent Login
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print('Firebase Auth persistence set to LOCAL');
  } catch (e) {
    // Auth persistence setting failed - will use default persistence
    print('Warning: Could not set Firebase Auth persistence: $e');
    print('Auth will use default persistence mode');
  }

  // Initialize FCM with error handling
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    

    // Get FCM token
    String? token = await messaging.getToken();
    // SECURITY FIX: Mask FCM token in logs to prevent exposure
    if (token != null && token.length > 10) {
      String maskedToken = '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
      
    } else {
      
    }

    // Subscribe to topics for notifications
    await messaging.subscribeToTopic('status_updates');
    
    
    // Subscribe to fire alarm events topic
    await FCMService.subscribeToFireAlarmEvents(token);
  } catch (e) {
    // FCM initialization failed - notifications will not be available
    print('Warning: FCM initialization failed: $e');
    print('Push notifications will not be available');
  }

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(bg_notification.BackgroundNotificationService.firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    
    

    // Show notification with sound even when app is in foreground
    final data = message.data;
    final eventType = data['eventType'] ?? 'UNKNOWN';
    final status = data['status'] ?? '';
    final user = data['user'] ?? 'System';
    
    bg_notification.BackgroundNotificationService().showFireAlarmNotification(
      title: 'Fire Alarm: $eventType',
      body: 'Status: $status - By: $user',
      eventType: eventType,
      data: data,
    );

    if (message.notification != null) {
      
    }
  });

  // Initialize background notification service for persistent operation
  await bg_notification.BackgroundNotificationService().initialize();

  // Initialize LocalAudioManager for background audio
  final audioManager = LocalAudioManager();
  await audioManager.initialize();

  // Initialize dependency injection
  try {
    await initializeServicesWithHealthCheck();
    print('Services initialized successfully');
  } catch (e) {
    // Service initialization failed - some features may not work
    print('Warning: Service initialization failed: $e');
    print('Some features may not be available');
  }

  

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => getIt<FireAlarmData>()),
        ChangeNotifierProvider(create: (context) => getIt<BellManager>()),
      ],
      child: MaterialApp(
        title: 'Fire Alarm Monitoring',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: const AuthNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  String _username = '';
  String _phone = '';
  String? _photoUrl;
  bool _hasShownDisconnectedMessage = false;

  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();

    // SECURITY FIX: Add authentication guard
    _validateAuthentication();
    _loadUserData();
    
    // Initialize pages with scaffold key
    _pages = [
      HomePage(scaffoldKey: _scaffoldKey),
      MonitoringPage(scaffoldKey: _scaffoldKey),
      ControlPage(scaffoldKey: _scaffoldKey),
      HistoryPage(scaffoldKey: _scaffoldKey),
      const ConfigPage(),
    ];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = Provider.of<FireAlarmData>(context, listen: false);
      if (data.isFirebaseConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to Firebase server')),
        );
      }
    });

    // Listen for connectivity changes to show disconnection message
    final data = Provider.of<FireAlarmData>(context, listen: false);
    data.addListener(() {
      if (!data.isFirebaseConnected && !_hasShownDisconnectedMessage) {
        _hasShownDisconnectedMessage = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check your internet connection..')),
          );
        }
      } else if (data.isFirebaseConnected) {
        _hasShownDisconnectedMessage = false;
      }
    });
  }

  Future<void> _loadUserData() async {
    final username = await _authService.getCurrentUsername();
    final phone = await _authService.getCurrentPhone();
    final photoUrl = await _authService.getCurrentUserPhotoUrl();
    if (mounted) {
      setState(() {
        _username = username ?? 'User';
        _phone = phone ?? '';
        _photoUrl = photoUrl;
      });
    }
  }

  // SECURITY FIX: Authentication validation guard
  Future<void> _validateAuthentication() async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthNavigation()),
            (route) => false,
          );
        }
        return;
      }

      // Additional security check - verify user still exists and is active
      final userSnapshot = await FirebaseDatabase.instance.ref().child('users/${user.uid}').get();
      if (!userSnapshot.exists || userSnapshot.child('isActive').value != true) {
        
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthNavigation()),
            (route) => false,
          );
        }
        return;
      }

    } catch (e) {
      // Authentication validation failed - redirect to login for security
      print('Warning: Authentication validation failed: $e');
      print('Redirecting to login for security');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthNavigation()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    // Tampilkan dialog konfirmasi
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Sign out from Firebase and clear session
      await _authService.signOut();
      
      // Navigate to login page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthNavigation()),
          (route) => false,
        );
      }
    }
  }

Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 27, 134, 47),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                            child: _photoUrl == null 
                                ? const Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Color.fromARGB(255, 35, 141, 39),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _phone.isNotEmpty ? '$_username | $_phone' : _username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Monitoring Control',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            'Fire Alarm System User',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('My Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToProfile();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.question_answer),
                      title: const Text('WA Message Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Whats App Settings');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.domain_add),
                      title: const Text('Zone Name Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ZoneNameSettingsPage(),
                          ),
                        );
                      },
                    ),
                      ListTile(
                      leading: const Icon(Icons.fullscreen),
                      title: const Text('Full Monitoring'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FullMonitoringPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.grid_on),
                      title: const Text('Zone Monitoring'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ZoneMonitoringPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Tab Monitoring'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TabMonitoringPage(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.wifi_outlined),
                      title: const Text('WebSocket Debug'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WebSocketDebugPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 0.5),
              SafeArea(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ),
            ],
          ),
        ),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: const Color.fromARGB(255, 0, 180, 81),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor_outlined),
                activeIcon: Icon(Icons.monitor),
                label: 'Monitoring',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Control',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
