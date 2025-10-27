import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:omm_admin/services/security_guard_auth_service.dart';
import 'package:omm_admin/security_guards/security_guard_profile.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SecurityGuardLoginPage extends StatefulWidget {
  const SecurityGuardLoginPage({Key? key}) : super(key: key);

  @override
  State<SecurityGuardLoginPage> createState() => _SecurityGuardLoginPageState();
}

class _SecurityGuardLoginPageState extends State<SecurityGuardLoginPage> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSecurityLogin() async {
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (mobile.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter mobile number and password"),
        ),
      );
      return;
    }

    // Basic mobile number validation
    if (mobile.length != 10 || !RegExp(r'^\d{10}$').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit mobile number"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await SecurityGuardAuthService.login(
        mobile,
        password,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        print('✅ Login successful, showing snackbar');
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            duration: Duration(seconds: 2),
          ),
        );

        print('⏳ Waiting for SharedPreferences to save...');
        // Small delay to ensure SharedPreferences is saved
        await Future.delayed(const Duration(milliseconds: 1000));

        print('🚀 Starting navigation to VisitorApprovalPage...');
        // Navigate to visitor approval page
        if (mounted) {
          try {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) {
                  try {
                    print('🏗️ Creating VisitorApprovalPage...');
                    return const VisitorApprovalPage();
                  } catch (e) {
                    print('❌ Error creating VisitorApprovalPage: $e');
                    throw e;
                  }
                },
              ),
            );
            print('✅ Navigation pushReplacement completed successfully');
          } catch (e) {
            print('❌ Navigation failed with error: $e');
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Navigation failed: $e')));
            }
          }
        } else {
          print('❌ Widget not mounted, cannot navigate');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? "Login failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Security Guard Login',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Security Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF455A64).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  size: 80,
                  color: Color(0xFF455A64),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Security Login",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your mobile number & password",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Mobile Number field
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone),
                  hintText: "Mobile Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: "Password",
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Remember Me checkbox
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    activeColor: const Color(0xFF455A64),
                  ),
                  const Text(
                    "Remember me for 30 days",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF455A64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _handleSecurityLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Back to Admin Login
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Back to Admin Login",
                  style: TextStyle(color: Color(0xFF455A64), fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  List<Map<String, dynamic>> _pendingVisitors = [];
  bool _isLoadingVisitors = true;
  String? _errorMessage;

  IO.Socket? _socket; // Socket.IO client

  @override
  void initState() {
    super.initState();
    print('🏗️ VisitorApprovalPage initState called');

    try {
      WidgetsBinding.instance.addObserver(this);
      _checkSessionStatus();
      _loadPendingVisitors();
      _initializeSocketConnection(); // Initialize Socket.IO connection
    } catch (e) {
      print('❌ Error in VisitorApprovalPage initState: $e');
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

            _socket = IO.io(origin, <String, dynamic>{
              'transports': ['websocket', 'polling'],
              'autoConnect': true,
              'forceNew': true,
              'timeout': 5000,
              // Add JWT token for authentication if available
              if (token != null) 'query': {'token': token},
              // If server uses a custom path: 'path': '/socket.io',
            });

            // Use generic on(...) handlers
            _socket!.on('connect', (_) {
              debugPrint('✅ Socket.IO connected: ${_socket!.id}');
              _joinGuardRoom(); // join after connect
            });

            _socket!.on('connect_error', (data) {
              debugPrint('🔥 Socket.IO connect_error: $data');
            });

            _socket!.on('disconnect', (reason) {
              debugPrint('❌ Socket.IO disconnected: $reason');
            });

            _socket!.on('reconnect', (attempt) {
              debugPrint('🔄 Socket.IO reconnected, attempt: $attempt');
              _joinGuardRoom();
            });

            // Subscribe to server events (ensure names match server)
            _socket!.on('visitorAdded', (data) {
              debugPrint('🆕 visitorAdded: $data');
              if (mounted) {
                _loadPendingVisitors();
                _showNewVisitorNotification(data);
              }
            });

            _socket!.on('visitorUpdated', (data) {
              debugPrint('🔄 visitorUpdated: $data');
              if (mounted) _loadPendingVisitors();
            });

            _socket!.on('visitorRemoved', (data) {
              debugPrint('🗑️ visitorRemoved: $data');
              if (mounted) _loadPendingVisitors();
            });

            // Connect (if autoConnect=false, call connect(); leaving it is okay)
            _socket!.connect();
          })
          .catchError((error) {
            debugPrint('❌ Error getting auth token for Socket.IO: $error');
            // Connect without token if token retrieval fails
            _socket = IO.io(origin, <String, dynamic>{
              'transports': ['websocket', 'polling'],
              'autoConnect': true,
              'forceNew': true,
              'timeout': 5000,
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

    _socket!.on('connect', (_) {
      debugPrint('✅ Socket.IO connected: ${_socket!.id}');
      _joinGuardRoom();
    });

    _socket!.on('connect_error', (data) {
      debugPrint('🔥 Socket.IO connect_error: $data');
    });

    _socket!.on('disconnect', (reason) {
      debugPrint('❌ Socket.IO disconnected: $reason');
    });

    _socket!.on('reconnect', (attempt) {
      debugPrint('🔄 Socket.IO reconnected, attempt: $attempt');
      _joinGuardRoom();
    });

    _socket!.on('visitorAdded', (data) {
      debugPrint('🆕 visitorAdded: $data');
      if (mounted) {
        _loadPendingVisitors();
        _showNewVisitorNotification(data);
      }
    });

    _socket!.on('visitorUpdated', (data) {
      debugPrint('🔄 visitorUpdated: $data');
      if (mounted) _loadPendingVisitors();
    });

    _socket!.on('visitorRemoved', (data) {
      debugPrint('🗑️ visitorRemoved: $data');
      if (mounted) _loadPendingVisitors();
    });
  }

  void _joinGuardRoom() async {
    try {
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      if (guardData != null) {
        final guardId = guardData['_id'] ?? guardData['id'];
        if (guardId == null) {
          debugPrint('Guard ID missing from guardData: $guardData');
          return;
        }
        if (_socket != null && _socket!.connected) {
          _socket!.emit('joinGuardRoom', guardId);
          debugPrint('🏢 Joined guard room: guard_$guardId');
        }
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
    debugPrint('� STARTING _loadPendingVisitors()');
    try {
      setState(() {
        _isLoadingVisitors = true;
        _errorMessage = null;
      });

      // Get guard ID from stored data
      debugPrint('🔍 Getting logged in guard data...');
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      debugPrint('🔍 Guard data retrieved: $guardData');

      if (guardData == null) {
        debugPrint('❌ Guard data is null - user not properly logged in');
        if (mounted) {
          setState(() {
            _errorMessage = 'Login session not found. Please login again.';
            _isLoadingVisitors = false;
          });
        }
        return; // Exit early without throwing
      }

      final guardId = guardData['id'] ?? guardData['_id'];
      debugPrint(
        '🔍 Guard ID extracted: $guardId (type: ${guardId?.runtimeType})',
      );

      if (guardId == null) {
        debugPrint('❌ Guard ID is null');
        if (mounted) {
          setState(() {
            _errorMessage = 'Guard ID not found. Please login again.';
            _isLoadingVisitors = false;
          });
        }
        return; // Exit early without throwing
      }

      debugPrint(
        '📡 Calling ApiService.getPendingVisitors with guardId: $guardId',
      );
      final result = await ApiService.getPendingVisitors(guardId: guardId);

      debugPrint('📨 RAW API RESPONSE: $result');
      debugPrint('📊 Response type: ${result.runtimeType}');
      debugPrint('📊 Response keys: ${result.keys.toList()}');

      if (result['success'] != true) {
        debugPrint('❌ API returned success=false or missing success field');
        debugPrint('❌ Response message: ${result['message']}');
        // Don't throw exception, just show error message
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load visitors.';
            _isLoadingVisitors = false;
          });
        }
        return; // Exit early without throwing
      }

      debugPrint('✅ API returned success=true, processing data...');
      final data = result['data'];
      debugPrint('📦 Data field: $data (type: ${data?.runtimeType})');

      if (data == null) {
        debugPrint('⚠️ Data field is null');
        if (mounted) {
          setState(() {
            _pendingVisitors = [];
            _isLoadingVisitors = false;
          });
        }
        return;
      }

      if (data is! List) {
        debugPrint('❌ Data field is not a List, it\'s a ${data.runtimeType}');
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid response format from server.';
            _isLoadingVisitors = false;
          });
        }
        return;
      }

      debugPrint('📋 Processing ${data.length} visitor records...');

      if (mounted) {
        setState(() {
          // The backend response structure matches what we expect
          // result['data'] contains the array of visitors
          // result['count'] contains the total count
          // result['guard'] contains guard information
          _pendingVisitors = List<Map<String, dynamic>>.from(
            data.map((visitor) {
              debugPrint(
                '👤 Processing visitor: ${visitor['_id'] ?? visitor['id']}',
              );
              // Cast visitor to Map<String, dynamic> to avoid type errors
              final visitorMap = visitor as Map<String, dynamic>;

              // The backend already provides displayName, progress, type, assignedGates
              // So we can use them directly, but let's ensure proper mapping
              String displayName =
                  visitorMap['displayName'] ?? 'Unknown Visitor';
              String progress = visitorMap['progress'] ?? '';
              String type =
                  visitorMap['type'] ??
                  visitorMap['preApprovalType'] ??
                  'other';

              // For backward compatibility, also set the old field names
              final processedVisitor = {
                'id': visitorMap['_id'] ?? visitorMap['id'],
                'name': displayName, // Use the backend's displayName
                'mobile': 'N/A', // Backend doesn't provide mobile for all types
                'purpose': displayName, // Use displayName as purpose
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
                'displayName': displayName, // Keep backend's displayName
                'progress': progress, // Keep backend's progress
                'assignedGates':
                    visitorMap['assignedGates'] ?? visitorMap['gateId'],
                // Keep original data for reference
                ...visitorMap,
              };

              debugPrint(
                '✅ Processed visitor: ${processedVisitor['id']} - ${processedVisitor['displayName']}',
              );
              return processedVisitor;
            }).toList(),
          );
          _isLoadingVisitors = false;
          debugPrint(
            '🎉 Successfully loaded ${_pendingVisitors.length} visitors',
          );
          debugPrint(
            '📝 Visitor IDs: ${_pendingVisitors.map((v) => v['id']).toList()}',
          );
        });
      }
    } catch (e, stackTrace) {
      debugPrint('💥 EXCEPTION in _loadPendingVisitors: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoadingVisitors = false;
        });
      }
    }
    debugPrint('🏁 ENDING _loadPendingVisitors()');
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionStatus();
    }
  }

  Future<void> _checkSessionStatus() async {
    print('🔍 Checking session status...');
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

  Future<bool> _onWillPop() async {
    // Show security warning when user tries to go back
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Security Alert'),
          content: const Text(
            'You are in a secure session. To exit the security guard panel, please use the logout button.\n\n'
            'This prevents unauthorized access and ensures proper session management.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Stay
              child: const Text('Stay Logged In'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Logout
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Logout Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _performLogout();
    }

    // Always return false to prevent back navigation
    return false;
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

  Future<void> _showApproveDialog(Map<String, dynamic> visitor) async {
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                                  visitor['displayName'] ??
                                      visitor['name'] ??
                                      'Unknown Visitor',
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
                          if (visitor['progress'] != null &&
                              visitor['progress'].isNotEmpty)
                            Text('Progress: ${visitor['progress']}'),
                          // Show type
                          Text(
                            'Type: ${visitor['type'] ?? visitor['preApprovalType'] ?? 'Other'}',
                          ),
                          // Show assigned gates if available
                          if (visitor['assignedGates'] != null &&
                              visitor['assignedGates'] is List &&
                              visitor['assignedGates'].isNotEmpty)
                            Text(
                              'Assigned Gates: ${visitor['assignedGates'].join(', ')}',
                            ),
                          Text('Flat: ${visitor['flatNumber'] ?? 'N/A'}'),
                          Text('Time: ${visitor['timestamp'] ?? 'N/A'}'),
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
                          final visitorOtpCode = visitor['otpCode']?.toString();
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
                            await _approveVisitor(
                              visitor['id'] ?? visitor['_id'],
                              otpCode: code,
                            );
                            if (mounted) {
                              Navigator.of(context).pop(); // Close dialog
                            }
                          } catch (e) {
                            if (mounted) {
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
    try {
      // Get guard ID from stored data
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      final guardId = guardData?['_id'] ?? guardData?['id']; // Prioritize _id

      if (guardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guard ID not found. Please login again.'),
          ),
        );
        return;
      }

      // Validate OTP code is provided
      if (otpCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP code is required for approval.')),
        );
        return;
      }

      print(
        '🔐 Approving visitor: $visitorId with OTP: $otpCode for guard: $guardId',
      );

      final result = await ApiService.approveVisitor(
        guardId: guardId,
        visitorId: visitorId,
        otpCode: otpCode,
      );

      print('📱 Approval result: $result');

      if (result['success'] == true) {
        // Remove from local list and refresh
        setState(() {
          _pendingVisitors.removeWhere(
            (visitor) =>
                visitor['id'] == visitorId || visitor['_id'] == visitorId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Visitor approved successfully'),
          ),
        );

        // Refresh the list
        await _loadPendingVisitors();
      } else {
        print('❌ Approval failed: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to approve visitor'),
          ),
        );
      }
    } catch (e) {
      print('🔥 Error in _approveVisitor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving visitor: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectVisitor(String visitorId) async {
    try {
      // Get guard ID from stored data
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      final guardId = guardData?['id'] ?? guardData?['_id'];

      if (guardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guard ID not found. Please login again.'),
          ),
        );
        return;
      }

      final result = await ApiService.rejectVisitor(
        visitorId: visitorId,
        mobileNumber:
            guardId, // Use guardId as mobileNumber for backward compatibility
        password: 'dummy', // Not used in new API
      );

      if (result['success'] == true) {
        // Remove from local list and refresh
        setState(() {
          _pendingVisitors.removeWhere(
            (visitor) =>
                visitor['id'] == visitorId || visitor['_id'] == visitorId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor rejected successfully')),
        );

        // Refresh the list
        await _loadPendingVisitors();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to reject visitor'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting visitor: ${e.toString()}')),
      );
    }
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
    try {
      // Get guard ID from stored data
      final guardData = await SecurityGuardAuthService.getLoggedInGuardData();
      final guardId = guardData?['id'] ?? guardData?['_id'];

      if (guardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guard ID not found. Please login again.'),
          ),
        );
        return;
      }

      // For QR code scanning, we directly approve using qrData
      final result = await ApiService.approveVisitor(
        guardId: guardId,
        qrData: qrCode,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visitor approved successfully via QR code!'),
          ),
        );

        // Refresh the list
        await _loadPendingVisitors();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Invalid QR code or visitor not found',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing QR code: ${e.toString()}')),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to logout from the security guard panel?\n\n'
            'This will end your current session and return you to the login screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _performLogout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
              Icons.menu,
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
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
        body: _selectedIndex == 0 ? _buildVisitorsList() : _buildQRScanPage(),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Visitors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'QR Scan',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF455A64),
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildVisitorsList() {
    // Show loading indicator
    if (_isLoadingVisitors) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF455A64)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading visitors...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show error message with retry option
    if (_errorMessage != null) {
      return Center(
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
              onPressed: _loadPendingVisitors,
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
      );
    }

    // Show empty state when no visitors and not loading
    if (_pendingVisitors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No pending visitors',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'All visitors have been processed',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show visitors list with pull-to-refresh
    return RefreshIndicator(
      onRefresh: _loadPendingVisitors,
      color: const Color(0xFF455A64),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingVisitors.length,
        itemBuilder: (context, index) {
          final visitor = _pendingVisitors[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xFF455A64),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          visitor['displayName'] ??
                              visitor['name'] ??
                              'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Show progress if available
                  if (visitor['progress'] != null &&
                      visitor['progress'].isNotEmpty)
                    Text('Progress: ${visitor['progress']}'),
                  // Show type
                  Text(
                    'Type: ${visitor['type'] ?? visitor['preApprovalType'] ?? 'Other'}',
                  ),
                  // Show assigned gates if available
                  if (visitor['assignedGates'] != null &&
                      visitor['assignedGates'] is List &&
                      visitor['assignedGates'].isNotEmpty)
                    Text(
                      'Assigned Gates: ${visitor['assignedGates'].join(', ')}',
                    ),
                  Text('Flat: ${visitor['flatNumber'] ?? 'N/A'}'),
                  Text('Time: ${visitor['timestamp'] ?? 'N/A'}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showApproveDialog(visitor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _rejectVisitor(visitor['id'] ?? visitor['_id']),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
              color: const Color(0xFF455A64).withOpacity(0.1),
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

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Allow going back to visitor management page
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Scan QR Code',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF455A64),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 2,
          actions: [
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: () => cameraController.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(Icons.camera_rear, color: Colors.white),
              onPressed: () => cameraController.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                if (!_isScanning) return;

                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() => _isScanning = false);

                  final String code = barcodes.first.rawValue!;
                  debugPrint('QR Code scanned: $code');

                  // Return the scanned code to the previous page
                  Navigator.of(context).pop(code);
                }
              },
            ),
            // Overlay with scan area
            Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: const Color(0xFF455A64),
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: MediaQuery.of(context).size.width * 0.8,
                ),
              ),
            ),
            // Instructions
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Scan Visitor QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Position the QR code within the frame to scan',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.borderRadius = 0,
    this.borderLength = 20,
    required this.cutOutSize,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    path.fillType = PathFillType.evenOdd;
    path.addRect(rect);

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    path.addRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
    );

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    canvas.drawRect(rect, backgroundPaint);

    // Draw the cut-out area (transparent)
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      Paint()..blendMode = BlendMode.clear,
    );

    // Draw border corners
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.square;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderRadius, cutOutRect.top)
        ..lineTo(cutOutRect.left + borderRadius + borderLength, cutOutRect.top)
        ..moveTo(cutOutRect.left, cutOutRect.top + borderRadius)
        ..lineTo(cutOutRect.left, cutOutRect.top + borderRadius + borderLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right - borderRadius - borderLength, cutOutRect.top)
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.top)
        ..moveTo(cutOutRect.right, cutOutRect.top + borderRadius)
        ..lineTo(
          cutOutRect.right,
          cutOutRect.top + borderRadius + borderLength,
        ),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left + borderRadius, cutOutRect.bottom)
        ..lineTo(
          cutOutRect.left + borderRadius + borderLength,
          cutOutRect.bottom,
        )
        ..moveTo(
          cutOutRect.left,
          cutOutRect.bottom - borderRadius - borderLength,
        )
        ..lineTo(cutOutRect.left, cutOutRect.bottom - borderRadius),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(
          cutOutRect.right - borderRadius - borderLength,
          cutOutRect.bottom,
        )
        ..lineTo(cutOutRect.right - borderRadius, cutOutRect.bottom)
        ..moveTo(
          cutOutRect.right,
          cutOutRect.bottom - borderRadius - borderLength,
        )
        ..lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius),
      cornerPaint,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QrScannerOverlayShape &&
          runtimeType == other.runtimeType &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          borderLength == other.borderLength &&
          cutOutSize == other.cutOutSize;

  @override
  int get hashCode =>
      borderColor.hashCode ^
      borderWidth.hashCode ^
      borderRadius.hashCode ^
      borderLength.hashCode ^
      cutOutSize.hashCode;

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }

  @override
  String toString() =>
      'QrScannerOverlayShape(borderColor: $borderColor, borderWidth: $borderWidth, borderRadius: $borderRadius, borderLength: $borderLength, cutOutSize: $cutOutSize)';
}
