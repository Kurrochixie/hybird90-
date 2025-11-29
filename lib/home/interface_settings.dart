import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/fire_alarm_data.dart';

import '../auth/auth_navigation.dart';

class InterfaceSettingsPage extends StatefulWidget {
  final VoidCallback? onSettingsDone;
  final VoidCallback? onBackPressed;

  const InterfaceSettingsPage({super.key, this.onSettingsDone, this.onBackPressed});

  @override
  State<InterfaceSettingsPage> createState() => _InterfaceSettingsPageState();
}

class _InterfaceSettingsPageState extends State<InterfaceSettingsPage> {
  final TextEditingController projectNameController = TextEditingController();
  String? selectedTypePanel;
  int? selectedLoop;
  int? selectedModuleCount;
  bool isLoading = true;

  // Store old values for comparison
  int? oldModuleCount;
  String? currentActiveZone;

  final List<String> typePanelOptions = [
    'DDS-ADD-P1',
    'DDS-ADD-P STAR',
    'CONVENTIONAL PANEL CONTROL',
  ];

  final List<int> loopOptions = List<int>.generate(8, (index) => index + 1);
  final List<int> moduleCountOptions = List<int>.generate(63, (index) => index + 1);

  String? moduleCountError;

  bool _isSaving = false;
  bool _noInternet = false;
  bool _showNoInternetBanner = false;

  // Error state for connectivity
  bool hasError = false;
  String? errorMessage;

  // Connectivity timer and subscription
  Timer? _connectivityTimer;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadDataFromFirebase();
  }

  Future<void> _loadDataFromFirebase() async {
    // Check initial connectivity
    var connectivityResults = await Connectivity().checkConnectivity();
    bool hasInternet = !connectivityResults.contains(ConnectivityResult.none);

    if (hasInternet) {
      await _performLoad();
    } else {
      // No internet, set up listener and timer
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
        if (!result.contains(ConnectivityResult.none) && mounted) {
          // Internet available, cancel timer and proceed
          _connectivityTimer?.cancel();
          _performLoad();
        }
      });

      // Start 20 second timer for connection timeout
      _connectivityTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = 'Check your internet connection..';
            isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _performLoad() async {
    // Cancel connectivity listener and timer when proceeding
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();

    try {
      // Load data from Firebase projectInfo node
      final snapshot = await FirebaseDatabase.instance.ref().child('projectInfo').get();

      if (snapshot.exists && mounted) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          // Only set values if they exist in Firebase
          if (data['projectName'] != null) {
            projectNameController.text = data['projectName'];
          }

          if (data['panelType'] != null && typePanelOptions.contains(data['panelType'])) {
            selectedTypePanel = data['panelType'];
          }

          if (data['numberOfModules'] != null) {
            int modules = data['numberOfModules'];
            if (moduleCountOptions.contains(modules)) {
              selectedModuleCount = modules;
              oldModuleCount = modules; // Store old value
            }
          }

          // Loop is not stored in Firebase currently, but check if it exists
          if (data['loop'] != null) {
            int loop = data['loop'];
            if (loopOptions.contains(loop)) {
              selectedLoop = loop;
            }
          }

          // Load current activeZone
          if (data['activeZone'] != null) {
            currentActiveZone = data['activeZone'];
          }

          isLoading = false;
        });
      } else {
        // No data in Firebase, keep everything empty
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Error loading data, keep everything empty
      // Using 
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    projectNameController.dispose();
    _connectivityTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  // Parse zone data from Firebase format: "#001#Zone Name, #002#Zone Name, ..."
  Map<int, String> _parseZoneData(String data) {
    Map<int, String> zones = {};
    if (data.isEmpty) return zones;

    List<String> zoneEntries = data.split(',');
    for (String entry in zoneEntries) {
      entry = entry.trim();
      if (entry.isEmpty) continue;

      RegExp regex = RegExp(r'#(\d{3})#(.+)');
      Match? match = regex.firstMatch(entry);
      if (match != null) {
        int zoneNumber = int.parse(match.group(1)!);
        String zoneName = match.group(2)!;
        zones[zoneNumber] = zoneName;
      }
    }
    return zones;
  }

  // Format zone data for Firebase: "#001#Zone Name, #002#Zone Name, ..."
  String _formatZoneData(List<String> zoneNames) {
    List<String> entries = [];
    for (int i = 0; i < zoneNames.length; i++) {
      String zoneNumber = (i + 1).toString().padLeft(3, '0');
      entries.add('#$zoneNumber#${zoneNames[i]}');
    }
    return entries.join(', ');
  }

  Future<void> _submit() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    bool hasInternet = !connectivityResults.contains(ConnectivityResult.none);

    if (!hasInternet) {
      setState(() {
        _noInternet = true;
        _isSaving = false;
        _showNoInternetBanner = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showNoInternetBanner = false;
          });
        }
      });
      return;
    }

    setState(() {
      // Validate all required fields
      if (projectNameController.text.trim().isEmpty) {
        moduleCountError = 'Please enter Project Name';
      } else if (selectedTypePanel == null) {
        moduleCountError = 'Please select a Type Panel';
      } else if (selectedLoop == null) {
        moduleCountError = 'Please select a Loop';
      } else if (selectedModuleCount == null) {
        moduleCountError = 'Please select Number of Modules';
      } else {
        moduleCountError = null;
      }
    });

    if (moduleCountError != null) return;

    setState(() {
      _noInternet = false;
      _showNoInternetBanner = false;
      _isSaving = true;
    });

    // Store context references before async operation
    // ignore: use_build_context_synchronously
    final dialogContext = context;

    try {
      // Check if module count changed
      bool moduleCountChanged = selectedModuleCount != oldModuleCount;

      String newActiveZone = currentActiveZone ?? '';

      // ignore: use_build_context_synchronously
      if (moduleCountChanged) {
        if (!mounted) return;
      // Show dialog to choose option
        // ignore: use_build_context_synchronously
        bool? keepExisting = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: dialogContext,
          barrierDismissible: false,
          // ignore: use_build_context_synchronously
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: const Text('Module Count Changed'),
              content: const Text(
                'The number of modules has changed. Do you want to keep existing zone names (adjusted for new count) or create new default zone names?'
              ),
              actions: [
                // ignore: use_build_context_synchronously
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false), // Create new
                  child: const Text('Create New Defaults'),
                ),
                ElevatedButton(
                  // ignore: use_build_context_synchronously
                  onPressed: () => Navigator.of(ctx).pop(true), // Keep existing
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 35, 141, 39),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Keep Existing'),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        if (keepExisting == null) return; // Dialog dismissed

        // ignore: use_build_context_synchronously
        if (keepExisting) {
          // Adjust existing zone names
          Map<int, String> existingZones = _parseZoneData(currentActiveZone ?? '');
          List<String> zoneNames = [];
          int oldZones = (oldModuleCount ?? 0) * 5;
          int newZones = selectedModuleCount! * 5;

          // Get existing zone names
          for (int i = 1; i <= oldZones; i++) {
            zoneNames.add(existingZones[i] ?? 'Zone ${i.toString().padLeft(2, '0')}');
          }

          // Adjust for new count
          if (newZones > zoneNames.length) {
            // Add defaults for extra zones
            for (int i = zoneNames.length + 1; i <= newZones; i++) {
              zoneNames.add('Zone ${i.toString().padLeft(2, '0')}');
            }
          } else if (newZones < zoneNames.length) {
            // Truncate to new count
            zoneNames = zoneNames.take(newZones).toList();
          }

          newActiveZone = _formatZoneData(zoneNames);
        } else {
          // Create new defaults
          newActiveZone = '';
        }
      }
      
      // Update FireAlarmData with new values and sync to Firebase
      // ignore: use_build_context_synchronously
      final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);
      fireAlarmData.projectName = projectNameController.text.trim();
      fireAlarmData.panelType = selectedTypePanel!;
      fireAlarmData.numberOfModules = selectedModuleCount!;
      // Calculate number of zones as numberOfModules * 5
      int numberOfZones = fireAlarmData.numberOfModules * 5;

      // Prepare data map to sync to projectInfo only
      Map<String, dynamic> projectInfoData = {
        'projectName': fireAlarmData.projectName,
        'panelType': fireAlarmData.panelType,
        'numberOfModules': fireAlarmData.numberOfModules,
        'numberOfZones': numberOfZones,
        'loop': selectedLoop,
        'lastUpdateTime': DateTime.now().toIso8601String(),
        'activeZone': newActiveZone,
      };
      
      await FirebaseDatabase.instance.ref().child('projectInfo').update(projectInfoData);

      // Show success message and navigate if still mounted
      if (mounted) {
        if (widget.onSettingsDone != null) {
          widget.onSettingsDone!();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interface settings saved and uploaded to Firebase')),
          );
        }

        // SECURITY FIX: Navigate to login page after save - CRITICAL PATCH
        if (context.mounted) {
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (navigatorContext) => const AuthNavigation()),
          );
        }
      }
    } catch (e) {
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving interface settings: $e'),
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
                onPressed: _restartLoad,
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
      body: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          strokeWidth: 4,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    color: Colors.grey,
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
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
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    double fontSize = 30;
                                    if (constraints.maxWidth < 300) {
                                      fontSize = 20;
                                    } else if (constraints.maxWidth < 400) {
                                      fontSize = 25;
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 48), // padding to avoid overlap with back button
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'INTERFACE SETTINGS',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w300,
                                            fontSize: fontSize,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            _buildLabeledTextField('Project Name', projectNameController),
                            const SizedBox(height: 20),
                            _buildDropdownField('Type Panel', typePanelOptions, selectedTypePanel, (String? newValue) {
                              setState(() {
                                selectedTypePanel = newValue;
                              });
                            }),
                            const SizedBox(height: 20),
                            _buildDropdownField('Loop', loopOptions.map((e) => e.toString()).toList(), selectedLoop?.toString(), (String? newValue) {
                              setState(() {
                                selectedLoop = int.tryParse(newValue ?? '');
                              });
                            }),
                            const SizedBox(height: 20),
                            _buildDropdownField('Number of Modules', moduleCountOptions.map((e) => e.toString()).toList(), selectedModuleCount?.toString(), (String? newValue) {
                              setState(() {
                                selectedModuleCount = int.tryParse(newValue ?? '');
                              });
                            }, errorText: moduleCountError),
                            const SizedBox(height: 30),
                            Center(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _noInternet ? Colors.grey : const Color.fromARGB(255, 26, 117, 29),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  elevation: 4,
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
                                    : _noInternet
                                        ? const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.refresh),
                                              SizedBox(width: 8),
                                              Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w300,
                                                  fontSize: 18,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            'SAVE',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w300,
                                              fontSize: 18,
                                              letterSpacing: 2,
                                            ),
                                          ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (_showNoInternetBanner)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Check your internet connection',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartLoad() {
    setState(() {
      hasError = false;
      errorMessage = null;
      isLoading = true;
    });
    _loadDataFromFirebase();
  }

  Widget _buildLabeledTextField(String label, TextEditingController controller, {bool isNumber = false, String? errorText}) {
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
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            errorText: errorText,
            hintText: 'Enter $label', // Add hint text to show field is empty
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String? selectedValue, ValueChanged<String?> onChanged, {String? errorText}) {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: errorText != null ? Colors.red : Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit dropdown height to show max 5 items approx
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.white.withValues(alpha: 0.93), // Increase opacity for stronger blur effect
                    ),
                    child: DropdownButton<String>(
                      value: selectedValue,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: Text('Select $label'), // Add hint text for empty dropdown
                      onChanged: onChanged,
                      items: options.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
