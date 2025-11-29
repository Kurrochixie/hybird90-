import 'package:flutter/material.dart';
import 'dart:async';
import '../services/bell_manager.dart';

/// Bell Status Widget - Visual bell indicator with real-time updates
/// Shows active bells, mute status, and bell analytics
class BellStatusWidget extends StatefulWidget {
  final BellManager bellManager;
  final bool showAnalytics;
  final bool showDeviceList;
  final double? size;
  final Color? activeColor;
  final Color? inactiveColor;

  const BellStatusWidget({
    super.key,
    required this.bellManager,
    this.showAnalytics = false,
    this.showDeviceList = false,
    this.size,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<BellStatusWidget> createState() => _BellStatusWidgetState();
}

class _BellStatusWidgetState extends State<BellStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _soundWaveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _soundWaveAnimation;

  BellSystemStatus? _currentStatus;
  StreamSubscription<BellSystemStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeListeners();
  }

  void _initializeAnimations() {
    // Pulse animation for active bell
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Sound wave animation
    _soundWaveController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _soundWaveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _soundWaveController,
      curve: Curves.easeOut,
    ));
  }

  void _initializeListeners() {
    _currentStatus = widget.bellManager.currentStatus;
    _statusSubscription = widget.bellManager.bellStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
        _updateAnimations();
      }
    });
  }

  void _updateAnimations() {
    if (_currentStatus != null && _currentStatus!.activeBells > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      if (!_soundWaveController.isAnimating) {
        _soundWaveController.repeat();
      }
    } else {
      _pulseController.stop();
      _soundWaveController.stop();
      _pulseController.reset();
      _soundWaveController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStatus == null) {
      return _buildLoadingIndicator();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBellIndicator(),
        if (widget.showAnalytics) _buildAnalyticsSection(),
        if (widget.showDeviceList) _buildDeviceListSection(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.size ?? 40,
      height: widget.size ?? 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Center(
        child: SizedBox(
          width: (widget.size ?? 40) * 0.5,
          height: (widget.size ?? 40) * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
          ),
        ),
      ),
    );
  }

  Widget _buildBellIndicator() {
    final isActive = _currentStatus!.activeBells > 0;
    final isMuted = _currentStatus!.isSystemMuted || _currentStatus!.isBellPaused;
    final bellColor = _getBellColor(isActive, isMuted);

    return GestureDetector(
      onTap: () => _showBellDetails(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sound waves animation
          if (isActive && !isMuted)
            ...List.generate(3, (index) => _buildSoundWave(index)),

          // Main bell icon
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isActive && !isMuted ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: widget.size ?? 40,
                  height: widget.size ?? 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bellColor.withValues(alpha: 0.2),
                    border: Border.all(
                      color: bellColor,
                      width: 2,
                    ),
                    boxShadow: isActive && !isMuted
                        ? [
                            BoxShadow(
                              color: bellColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isMuted ? Icons.notifications_off : Icons.notifications,
                    color: bellColor,
                    size: (widget.size ?? 40) * 0.6,
                  ),
                ),
              );
            },
          ),

          // Bell count badge
          if (_currentStatus!.activeBells > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Text(
                    _currentStatus!.activeBells > 9 ? '9+' : '${_currentStatus!.activeBells}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSoundWave(int index) {
    return AnimatedBuilder(
      animation: _soundWaveAnimation,
      builder: (context, child) {
        final delay = index * 0.3;
        final adjustedAnimation = (_soundWaveAnimation.value - delay).clamp(0.0, 1.0);

        return Container(
          width: widget.size ?? 40,
          height: widget.size ?? 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.activeColor ?? Colors.red,
              width: 1,
            ),
          ),
          child: Transform.scale(
            scale: 1.0 + (adjustedAnimation * 0.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (widget.activeColor ?? Colors.red).withValues(alpha:
                    1.0 - adjustedAnimation,
                  ),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsSection() {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnalyticsRow('Active Bells', '${_currentStatus!.activeBells}/${_currentStatus!.totalDevices}'),
            _buildAnalyticsRow('System Muted', _currentStatus!.isSystemMuted ? 'Yes' : 'No'),
            _buildAnalyticsRow('Bell Paused', _currentStatus!.isBellPaused ? 'Yes' : 'No'),
            _buildAnalyticsRow('Last Activity', _formatTime(_currentStatus!.lastBellActivity)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListSection() {
    final activeDevices = widget.bellManager.activeBellDevices;

    if (activeDevices.isEmpty) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Bell Devices (${activeDevices.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: activeDevices.map((deviceId) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    deviceId,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBellColor(bool isActive, bool isMuted) {
    if (isMuted) {
      return widget.inactiveColor ?? Colors.grey;
    }
    if (isActive) {
      return widget.activeColor ?? Colors.red;
    }
    return widget.inactiveColor ?? Colors.grey[400]!;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  void _showBellDetails() {
    showDialog(
      context: context,
      builder: (context) => BellDetailsDialog(
        bellManager: widget.bellManager,
        currentStatus: _currentStatus!,
      ),
    );
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _pulseController.dispose();
    _soundWaveController.dispose();
    super.dispose();
  }
}

/// Bell Details Dialog - Shows comprehensive bell information
class BellDetailsDialog extends StatefulWidget {
  final BellManager bellManager;
  final BellSystemStatus currentStatus;

  const BellDetailsDialog({
    super.key,
    required this.bellManager,
    required this.currentStatus,
  });

  @override
  State<BellDetailsDialog> createState() => _BellDetailsDialogState();
}

class _BellDetailsDialogState extends State<BellDetailsDialog> {
  BellAnalytics? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() {
    setState(() {
      _analytics = widget.bellManager.getAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(),
                      SizedBox(height: 16),
                      _buildControlButtons(),
                      SizedBox(height: 16),
                      if (_analytics != null) _buildAnalytics(),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bell System Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.currentStatus.activeBells} of ${widget.currentStatus.totalDevices} devices active',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatRow('Active Bells', '${widget.currentStatus.activeBells}', Colors.red),
          Divider(height: 1),
          _buildStatRow('System Muted', widget.currentStatus.isSystemMuted ? 'Yes' : 'No', Colors.orange),
          Divider(height: 1),
          _buildStatRow('Bell Paused', widget.currentStatus.isBellPaused ? 'Yes' : 'No', Colors.blue),
          Divider(height: 1),
          _buildStatRow('Last Activity', _formatTime(widget.currentStatus.lastBellActivity), Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bell Controls',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final success = await widget.bellManager.toggleSystemMute();
                  if (success) {
                    _loadAnalytics();
                    setState(() {});
                  }
                },
                icon: Icon(widget.currentStatus.isSystemMuted ? Icons.notifications : Icons.notifications_off),
                label: Text(widget.currentStatus.isSystemMuted ? 'Unmute Bells' : 'Mute Bells'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.currentStatus.isSystemMuted ? Colors.green : Colors.orange,
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.currentStatus.isBellPaused
                    ? () async {
                        final success = await widget.bellManager.resumeBell();
                        if (success) {
                          _loadAnalytics();
                          setState(() {});
                        }
                      }
                    : () async {
                        final success = await widget.bellManager.pauseBell();
                        if (success) {
                          _loadAnalytics();
                          setState(() {});
                        }
                      },
                icon: Icon(widget.currentStatus.isBellPaused ? Icons.play_arrow : Icons.pause),
                label: Text(widget.currentStatus.isBellPaused ? 'Resume' : 'Pause'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.currentStatus.isBellPaused ? Colors.green : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalytics() {
    if (_analytics == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bell Analytics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildAnalyticsRow('Confirmations (Last Hour)', '${_analytics!.totalConfirmationsLastHour}'),
              _buildAnalyticsRow('Most Active Device', _analytics!.mostActiveDevice),
              _buildAnalyticsRow('Average Activation Time', _formatDuration(_analytics!.averageActivationTime)),
              if (_analytics!.muteDuration > Duration.zero)
                _buildAnalyticsRow('Mute Duration', _formatDuration(_analytics!.muteDuration)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return '${difference.inHours} hours ago';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}