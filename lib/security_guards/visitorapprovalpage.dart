import 'dart:async';
import 'package:flutter/material.dart';
import 'package:omm_admin/security_guards/qr_scanner_page.dart';
import 'package:omm_admin/security_guards/security_guard_profile.dart';
import 'package:omm_admin/services/security_guard_auth_service.dart';

import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

/// Professional visitor status enum for type safety and consistency
enum VisitorStatus {
  pending,
  approved,
  rejected;

  Color get badgeColor {
    switch (this) {
      case VisitorStatus.pending:
        return Colors.orange;
      case VisitorStatus.approved:
        return Colors.green;
      case VisitorStatus.rejected:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case VisitorStatus.pending:
        return Icons.access_time;
      case VisitorStatus.approved:
        return Icons.check_circle;
      case VisitorStatus.rejected:
        return Icons.cancel;
    }
  }

  String get displayName {
    switch (this) {
      case VisitorStatus.pending:
        return 'Pending';
      case VisitorStatus.approved:
        return 'Approved';
      case VisitorStatus.rejected:
        return 'Rejected';
    }
  }

  bool get canBeActedUpon => this == VisitorStatus.pending;

  int get priority {
    switch (this) {
      case VisitorStatus.pending:
        return 0;
      case VisitorStatus.approved:
        return 1;
      case VisitorStatus.rejected:
        return 2;
    }
  }
}

/// Professional visitor data model for type safety and consistency
class VisitorData {
  final String id;
  final String displayName;
  final String? timestamp;
  final String? progress;
  final String? type;
  final List<String>? assignedGates;
  final String? flatNumber;
  final VisitorStatus status;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final Map<String, dynamic> rawData;

  const VisitorData({
    required this.id,
    required this.displayName,
    this.timestamp,
    this.progress,
    this.type,
    this.assignedGates,
    this.flatNumber,
    required this.status,
    this.approvedAt,
    this.rejectedAt,
    required this.rawData,
  });

  factory VisitorData.fromMap(Map<String, dynamic> map) {
    // Determine status based on flags
    VisitorStatus status = VisitorStatus.pending;
    if (map['isApproved'] == true) {
      status = VisitorStatus.approved;
    } else if (map['isRejected'] == true) {
      status = VisitorStatus.rejected;
    }

    return VisitorData(
      id: map['_id'] ?? map['id'] ?? '',
      displayName: map['displayName'] ?? 'Unknown Visitor',
      timestamp: map['createdAt'] ?? map['timestamp'] ?? 'N/A',
      progress: map['progress'],
      type: map['type'] ?? map['preApprovalType'] ?? 'Other',
      assignedGates: (map['assignedGates'] ?? map['gateId']) is List
          ? List<String>.from((map['assignedGates'] ?? map['gateId']))
          : null,
      flatNumber: map['flatId'] ?? map['flatNumber'] ?? 'N/A',
      status: status,
      rawData: map,
    );
  }

  VisitorData copyWith({
    String? id,
    String? displayName,
    String? timestamp,
    String? progress,
    String? type,
    List<String>? assignedGates,
    String? flatNumber,
    VisitorStatus? status,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    Map<String, dynamic>? rawData,
  }) {
    return VisitorData(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      timestamp: timestamp ?? this.timestamp,
      progress: progress ?? this.progress,
      type: type ?? this.type,
      assignedGates: assignedGates ?? this.assignedGates,
      flatNumber: flatNumber ?? this.flatNumber,
      status: status ?? this.status,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toMap() => rawData;
}

/// Professional data processing pipeline for consistent visitor data handling
class VisitorDataManager {
  final List<VisitorData> _visitors = [];
  Timer? _refreshTimer;
  DateTime? _lastRealTimeUpdate;
  bool _isProcessing = false;

  /// Get current visitors list (returns a copy to prevent external modification)
  List<VisitorData> get visitors => List.unmodifiable(_visitors);

  /// Process visitor data from Socket.IO event or API response
  VisitorData _processVisitorData(Map<String, dynamic> rawData) {
    String displayName = rawData['displayName'] ?? 'Unknown Visitor';
    String progress = rawData['progress'] ?? '';
    String type = rawData['type'] ?? rawData['preApprovalType'] ?? 'other';

    // Determine status based on data
    VisitorStatus status = VisitorStatus.pending;
    if (rawData['isApproved'] == true) {
      status = VisitorStatus.approved;
    } else if (rawData['isRejected'] == true) {
      status = VisitorStatus.rejected;
    }

    return VisitorData(
      id: rawData['_id'] ?? rawData['id'],
      displayName: displayName,
      timestamp: rawData['createdAt'] ?? rawData['timestamp'] ?? 'N/A',
      progress: progress,
      type: type,
      assignedGates: (rawData['assignedGates'] ?? rawData['gateId']) is List
          ? List<String>.from((rawData['assignedGates'] ?? rawData['gateId']))
          : null,
      flatNumber: rawData['flatId'] ?? 'N/A',
      status: status,
      rawData: rawData,
    );
  }

  /// Add visitor instantly (like chat message appearing at top)
  void addVisitor(Map<String, dynamic> rawData) {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      final processedVisitor = _processVisitorData(rawData);

      // Check if visitor already exists
      final existingIndex = _visitors.indexWhere(
        (v) =>
            v.id == processedVisitor.id ||
            v.rawData['_id'] == processedVisitor.id,
      );

      if (existingIndex != -1) {
        // Update existing visitor
        _visitors[existingIndex] = processedVisitor;
        debugPrint(
          '🔄 VisitorDataManager: Updated existing visitor ${processedVisitor.id}',
        );
      } else {
        // Add new visitor at the beginning (chat-like behavior)
        _visitors.insert(0, processedVisitor);
        debugPrint(
          '🆕 VisitorDataManager: Added new visitor ${processedVisitor.id} at top',
        );
      }

      _lastRealTimeUpdate = DateTime.now();
      _resetRefreshTimer();
    } catch (e) {
      debugPrint('❌ VisitorDataManager: Error adding visitor: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Update visitor instantly
  void updateVisitor(Map<String, dynamic> rawData) {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      final processedVisitor = _processVisitorData(rawData);
      final visitorId = processedVisitor.id;

      final index = _visitors.indexWhere(
        (v) => v.id == visitorId || v.rawData['_id'] == visitorId,
      );

      if (index != -1) {
        _visitors[index] = processedVisitor;
        debugPrint('🔄 VisitorDataManager: Updated visitor $visitorId');
        _lastRealTimeUpdate = DateTime.now();
        _resetRefreshTimer();
      } else {
        debugPrint(
          '⚠️ VisitorDataManager: Visitor $visitorId not found for update',
        );
      }
    } catch (e) {
      debugPrint('❌ VisitorDataManager: Error updating visitor: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Update visitor status locally (for approval/rejection)
  void updateVisitorStatus(String visitorId, VisitorStatus newStatus) {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      final index = _visitors.indexWhere(
        (v) => v.id == visitorId || v.rawData['_id'] == visitorId,
      );

      if (index != -1) {
        final updatedVisitor = _visitors[index].copyWith(status: newStatus);
        _visitors[index] = updatedVisitor;
        debugPrint(
          '🔄 VisitorDataManager: Updated visitor $visitorId status to $newStatus',
        );
        _lastRealTimeUpdate = DateTime.now();
        _resetRefreshTimer();
      } else {
        debugPrint(
          '⚠️ VisitorDataManager: Visitor $visitorId not found for status update',
        );
      }
    } catch (e) {
      debugPrint('❌ VisitorDataManager: Error updating visitor status: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Remove visitor instantly
  void removeVisitor(String visitorId) {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      final initialLength = _visitors.length;
      _visitors.removeWhere(
        (v) => v.id == visitorId || v.rawData['_id'] == visitorId,
      );

      if (_visitors.length < initialLength) {
        debugPrint('🗑️ VisitorDataManager: Removed visitor $visitorId');
        _lastRealTimeUpdate = DateTime.now();
        _resetRefreshTimer();
      } else {
        debugPrint(
          '⚠️ VisitorDataManager: Visitor $visitorId not found for removal',
        );
      }
    } catch (e) {
      debugPrint('❌ VisitorDataManager: Error removing visitor: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Replace entire visitor list (for API refresh)
  void setVisitors(List<Map<String, dynamic>> rawVisitors) {
    if (_isProcessing) return;

    try {
      _isProcessing = true;
      _visitors.clear();
      for (final rawVisitor in rawVisitors) {
        _visitors.add(_processVisitorData(rawVisitor));
      }
      debugPrint(
        '📋 VisitorDataManager: Set ${rawVisitors.length} visitors from API',
      );
      _lastRealTimeUpdate = DateTime.now();
      _resetRefreshTimer();
    } catch (e) {
      debugPrint('❌ VisitorDataManager: Error setting visitors: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Smart refresh timer - only runs when no real-time updates have occurred recently
  void _resetRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 30), () {
      // Only refresh if no real-time updates in the last 30 seconds
      if (_lastRealTimeUpdate == null ||
          DateTime.now().difference(_lastRealTimeUpdate!) >
              const Duration(seconds: 30)) {
        debugPrint('⏰ VisitorDataManager: Smart refresh timer triggered');
        // This would trigger a refresh in the parent widget
      }
    });
  }

  /// Check if real-time updates are active (no need for periodic refresh)
  bool get hasRecentRealTimeUpdate {
    return _lastRealTimeUpdate != null &&
        DateTime.now().difference(_lastRealTimeUpdate!) <
            const Duration(seconds: 30);
  }

  /// Clear all visitors
  void clear() {
    _visitors.clear();
    _refreshTimer?.cancel();
    _lastRealTimeUpdate = null;
    debugPrint('🧹 VisitorDataManager: Cleared all visitors');
  }

  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    clear();
  }
}

class VisitorApprovalPage extends StatefulWidget {
  const VisitorApprovalPage({Key? key}) : super(key: key);

  @override
  State<VisitorApprovalPage> createState() => _VisitorApprovalPageState();
}

class _VisitorApprovalPageState extends State<VisitorApprovalPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0; // 0 for Visitors, 1 for QR Scan
  bool _isApproving = false;
  List<VisitorData> _pendingVisitors = [];
  bool _isLoadingVisitors = true;
  bool _isRefreshingVisitors = false; // Separate flag for refresh operations
  String? _errorMessage;
  bool _showExpiredVisitors = false; // Toggle for expired vs pending visitors

  io.Socket? _socket; // Socket.IO client

  // Professional data management for instant real-time updates
  final VisitorDataManager _visitorDataManager = VisitorDataManager();

  // Keep track of processed visitor IDs to prevent them from reappearing
  final Set<String> _processedVisitorIds = {};

  @override
  void initState() {
    super.initState();
    debugPrint('🏗️ VisitorApprovalPage initState called');

    try {
      WidgetsBinding.instance.addObserver(this);
      _checkSessionStatus();
      _loadPendingVisitors();
      _initializeSocketConnection(); // Initialize Socket.IO connection
    } catch (e) {
      debugPrint('❌ Error in VisitorApprovalPage initState: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize page: $e';
          _isLoadingVisitors = false;
        });
      }
    }
  }

  void _initializeSocketConnection() {
    try {
      // Use origin to get scheme + host + port (e.g., http://server:3000)
      final origin = Uri.parse(ApiService.baseUrl).origin;
      debugPrint('🔌 Connecting to Socket.IO at: $origin');

      // Get JWT token for authentication (async call)
      SecurityGuardAuthService.getToken()
          .then((token) {
            debugPrint('🔑 Socket.IO auth token available: ${token != null}');

            _socket = io.io(origin, <String, dynamic>{
              'transports': ['websocket', 'polling'],
              'autoConnect':
                  false, // Don't auto-connect, we'll connect manually
              'forceNew': true,
              'timeout': 10000, // Increased timeout
              'reconnection': true,
              'reconnectionAttempts': 5,
              'reconnectionDelay': 1000,
              // Add JWT token for authentication if available
              if (token != null) 'query': {'token': token},
              // If server uses a custom path: 'path': '/socket.io',
            });

            // Set up event handlers BEFORE connecting
            _setupSocketEventHandlers();

            // Connect manually
            debugPrint('🔌 Manually connecting Socket.IO...');
            _socket!.connect();
          })
          .catchError((error) {
            debugPrint('❌ Error getting auth token for Socket.IO: $error');
            // Connect without token if token retrieval fails
            _socket = io.io(origin, <String, dynamic>{
              'transports': ['websocket', 'polling'],
              'autoConnect': false,
              'forceNew': true,
              'timeout': 10000,
              'reconnection': true,
              'reconnectionAttempts': 5,
              'reconnectionDelay': 1000,
            });

            // Set up event handlers without token
            _setupSocketEventHandlers();
            _socket!.connect();
          });
    } catch (e, st) {
      debugPrint('🔥 Error initializing Socket.IO: $e\n$st');
    }
  }

  void _setupSocketEventHandlers() {
    if (_socket == null) return;

    debugPrint('🔧 Setting up Socket.IO event handlers...');

    // Connection events
    _socket!.on('connect', (_) {
      debugPrint('✅ Socket.IO connected: ${_socket!.id}');
      debugPrint('🏢 Socket.IO connected to: ${_socket!.io.uri}');
      _joinGuardRoom();
    });

    _socket!.on('connect_error', (data) {
      debugPrint('🔥 Socket.IO connect_error: $data');
      debugPrint('🔍 Connection error details: ${data.toString()}');
    });

    _socket!.on('disconnect', (reason) {
      debugPrint('❌ Socket.IO disconnected: $reason');
      debugPrint('🔍 Disconnect reason: $reason');
    });

    _socket!.on('reconnect', (attempt) {
      debugPrint('🔄 Socket.IO reconnected, attempt: $attempt');
      _joinGuardRoom();
    });

    _socket!.on('reconnect_error', (error) {
      debugPrint('🔄 Socket.IO reconnection error: $error');
    });

    _socket!.on('reconnect_failed', (_) {
      debugPrint('❌ Socket.IO reconnection failed - giving up');
    });

    // Visitor events - make sure these match server event names exactly
    _socket!.on('visitorAdded', (data) {
      debugPrint('🆕 visitorAdded event received: $data');
      debugPrint('📊 Event data type: ${data.runtimeType}');
      if (data != null) {
        debugPrint(
          '📋 Visitor data keys: ${(data as Map?)?.keys.toList() ?? "Not a Map"}',
        );
      }
      if (mounted && data != null) {
        debugPrint('� Adding new visitor instantly like chat message...');

        // Process visitor data directly from Socket.IO event (like chat message)
        final visitorMap = data as Map<String, dynamic>;

        String displayName = visitorMap['displayName'] ?? 'Unknown Visitor';
        String progress = visitorMap['progress'] ?? '';
        String type =
            visitorMap['type'] ?? visitorMap['preApprovalType'] ?? 'other';

        final newVisitor = {
          'id': visitorMap['_id'] ?? visitorMap['id'],
          'name': displayName,
          'mobile': 'N/A',
          'purpose': displayName,
          'flatNumber': visitorMap['flatId'] ?? 'N/A',
          'timestamp':
              visitorMap['createdAt'] ?? visitorMap['timestamp'] ?? 'N/A',
          'type': type,
          'inviteType': visitorMap['inviteType'],
          'totalCount': visitorMap['totalCount'] ?? 1,
          'approvedCount': visitorMap['approvedCount'] ?? 0,
          'gateId': visitorMap['gateId'] ?? [],
          'otpCode': visitorMap['otpCode'],
          'qrCode': visitorMap['qrCode'],
          'expiry': visitorMap['expiry'],
          'displayName': displayName,
          'progress': progress,
          'assignedGates': visitorMap['assignedGates'] ?? visitorMap['gateId'],
          ...visitorMap,
        };

        debugPrint(
          '✅ Processed new visitor: ${newVisitor['id']} - ${newVisitor['displayName']}',
        );

        // Add to the beginning of the list (like new chat messages appear at top)
        setState(() {
          final newVisitor = VisitorData(
            id: visitorMap['_id'] ?? visitorMap['id'],
            displayName: displayName,
            timestamp:
                visitorMap['createdAt'] ?? visitorMap['timestamp'] ?? 'N/A',
            progress: progress,
            type: type,
            assignedGates:
                (visitorMap['assignedGates'] ?? visitorMap['gateId']) is List
                ? List<String>.from(
                    (visitorMap['assignedGates'] ?? visitorMap['gateId']),
                  )
                : null,
            flatNumber: visitorMap['flatId'] ?? 'N/A',
            status: VisitorStatus.pending,
            rawData: visitorMap,
          );
          _pendingVisitors.insert(0, newVisitor);
          debugPrint(
            '💬 New visitor added instantly to list (chat-like behavior)',
          );
        });

        _showNewVisitorNotification(data);
      }
    });

    _socket!.on('visitorUpdated', (data) {
      debugPrint('🔄 visitorUpdated event received: $data');
      debugPrint('📊 Event data type: ${data.runtimeType}');
      if (mounted && data != null) {
        debugPrint('🔄 Updating visitor instantly...');

        // Use VisitorDataManager for instant update (no API call needed)
        _visitorDataManager.updateVisitor(data as Map<String, dynamic>);

        // Update UI with processed visitors
        setState(() {
          _pendingVisitors = _visitorDataManager.visitors;
        });
      }
    });

    _socket!.on('visitorRemoved', (data) {
      debugPrint('🗑️ visitorRemoved event received: $data');
      debugPrint('📊 Event data type: ${data.runtimeType}');
      if (data != null && mounted) {
        final visitorId = data['visitorId'] ?? data['id'] ?? data['_id'];
        debugPrint('🆔 Removing visitor instantly: $visitorId');

        // Use VisitorDataManager for instant removal (no API call needed)
        _visitorDataManager.removeVisitor(visitorId.toString());

        // Update UI with processed visitors
        setState(() {
          _pendingVisitors = _visitorDataManager.visitors;
        });
      }
    });

    // New event for instant visitor approval removal
    _socket!.on('visitorApprovedInstant', (data) {
      debugPrint('✅ visitorApprovedInstant event received: $data');
      debugPrint('📊 Event data type: ${data.runtimeType}');
      if (data != null && mounted) {
        final visitorId = data['visitorId'];
        final action = data['action'];
        debugPrint('🆔 Visitor ID: $visitorId, Action: $action');

        if (action == 'remove_from_pending') {
          // Instead of removing from VisitorDataManager, mark as approved locally
          // This preserves the visitor for refresh operations
          setState(() {
            final visitorIndex = _pendingVisitors.indexWhere(
              (visitor) =>
                  visitor.id == visitorId ||
                  visitor.rawData['_id'] == visitorId,
            );
            if (visitorIndex != -1) {
              // Update visitor status to approved
              final updatedVisitor = _pendingVisitors[visitorIndex].copyWith(
                status: VisitorStatus.approved,
              );
              _pendingVisitors[visitorIndex] = updatedVisitor;
              debugPrint(
                '✅ Visitor $visitorId marked as approved via Socket.IO event',
              );
            } else {
              debugPrint(
                '⚠️ Visitor $visitorId not found in local list for Socket.IO approval',
              );
            }
          });
        }
      }
    });
    _socket!.on('error', (error) {
      debugPrint('🚨 Socket.IO error: $error');
    });

    _socket!.on('ping', (_) {
      debugPrint('🏓 Socket.IO ping received');
    });

    _socket!.on('pong', (_) {
      debugPrint('🏓 Socket.IO pong received');
    });

    // Remove periodic refresh - rely on Socket.IO for real-time updates
    // Smart periodic refresh as fallback (every 30 seconds only if no real-time updates)
    // This ensures data consistency while prioritizing real-time updates
    // Timer.periodic(const Duration(seconds: 30), (timer) {
    //   if (mounted && !_isLoadingVisitors && !_hasRecentRealtimeUpdate) {
    //     debugPrint('⏰ Fallback refresh: checking for missed updates');
    //     _showExpiredVisitors ? _loadExpiredVisitors() : _loadPendingVisitors();
    //   } else if (!mounted) {
    //     timer.cancel();
    //   }
    // });

    debugPrint('✅ Socket.IO event handlers set up successfully');
  }

  void _joinGuardRoom() async {
    try {
      if (_socket == null || !_socket!.connected) {
        debugPrint('❌ Cannot join guard room: Socket not connected');
        return;
      }

      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      if (guardData != null) {
        final guardId = guardData['_id'] ?? guardData['id'];
        if (guardId == null) {
          debugPrint('❌ Guard ID missing from guardData: $guardData');
          return;
        }

        debugPrint('🏢 Joining guard room with guardId: $guardId');
        debugPrint('🔌 Socket connected: ${_socket!.connected}');
        debugPrint('🆔 Socket ID: ${_socket!.id}');

        // Emit joinGuardRoom event
        _socket!.emit('joinGuardRoom', guardId);

        debugPrint('📤 Emitted joinGuardRoom event with data: $guardId');

        // Listen for room join confirmation
        _socket!.once('joinedGuardRoom', (data) {
          debugPrint('✅ Successfully joined guard room: $data');
        });

        // Test the connection by emitting a ping
        _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
        debugPrint('📤 Emitted test ping to server');
      } else {
        debugPrint('❌ Guard data is null, cannot join guard room');
      }
    } catch (e) {
      debugPrint('❌ Error joining guard room: $e');
    }
  }

  void _showNewVisitorNotification(dynamic data) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🆕 New visitor request received!'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Scroll to top or refresh the list
            _loadPendingVisitors();
          },
        ),
      ),
    );
  }

  Future<void> _loadPendingVisitors() async {
    debugPrint('🚀 STARTING _loadPendingVisitors()');

    // Check if this is a refresh (we already have data) or initial load
    final isRefresh = _pendingVisitors.isNotEmpty;

    try {
      if (isRefresh) {
        // For refresh operations, show subtle loading indicator
        setState(() {
          _isRefreshingVisitors = true;
          _errorMessage = null;
        });
      } else {
        // For initial load, show full loading screen
        setState(() {
          _isLoadingVisitors = true;
          _errorMessage = null;
        });
      }

      // Get guard data
      debugPrint('🔍 Getting logged in guard data...');
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      debugPrint('🔍 Guard data retrieved: $guardData');

      if (guardData == null) {
        debugPrint('❌ Guard data is null - user not properly logged in');
        if (mounted) {
          setState(() {
            _errorMessage = 'Login session not found. Please login again.';
            if (isRefresh) {
              _isRefreshingVisitors = false;
            } else {
              _isLoadingVisitors = false;
            }
          });
        }
        return;
      }

      // ✅ UPDATED: Extract guardId from guardData
      final guardId = guardData['_id'] ?? guardData['id'];

      debugPrint('🔍 Extracted parameters:');
      debugPrint('  - Guard ID: $guardId');

      if (guardId == null) {
        debugPrint('❌ Guard ID is null');
        if (mounted) {
          setState(() {
            _errorMessage = 'Guard ID not found. Please login again.';
            if (isRefresh) {
              _isRefreshingVisitors = false;
            } else {
              _isLoadingVisitors = false;
            }
          });
        }
        return;
      }

      debugPrint(
        '📡 Calling ApiService.getPendingVisitors with guardId: $guardId',
      );

      // ✅ UPDATED: Use new API signature with guardId as positional parameter
      final result = await ApiService.getPendingVisitors(guardId);

      debugPrint('📨 RAW API RESPONSE: $result');
      debugPrint('📊 Response type: ${result.runtimeType}');
      debugPrint('📊 Response length: ${result.length}');

      // Log detailed response analysis
      debugPrint('✅ API returned List with ${result.length} items');
      if (result.isNotEmpty) {
        debugPrint('📋 First item type: ${result.first.runtimeType}');
        debugPrint(
          '📋 First item keys: ${(result.first as Map?)?.keys.toList() ?? "Not a Map"}',
        );
      }

      debugPrint('✅ API returned List, processing data...');
      final visitors = result;
      debugPrint('📋 Processing ${visitors.length} visitor records...');

      if (mounted) {
        setState(() {
          // Preserve ALL approved and rejected visitors during refresh - they should stay visible with their status
          final processedVisitors = _pendingVisitors
              .where(
                (visitor) =>
                    visitor.status == VisitorStatus.approved ||
                    visitor.status == VisitorStatus.rejected,
              )
              .toList();

          debugPrint(
            '🔄 Preserving ${processedVisitors.length} approved/rejected visitors during refresh',
          );

          // Clear the visitor manager and add only truly pending visitors from API
          _visitorDataManager.clear();

          // Process API response - the API should only return pending visitors, but we'll double-check
          final rawVisitors = result.cast<Map<String, dynamic>>();
          debugPrint(
            '📊 API returned ${rawVisitors.length} raw visitor records',
          );

          // Filter to ensure we only process visitors that are actually pending AND not already processed
          final trulyPendingVisitors = rawVisitors.where((visitor) {
            final visitorId = visitor['_id'] ?? visitor['id'] ?? '';
            final isApproved = visitor['isApproved'] == true;
            final isRejected = visitor['isRejected'] == true;
            final isAlreadyProcessed = _processedVisitorIds.contains(visitorId);

            final shouldInclude =
                !isApproved && !isRejected && !isAlreadyProcessed;

            if (!shouldInclude) {
              debugPrint(
                '⚠️ Filtering out visitor $visitorId - Status: approved=$isApproved, rejected=$isRejected, processed=$isAlreadyProcessed',
              );
            }

            return shouldInclude;
          }).toList();

          debugPrint(
            '✅ After filtering, ${trulyPendingVisitors.length} truly pending visitors from API (${_processedVisitorIds.length} already processed)',
          );

          // Set only the pending visitors in the manager
          _visitorDataManager.setVisitors(trulyPendingVisitors);
          _pendingVisitors = List<VisitorData>.from(
            _visitorDataManager.visitors,
          );

          // Add back ALL previously approved/rejected visitors to maintain their status across refreshes
          _pendingVisitors.addAll(processedVisitors);

          debugPrint(
            '🔄 Refresh complete: ${_pendingVisitors.length} total visitors '
            '(${processedVisitors.where((v) => v.status == VisitorStatus.approved).length} approved, '
            '${processedVisitors.where((v) => v.status == VisitorStatus.rejected).length} rejected, '
            '${_pendingVisitors.length - processedVisitors.length} pending)',
          );

          if (isRefresh) {
            _isRefreshingVisitors = false;
          } else {
            _isLoadingVisitors = false;
          }
          debugPrint(
            '🎉 Successfully loaded ${_pendingVisitors.length} visitors',
          );
        });
      }
    } catch (e, stackTrace) {
      debugPrint('💥 EXCEPTION in _loadPendingVisitors: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      debugPrint('🔍 Error message: ${e.toString()}');

      // Log additional error details
      if (e is FormatException) {
        debugPrint('❌ FormatException: Invalid JSON response from server');
      } else if (e is TimeoutException) {
        debugPrint('⏰ TimeoutException: Server request timed out');
      } else if (e.toString().contains('SocketException')) {
        debugPrint('🌐 SocketException: Network connection failed');
      } else if (e.toString().contains('HttpException')) {
        debugPrint('🔗 HttpException: HTTP request failed');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('🔐 Authentication Error: Invalid or expired token');
      } else if (e.toString().contains('404')) {
        debugPrint('🔍 Not Found Error: API endpoint not found');
      } else if (e.toString().contains('500')) {
        debugPrint('🖥️ Server Error: Internal server error');
      }

      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          if (isRefresh) {
            _isRefreshingVisitors = false;
          } else {
            _isLoadingVisitors = false;
          }
        });
      }
    }
    debugPrint('🏁 ENDING _loadPendingVisitors()');
  }

  Future<void> _loadExpiredVisitors() async {
    debugPrint('🚀 STARTING _loadExpiredVisitors()');

    if (!mounted) {
      debugPrint('❌ Widget not mounted, aborting');
      return;
    }

    setState(() {
      _isLoadingVisitors = true;
      _errorMessage = null;
    });

    try {
      // Get guard ID from stored data
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      final guardId = guardData?['_id'] ?? guardData?['id']; // Prioritize _id

      if (guardId == null) {
        debugPrint('❌ Guard ID is null');
        if (mounted) {
          setState(() {
            _errorMessage = 'Guard ID not found. Please login again.';
            _isLoadingVisitors = false;
          });
        }
        return;
      }

      debugPrint(
        '📡 Calling ApiService.getExpiredVisitors with guardId: $guardId',
      );

      // ✅ Use new API method for expired visitors
      final result = await ApiService.getExpiredVisitors(guardId);

      debugPrint('📨 RAW API RESPONSE: $result');
      debugPrint('📊 Response type: ${result.runtimeType}');
      debugPrint('📊 Response length: ${result.length}');

      // Log detailed response analysis
      debugPrint('✅ API returned List with ${result.length} items');
      if (result.isNotEmpty) {
        debugPrint('📋 First item type: ${result.first.runtimeType}');
        debugPrint(
          '📋 First item keys: ${(result.first as Map?)?.keys.toList() ?? "Not a Map"}',
        );
      }

      debugPrint('✅ API returned List, processing expired visitors...');
      final visitors = result;
      debugPrint('📋 Processing ${visitors.length} expired visitor records...');

      if (mounted) {
        setState(() {
          _pendingVisitors = List<VisitorData>.from(
            visitors.map((visitor) {
              debugPrint(
                '👤 Processing expired visitor: ${visitor['_id'] ?? visitor['id']}',
              );
              final visitorMap = visitor as Map<String, dynamic>;

              String displayName =
                  visitorMap['displayName'] ?? 'Unknown Visitor';
              String progress = visitorMap['progress'] ?? '';
              String type =
                  visitorMap['type'] ??
                  visitorMap['preApprovalType'] ??
                  'other';

              return VisitorData(
                id: visitorMap['_id'] ?? visitorMap['id'],
                displayName: displayName,
                timestamp:
                    visitorMap['createdAt'] ?? visitorMap['timestamp'] ?? 'N/A',
                progress: progress,
                type: type,
                assignedGates:
                    (visitorMap['assignedGates'] ?? visitorMap['gateId'])
                        is List
                    ? List<String>.from(
                        (visitorMap['assignedGates'] ?? visitorMap['gateId']),
                      )
                    : null,
                flatNumber: visitorMap['flatId'] ?? 'N/A',
                status: VisitorStatus
                    .rejected, // Expired visitors are treated as rejected
                rawData: visitorMap,
              );
            }).toList(),
          );
          _isLoadingVisitors = false;
          debugPrint(
            '🎉 Successfully loaded ${_pendingVisitors.length} expired visitors',
          );
        });
      }
    } catch (e, stackTrace) {
      debugPrint('💥 EXCEPTION in _loadExpiredVisitors: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      debugPrint('🔍 Error message: ${e.toString()}');

      // Log additional error details
      if (e is FormatException) {
        debugPrint('❌ FormatException: Invalid JSON response from server');
      } else if (e is TimeoutException) {
        debugPrint('⏰ TimeoutException: Server request timed out');
      } else if (e.toString().contains('SocketException')) {
        debugPrint('🌐 SocketException: Network connection failed');
      } else if (e.toString().contains('HttpException')) {
        debugPrint('🔗 HttpException: HTTP request failed');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('🔐 Authentication Error: Invalid or expired token');
      } else if (e.toString().contains('404')) {
        debugPrint('🔍 Not Found Error: API endpoint not found');
      } else if (e.toString().contains('500')) {
        debugPrint('🖥️ Server Error: Internal server error');
      }

      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoadingVisitors = false;
        });
      }
    }
    debugPrint('🏁 ENDING _loadExpiredVisitors()');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_socket != null) {
      try {
        _socket!.disconnect();
        // Note: dispose() may not exist on all socket client versions
        // _socket!.dispose(); // Commented out as it may not be available
      } catch (e) {
        debugPrint('Error disposing socket: $e');
      }
      _socket = null;
    }
    _visitorDataManager.dispose(); // Dispose of data manager
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionStatus();
    }
  }

  Future<void> _checkSessionStatus() async {
    debugPrint('🔍 Checking session status...');
    final isLoggedIn = await SecurityGuardAuthService.isLoggedIn();
    debugPrint('Session check result: $isLoggedIn');

    if (!isLoggedIn) {
      debugPrint('Session check failed, forcing logout');
      if (!mounted) return;
      _forceLogout('Session expired. Please login again.');
      return;
    }

    debugPrint('Session check passed, user is logged in');

    // JWT tokens handle their own expiration, no need for manual session time checking
  }

  Future<void> _performLogout() async {
    try {
      await SecurityGuardAuthService.logout();
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  void _forceLogout(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
    _performLogout();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Automatically start QR scanning when QR Scan tab is selected
    if (index == 1) {
      _scanQRCode();
    }
  }

  Future<void> _showApproveDialog(VisitorData visitor) async {
    final TextEditingController codeController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Approve Visitor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visitor Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color(0xFF455A64),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  visitor.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Show progress if available
                          if (visitor.progress != null &&
                              visitor.progress!.isNotEmpty)
                            Text('Progress: ${visitor.progress}'),
                          // Show type
                          Text('Type: ${visitor.type ?? 'Other'}'),
                          // Show assigned gates if available
                          if (visitor.assignedGates != null &&
                              visitor.assignedGates!.isNotEmpty)
                            Text(
                              'Assigned Gates: ${visitor.assignedGates!.join(', ')}',
                            ),
                          Text('Flat: ${visitor.flatNumber ?? 'N/A'}'),
                          Text('Time: ${visitor.timestamp ?? 'N/A'}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter 4-digit approval code:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        hintText: 'Enter 4-digit code',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final code = codeController.text.trim();
                          if (code.length != 4 ||
                              !RegExp(r'^\d{4}$').hasMatch(code)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid 4-digit code',
                                ),
                              ),
                            );
                            return;
                          }

                          // Check if the entered code matches the visitor's OTP code
                          final visitorOtpCode = visitor.rawData['otpCode']
                              ?.toString();
                          if (visitorOtpCode != null &&
                              visitorOtpCode != code) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invalid approval code. Please check and try again.',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          try {
                            await _approveVisitor(visitor.id, otpCode: code);
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Approve'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _approveVisitor(
    String visitorId, {
    required String otpCode,
  }) async {
    debugPrint('🚀 STARTING VISITOR APPROVAL PROCESS');
    debugPrint('📋 Visitor ID: $visitorId');
    debugPrint('🔢 OTP Code: $otpCode');

    // Add loading state to prevent multiple clicks
    setState(() => _isApproving = true);

    try {
      // Get guard ID from stored data
      debugPrint('🔍 Retrieving guard data...');
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      debugPrint(
        '📊 Guard data retrieved: ${guardData != null ? 'SUCCESS' : 'NULL'}',
      );

      final guardId = guardData?['_id'] ?? guardData?['id']; // Prioritize _id
      debugPrint('🆔 Guard ID extracted: $guardId');

      if (guardId == null) {
        debugPrint('❌ ERROR: Guard ID is null - user not properly logged in');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guard ID not found. Please login again.'),
            ),
          );
        }
        return;
      }

      // Validate OTP code format (exactly 4 digits)
      if (otpCode.isEmpty) {
        debugPrint('❌ ERROR: OTP code is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP code is required for approval.')),
          );
        }
        return;
      }

      // Additional OTP format validation
      if (!RegExp(r'^\d{4}$').hasMatch(otpCode)) {
        debugPrint('❌ ERROR: OTP code format invalid');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP must be exactly 4 digits.')),
          );
        }
        return;
      }

      debugPrint('✅ VALIDATION PASSED - All required data available');
      debugPrint(
        '🔐 Approving visitor: $visitorId with OTP: $otpCode for guard: $guardId',
      );

      // Call API service
      debugPrint('🌐 Calling ApiService.approveVisitor...');
      final result = await ApiService.approveVisitor(
        guardId: guardId,
        visitorId: visitorId,
        otpCode: otpCode,
      );

      debugPrint('📡 API RESPONSE RECEIVED');
      debugPrint('📊 Response type: ${result.runtimeType}');
      debugPrint('📋 Response keys: ${result.keys.toList()}');
      debugPrint('📱 Approval result: $result');

      // Safe response handling with null safety
      final success = result['success'] as bool?;
      final message = result['message'] as String?;
      final data = result['data'];

      debugPrint(
        '🔍 Parsed success value: $success (type: ${success.runtimeType})',
      );
      debugPrint('🔍 Parsed message value: $message');
      debugPrint('🔍 Parsed data value: $data');

      if (success == true) {
        debugPrint('✅ APPROVAL SUCCESSFUL');
        debugPrint(
          '📝 Success message: ${message ?? 'Visitor approved successfully'}',
        );

        // Mark visitor as approved locally to prevent blinking on refresh
        debugPrint('🔄 Marking visitor as approved locally...');
        setState(() {
          final visitorIndex = _pendingVisitors.indexWhere(
            (visitor) => visitor.id == visitorId || visitor.id == visitorId,
          );
          if (visitorIndex != -1) {
            // Create updated visitor with approved status
            final updatedVisitor = _pendingVisitors[visitorIndex].copyWith(
              status: VisitorStatus.approved,
            );
            _pendingVisitors[visitorIndex] = updatedVisitor;
            debugPrint(
              '✅ Visitor marked as approved locally at index: $visitorIndex',
            );
          } else {
            debugPrint(
              '⚠️ Visitor not found in local list for marking as approved',
            );
          }

          // Add to processed visitors set to prevent reappearance
          _processedVisitorIds.add(visitorId);
          debugPrint(
            '🛡️ Added visitor $visitorId to processed set (total: ${_processedVisitorIds.length})',
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message ?? 'Visitor approved successfully')),
          );
        }
      } else {
        debugPrint('❌ APPROVAL FAILED - API returned success=false');
        debugPrint('📝 Error message: ${message ?? 'Unknown error'}');
        debugPrint('🔍 Full response: $result');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message ?? 'Failed to approve visitor')),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('💥 CRITICAL ERROR in _approveVisitor');
      debugPrint('🔥 Exception type: ${e.runtimeType}');
      debugPrint('🔥 Exception message: ${e.toString()}');
      debugPrint('📚 Stack trace: $stackTrace');

      // Simplified error handling - focus on user-friendly messages
      String errorMessage = 'Error approving visitor';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        errorMessage = 'Network error. Check your connection and try again.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = 'Authentication error. Please login again.';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Visitor not found or approval endpoint unavailable.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please check your connection.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }

    debugPrint('🏁 ENDING VISITOR APPROVAL PROCESS');
  }

  Future<void> _rejectVisitor(String visitorId) async {
    debugPrint('🚀 STARTING VISITOR REJECTION PROCESS');
    debugPrint('📋 Visitor ID: $visitorId');

    try {
      // Get guard ID from stored data
      debugPrint('🔍 Retrieving guard data for rejection...');
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      debugPrint(
        '📊 Guard data retrieved: ${guardData != null ? 'SUCCESS' : 'NULL'}',
      );

      final guardId = guardData?['_id'] ?? guardData?['id']; // Prioritize _id
      debugPrint('🆔 Guard ID extracted: $guardId');

      if (guardId == null) {
        debugPrint('❌ ERROR: Guard ID is null - user not properly logged in');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guard ID not found. Please login again.'),
          ),
        );
        return;
      }

      debugPrint('✅ VALIDATION PASSED - Processing visitor rejection');
      //debugPrint('❌ Rejecting visitor: $visitorId ');

      // Call API service
      debugPrint('🌐 Calling ApiService.rejectVisitor...');
      final result = await ApiService.rejectVisitor(
        visitorId: visitorId,
        guardId: guardId,
      );

      debugPrint('📡 REJECTION API RESPONSE RECEIVED');
      debugPrint('📊 Response type: ${result.runtimeType}');
      debugPrint('📋 Response keys: ${result.keys.toList()}');
      debugPrint('📱 Rejection result: $result');

      if (result['success'] == true) {
        debugPrint('✅ REJECTION SUCCESSFUL');
        debugPrint(
          '📝 Success message: ${result['message'] ?? 'Visitor rejected successfully'}',
        );

        // Update visitor with full data from API response
        final visitorData = result['data'];
        if (visitorData != null && visitorData is Map<String, dynamic>) {
          debugPrint('📊 Processing rejection data from API response');
          setState(() {
            final visitorIndex = _pendingVisitors.indexWhere(
              (visitor) => visitor.id == visitorId,
            );
            if (visitorIndex != -1) {
              // Create updated visitor with rejected status and timestamp
              final updatedVisitor = _pendingVisitors[visitorIndex].copyWith(
                status: VisitorStatus.rejected,
                rejectedAt: visitorData['rejectedAt'] != null
                    ? DateTime.tryParse(visitorData['rejectedAt'])
                    : DateTime.now(),
              );
              _pendingVisitors[visitorIndex] = updatedVisitor;
              debugPrint(
                '✅ Visitor updated with rejected status and timestamp',
              );
            }

            // Add to processed visitors set to prevent reappearance
            _processedVisitorIds.add(visitorId);
            debugPrint(
              '🛡️ Added rejected visitor $visitorId to processed set (total: ${_processedVisitorIds.length})',
            );
          });
        } else {
          // Fallback to local marking if no data in response
          debugPrint('⚠️ No visitor data in API response, using local marking');
          setState(() {
            final visitorIndex = _pendingVisitors.indexWhere(
              (visitor) => visitor.id == visitorId,
            );
            if (visitorIndex != -1) {
              final updatedVisitor = _pendingVisitors[visitorIndex].copyWith(
                status: VisitorStatus.rejected,
                rejectedAt: DateTime.now(),
              );
              _pendingVisitors[visitorIndex] = updatedVisitor;
            }

            // Add to processed visitors set to prevent reappearance
            _processedVisitorIds.add(visitorId);
            debugPrint(
              '🛡️ Added rejected visitor $visitorId to processed set (total: ${_processedVisitorIds.length})',
            );
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Visitor rejected successfully')),
          );
        }

        // Refresh the list
        debugPrint('🔄 Refreshing visitor list after rejection...');
        await _loadPendingVisitors();
        debugPrint('✅ Visitor list refreshed successfully');
      } else {
        debugPrint('❌ REJECTION FAILED - API returned success=false');
        debugPrint('📝 Error message: ${result['message'] ?? 'Unknown error'}');
        debugPrint('🔍 Full response: $result');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to reject visitor'),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('� CRITICAL ERROR in _rejectVisitor');
      debugPrint('�🔥 Exception type: ${e.runtimeType}');
      debugPrint('🔥 Exception message: ${e.toString()}');
      debugPrint('📚 Stack trace: $stackTrace');

      // Detailed error analysis for rejection
      if (e.toString().contains('SocketException')) {
        debugPrint('🌐 NETWORK ERROR: Cannot connect to server');
        debugPrint('💡 Check: Is the backend server running?');
        debugPrint('💡 Check: Is the device connected to internet?');
      } else if (e.toString().contains('TimeoutException')) {
        debugPrint('⏰ TIMEOUT ERROR: Request took too long');
        debugPrint('💡 Check: Is the server responding slowly?');
        debugPrint('💡 Check: Is there a network connectivity issue?');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('🔐 AUTHENTICATION ERROR: Invalid or expired token');
        debugPrint('💡 Check: Is the user logged in?');
        debugPrint('💡 Check: Has the session expired?');
      } else if (e.toString().contains('404')) {
        debugPrint('🔍 NOT FOUND ERROR: API endpoint not found');
        debugPrint('💡 Check: Is the API endpoint correct?');
        debugPrint('💡 Check: Does the visitor exist?');
      } else if (e.toString().contains('500')) {
        debugPrint('🖥️ SERVER ERROR: Internal server error');
        debugPrint('💡 Check: Backend server logs for details');
      } else if (e.toString().contains('FormatException')) {
        debugPrint('📋 FORMAT ERROR: Invalid response format');
        debugPrint('💡 Check: Is the API returning valid JSON?');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting visitor: ${e.toString()}')),
      );
    }

    debugPrint('🏁 ENDING VISITOR REJECTION PROCESS');
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (result != null && result.isNotEmpty) {
      // Process the scanned QR code
      _processScannedQRCode(result);
    }
  }

  void _processScannedQRCode(String qrCode) async {
    debugPrint('🚀 STARTING QR CODE APPROVAL PROCESS');
    debugPrint('📱 QR Code scanned: $qrCode');

    try {
      // Get guard ID from stored data
      debugPrint('🔍 Retrieving guard data for QR approval...');
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      debugPrint(
        '📊 Guard data retrieved: ${guardData != null ? 'SUCCESS' : 'NULL'}',
      );

      final guardId = guardData?['id'] ?? guardData?['_id'];
      debugPrint('🆔 Guard ID extracted: $guardId');

      if (guardId == null) {
        debugPrint('❌ ERROR: Guard ID is null - user not properly logged in');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guard ID not found. Please login again.'),
          ),
        );
        return;
      }

      debugPrint('✅ VALIDATION PASSED - Processing QR code approval');
      debugPrint('🔐 Approving visitor via QR code for guard: $guardId');

      // Call API service with QR data
      debugPrint('🌐 Calling ApiService.approveVisitor with QR data...');
      final result = await ApiService.approveVisitor(
        guardId: guardId,
        qrData: qrCode,
      );

      debugPrint('📡 QR APPROVAL API RESPONSE RECEIVED');
      debugPrint('📊 Response type: ${result.runtimeType}');
      debugPrint('📋 Response keys: ${result.keys.toList()}');
      debugPrint('📱 QR Approval result: $result');

      if (result['success'] == true) {
        debugPrint('✅ QR APPROVAL SUCCESSFUL');
        debugPrint(
          '📝 Success message: ${result['message'] ?? 'Visitor approved successfully via QR code'}',
        );

        // Mark visitor as approved locally to prevent blinking on refresh
        debugPrint(
          '🔄 Marking visitor as approved locally after QR approval...',
        );
        setState(() {
          // For QR approval, we need to find the visitor by QR data or other means
          // Since QR data might contain visitor ID, we'll try to match it
          final visitorIndex = _pendingVisitors.indexWhere((visitor) {
            // Check if QR code matches visitor ID
            return visitor.id == qrCode;
          });
          if (visitorIndex != -1) {
            final updatedVisitor = _pendingVisitors[visitorIndex].copyWith(
              status: VisitorStatus.approved,
            );
            _pendingVisitors[visitorIndex] = updatedVisitor;
            debugPrint(
              '✅ Visitor marked as approved locally after QR scan at index: $visitorIndex',
            );

            // Add to processed visitors set to prevent reappearance
            _processedVisitorIds.add(_pendingVisitors[visitorIndex].id);
            debugPrint(
              '🛡️ Added QR-approved visitor ${_pendingVisitors[visitorIndex].id} to processed set (total: ${_processedVisitorIds.length})',
            );
          } else {
            debugPrint(
              '⚠️ Visitor not found in local list for QR approval marking',
            );
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor approved successfully via QR code!'),
          ),
        );
      } else {
        debugPrint('❌ QR APPROVAL FAILED - API returned success=false');
        debugPrint('📝 Error message: ${result['message'] ?? 'Unknown error'}');
        debugPrint('🔍 Full response: $result');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Invalid QR code or visitor not found',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('💥 CRITICAL ERROR in QR code approval');
      debugPrint('🔥 Exception type: ${e.runtimeType}');
      debugPrint('🔥 Exception message: ${e.toString()}');
      debugPrint('📚 Stack trace: $stackTrace');

      // Detailed error analysis for QR approval
      if (e.toString().contains('SocketException')) {
        debugPrint('🌐 NETWORK ERROR: Cannot connect to server');
        debugPrint('💡 Check: Is the backend server running?');
        debugPrint('💡 Check: Is the device connected to internet?');
      } else if (e.toString().contains('TimeoutException')) {
        debugPrint('⏰ TIMEOUT ERROR: Request took too long');
        debugPrint('💡 Check: Is the server responding slowly?');
        debugPrint('💡 Check: Is there a network connectivity issue?');
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        debugPrint('🔐 AUTHENTICATION ERROR: Invalid or expired token');
        debugPrint('💡 Check: Is the user logged in?');
        debugPrint('💡 Check: Has the session expired?');
      } else if (e.toString().contains('404')) {
        debugPrint(
          '🔍 NOT FOUND ERROR: API endpoint not found or invalid QR code',
        );
        debugPrint('💡 Check: Is the QR code format correct?');
        debugPrint('💡 Check: Has the QR code expired?');
      } else if (e.toString().contains('500')) {
        debugPrint('🖥️ SERVER ERROR: Internal server error');
        debugPrint('💡 Check: Backend server logs for details');
      } else if (e.toString().contains('FormatException')) {
        debugPrint('📋 FORMAT ERROR: Invalid QR code format');
        debugPrint('💡 Check: Is the QR code properly formatted JSON?');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing QR code: ${e.toString()}')),
      );
    }

    debugPrint('🏁 ENDING QR CODE APPROVAL PROCESS');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visitor Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        automaticallyImplyLeading: false, // Remove back arrow
        leading: IconButton(
          icon: const Icon(
            Icons.person_outline_sharp,
            color: Colors.white,
          ), // Hamburger menu (3 horizontal lines) moved to left
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SecurityGuardProfilePage(),
              ),
            );
          },
        ),
        actions: [
          // Socket.IO connection status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _socket?.connected == true
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _socket?.connected == true ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _socket?.connected == true ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: _socket?.connected == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _socket?.connected == true ? '' : '',
                  style: TextStyle(
                    fontSize: 12,
                    color: _socket?.connected == true
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh visitor list',
            onPressed: () {
              debugPrint('🔄 Manual refresh triggered by user');
              _showExpiredVisitors
                  ? _loadExpiredVisitors()
                  : _loadPendingVisitors();
            },
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildVisitorsList() : _buildQRScanPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Visitors'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QR Scan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF455A64),
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildVisitorsList() {
    // Attractive tab-style toggle for pending/expired visitors
    final toggleTabs = Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pending Visitors Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showExpiredVisitors = false;
                  _loadPendingVisitors();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: !_showExpiredVisitors
                      ? const Color(0xFF455A64)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_showExpiredVisitors
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF455A64,
                            ).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: !_showExpiredVisitors
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pending',
                      style: TextStyle(
                        color: !_showExpiredVisitors
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expired Visitors Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showExpiredVisitors = true;
                  _loadExpiredVisitors();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: _showExpiredVisitors
                      ? const Color(0xFF455A64)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _showExpiredVisitors
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF455A64,
                            ).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 20,
                      color: _showExpiredVisitors
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expired',
                      style: TextStyle(
                        color: _showExpiredVisitors
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Show loading indicator only for initial load (no visitors yet)
    if (_isLoadingVisitors && _pendingVisitors.isEmpty) {
      return Column(
        children: [
          toggleTabs,
          Expanded(
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF455A64),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading visitors...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show error message with retry option
    if (_errorMessage != null) {
      return Column(
        children: [
          toggleTabs,
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load visitors',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showExpiredVisitors
                        ? _loadExpiredVisitors
                        : _loadPendingVisitors,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF455A64),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show empty state when no visitors and not loading
    if (_pendingVisitors.isEmpty) {
      return Column(
        children: [
          toggleTabs,
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _showExpiredVisitors
                          ? Icons.history
                          : Icons.people_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _showExpiredVisitors
                        ? 'No expired visitors'
                        : 'No pending visitors',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showExpiredVisitors
                        ? 'All expired visitors have been reviewed'
                        : 'All visitors have been processed',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show visitors list with pull-to-refresh
    return Column(
      children: [
        toggleTabs,
        // Show refresh indicator at the top when refreshing
        if (_isRefreshingVisitors)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.blue.withValues(alpha: 0.1),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF455A64),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Refreshing...',
                  style: TextStyle(
                    color: Color(0xFF455A64),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _showExpiredVisitors
                ? _loadExpiredVisitors
                : _loadPendingVisitors,
            color: const Color(0xFF455A64),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingVisitors.length,
              itemBuilder: (context, index) {
                final visitor = _pendingVisitors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF455A64,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF455A64),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      visitor.displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF455A64),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          visitor.timestamp ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Visitor details in a more attractive layout
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Show progress if available
                                if (visitor.progress != null &&
                                    visitor.progress!.isNotEmpty)
                                  _buildInfoRow('Progress', visitor.progress!),
                                _buildInfoRow('Type', visitor.type ?? 'Other'),
                                // Show assigned gates if available
                                if (visitor.assignedGates != null &&
                                    visitor.assignedGates!.isNotEmpty)
                                  _buildInfoRow(
                                    'Assigned Gates',
                                    visitor.assignedGates!.join(', '),
                                  ),
                                _buildInfoRow(
                                  'Flat',
                                  visitor.flatNumber ?? 'N/A',
                                ),
                              ],
                            ),
                          ),
                          // Status badges - Professional implementation
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Status badge based on visitor status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: visitor.status.badgeColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: visitor.status.badgeColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      visitor.status.icon,
                                      size: 14,
                                      color: visitor.status.badgeColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      visitor.status.displayName,
                                      style: TextStyle(
                                        color: visitor.status.badgeColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Action buttons - Only show for pending visitors
                          if (visitor.status.canBeActedUpon)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showApproveDialog(visitor),
                                      icon: const Icon(Icons.check, size: 18),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _rejectVisitor(visitor.id),
                                      icon: const Icon(Icons.close, size: 18),
                                      label: const Text('Reject'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                        foregroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF455A64),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF455A64).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Color(0xFF455A64),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'QR Code Scanner',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap the QR Scan tab to start scanning visitor QR codes',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Scanner will open automatically when you tap the QR Scan tab',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
