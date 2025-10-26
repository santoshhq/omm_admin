import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'memebers_module.dart';
import 'dart:io';
import 'dart:math';
import '../config/api_config.dart';
import '../services/admin_session_service.dart';

class MemberRegistrationFlow extends StatefulWidget {
  const MemberRegistrationFlow({super.key});

  @override
  State<MemberRegistrationFlow> createState() => _MemberRegistrationFlowState();
}

class _MemberRegistrationFlowState extends State<MemberRegistrationFlow> {
  final _pageController = PageController();
  final MemberRegistrationModel model = MemberRegistrationModel();

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  final _formKeyStep4 = GlobalKey<FormState>();

  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _mobileController = TextEditingController(text: '+91');
  final _emailController = TextEditingController();
  final _flatNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final _userIdController = TextEditingController();
  // Example: hardcoded — later replace this with data from Firebase/your DB

  final ImagePicker _picker = ImagePicker();
  int _currentStep = 0;
  final int totalSteps = 4;

  // Flag to track if userId has been generated once
  bool _userIdGenerated = false;

  // Admin ID - should be passed from previous screen or stored in shared preferences
  String? _adminId;

  // Loading state for submission
  bool _isSubmitting = false;

  // Parking slot logic
  final Map<String, List<String>> parkingSlots = {
    'P1': List.generate(6, (i) => 'P1-${i + 1}'),
    'P2': List.generate(6, (i) => 'P2-${i + 1}'),
  };

  // Track occupied parking slots
  Set<String> _occupiedParkingSlots = <String>{};
  bool _isLoadingParkingData = false;

  // Optimized validation getters that check field values directly
  bool get isStep1Valid {
    // Check field values directly instead of form validation
    final firstNameValid = _firstController.text.trim().isNotEmpty;
    final lastNameValid = _lastController.text.trim().isNotEmpty;
    final mobileValid =
        _mobileController.text.trim().length == 13 &&
        _mobileController.text.trim().startsWith('+91');
    final emailValid =
        _emailController.text.trim().isNotEmpty &&
        RegExp(
          r"^[\w\-.]+@([\w-]+\.)+[\w]{2,4}",
        ).hasMatch(_emailController.text.trim());

    final isValid =
        firstNameValid && lastNameValid && mobileValid && emailValid;
    if (!isValid) {
      print("❌ Step 1 validation failed:");
      print(
        "  - First name: '${_firstController.text.trim()}' (${firstNameValid})",
      );
      print(
        "  - Last name: '${_lastController.text.trim()}' (${lastNameValid})",
      );
      print(
        "  - Mobile: '${_mobileController.text.trim()}' (length: ${_mobileController.text.trim().length}, starts with +91: ${_mobileController.text.trim().startsWith('+91')}) -> ${mobileValid}",
      );
      print("  - Email: '${_emailController.text.trim()}' (${emailValid})");
    }
    return isValid;
  }

  bool get isStep2Valid {
    final flatNoValid = _flatNoController.text.trim().isNotEmpty;
    final floorValid = model.floor != null && model.floor!.isNotEmpty;
    final paymentStatusValid =
        model.paymentStatus != null && model.paymentStatus!.isNotEmpty;
    final parkingAreaValid =
        model.parkingArea != null && model.parkingArea!.isNotEmpty;
    final parkingSlotValid =
        model.parkingSlot != null && model.parkingSlot!.isNotEmpty;

    final isValid =
        flatNoValid &&
        floorValid &&
        paymentStatusValid &&
        parkingAreaValid &&
        parkingSlotValid;
    if (!isValid) {
      print("❌ Step 2 validation failed:");
      print(
        "  - Flat number: '${_flatNoController.text.trim()}' (${flatNoValid})",
      );
      print("  - Floor: '${model.floor}' (${floorValid})");
      print(
        "  - Payment status: '${model.paymentStatus}' (${paymentStatusValid})",
      );
      print("  - Parking area: '${model.parkingArea}' (${parkingAreaValid})");
      print("  - Parking slot: '${model.parkingSlot}' (${parkingSlotValid})");
    }
    return isValid;
  }

  bool get isStep3Valid {
    final govtIdTypeValid =
        model.govtIdType != null && model.govtIdType!.isNotEmpty;
    final govtIdImageValid = model.govtIdImage != null;

    final isValid = govtIdTypeValid && govtIdImageValid;
    if (!isValid) {
      print("❌ Step 3 validation failed:");
      print("  - Govt ID Type: '${model.govtIdType}' (${govtIdTypeValid})");
      print("  - Govt ID Image: '${model.govtIdImage}' (${govtIdImageValid})");
    }
    return isValid;
  }

  bool get isStep4Valid {
    final userIdValid = _userIdController.text.trim().isNotEmpty;
    final passwordValid = _passwordController.text.length >= 6;
    final passwordsMatch =
        _passwordController.text == _rePasswordController.text;

    final isValid = userIdValid && passwordValid && passwordsMatch;
    if (!isValid) {
      print("❌ Step 4 validation failed:");
      print("  - User ID: '${_userIdController.text.trim()}' (${userIdValid})");
      print(
        "  - Password length: ${_passwordController.text.length} (>= 6: ${passwordValid})",
      );
      print(
        "  - Passwords match: '${_passwordController.text}' == '${_rePasswordController.text}' (${passwordsMatch})",
      );
    }
    return isValid;
  }

  @override
  void initState() {
    super.initState();
    _fetchOccupiedParkingSlots();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstController.dispose();
    _lastController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _flatNoController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  // Fetch occupied parking slots from backend
  Future<void> _fetchOccupiedParkingSlots() async {
    setState(() => _isLoadingParkingData = true);

    try {
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin session not found');
      }

      final result = await ApiService.getAdminMembers(adminId);
      if (result['success'] == true) {
        final List<dynamic> membersData = result['data'] ?? [];

        Set<String> occupiedSlots = <String>{};
        for (var memberJson in membersData) {
          final parkingSlot = memberJson['parkingSlot'];
          if (parkingSlot != null &&
              parkingSlot != 'N/A' &&
              parkingSlot != 'Not Assigned' &&
              parkingSlot.toString().isNotEmpty) {
            occupiedSlots.add(parkingSlot.toString());
          }
        }

        setState(() {
          _occupiedParkingSlots = occupiedSlots;
        });

        print('Occupied parking slots: $_occupiedParkingSlots');
      }
    } catch (e) {
      print('Error fetching parking data: $e');
    } finally {
      setState(() => _isLoadingParkingData = false);
    }
  }

  // Build parking slot dropdown items with occupied slot handling
  List<DropdownMenuItem<String>> _buildParkingSlotItems(String parkingArea) {
    List<String> slots = [];

    if (parkingArea == 'N/A') {
      // If N/A area is selected, only show N/A slot
      slots = ['N/A'];
    } else {
      // Get all slots for the area and add N/A option
      List<String> baseSlots = parkingSlots[parkingArea] ?? [];
      slots = [...baseSlots, 'N/A'];
    }

    // Ensure no duplicates
    slots = slots.toSet().toList();

    return slots.map((slot) {
      final isOccupied = _occupiedParkingSlots.contains(slot);
      final isNA = slot == 'N/A';

      return DropdownMenuItem(
        value: slot,
        enabled:
            !isOccupied ||
            isNA, // N/A is always enabled, others depend on occupancy
        child: Row(
          children: [
            Text(
              slot,
              style: TextStyle(
                color: isOccupied && !isNA ? Colors.grey : Colors.black,
                fontWeight: isNA ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isOccupied && !isNA) ...[
              SizedBox(width: 8),
              Icon(Icons.block, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Text(
                '(Occupied)',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  // Get valid parking slot value to prevent dropdown assertion errors
  String? _getValidParkingSlotValue(String parkingArea, String? currentSlot) {
    List<String> availableSlots = [];

    if (parkingArea == 'N/A') {
      availableSlots = ['N/A'];
    } else {
      List<String> baseSlots = parkingSlots[parkingArea] ?? [];
      availableSlots = [...baseSlots, 'N/A'];
    }

    // If current slot is valid, return it, otherwise return null
    if (currentSlot != null && availableSlots.contains(currentSlot)) {
      return currentSlot;
    }

    return null;
  }

  void _nextPage() {
    // Use optimized validation getters
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        isValid = isStep1Valid;
        break;
      case 1:
        isValid = isStep2Valid;
        break;
      case 2:
        isValid = isStep3Valid;
        break;
      case 3:
        isValid = isStep4Valid;
        break;
    }

    if (isValid) {
      // Step 1 values
      if (_currentStep == 0) {
        model.firstName = _firstController.text.trim();
        model.lastName = _lastController.text.trim();
        model.mobile = _mobileController.text.trim();
        model.email = _emailController.text.trim();
      }
      // Step 2 values
      if (_currentStep == 1) {
        model.flatNo = _flatNoController.text.trim();
      }

      if (_currentStep < totalSteps - 1) {
        setState(() => _currentStep++);

        // Auto-generate userId when entering step 4 for the first time
        if (_currentStep == 3 && !_userIdGenerated) {
          final id = _generateUserId();
          setState(() {
            model.userId = id;
            _userIdController.text = id;
            _userIdGenerated = true;
          });
        }

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      }
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  void _submitMember() async {
    print("🚀 Starting member submission process...");

    if (_isSubmitting) {
      print("⚠️ Submission already in progress, ignoring duplicate request");
      return; // Prevent multiple submissions
    }

    // Get admin ID from session service
    _adminId = await AdminSessionService.getAdminId();
    print("👤 Admin ID retrieved: $_adminId");

    if (_adminId == null) {
      print("❌ Admin session expired - no admin ID found");
      _showErrorDialog("Admin session expired. Please login again.");
      return;
    }

    // Update model values from controllers before validation
    print("🔄 Updating model values from controllers...");
    model.firstName = _firstController.text.trim();
    model.lastName = _lastController.text.trim();
    model.mobile = _mobileController.text.trim();
    model.email = _emailController.text.trim();
    model.flatNo = _flatNoController.text.trim();
    model.userId = _userIdController.text.trim();
    model.password = _passwordController.text;

    // Validate all required fields before submission
    print("🔍 Running comprehensive validation...");
    if (!_validateAllSteps()) {
      print("❌ Overall validation failed - checking individual steps:");
      print("  Step 1 valid: $isStep1Valid");
      print("  Step 2 valid: $isStep2Valid");
      print("  Step 3 valid: $isStep3Valid");
      print("  Step 4 valid: $isStep4Valid");
      _showErrorDialog(
        "Please fill all required fields correctly.\n\nValidation failed for one or more steps.",
      );
      return;
    }

    print("✅ All validations passed, proceeding with submission...");

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare data for API
      model.password = _passwordController.text;
      model.userId = _userIdController.text;

      print("🔍 Debug - About to create member:");
      print("  Admin ID: $_adminId");
      print("  User ID: ${model.userId}");
      print("  Name: ${model.firstName} ${model.lastName}");
      print("  Email: ${model.email}");
      print("  Mobile: ${model.mobile}");
      print("  Floor: ${model.floor}, Flat: ${model.flatNo}");
      print("  Parking: ${model.parkingArea}, ${model.parkingSlot}");
      print("  Govt ID Type: ${model.govtIdType}");
      print("  Password length: ${model.password?.length ?? 0}");
      print(
        "  Profile Image: ${model.profileImage != null ? 'Present' : 'Null'}",
      );
      print(
        "  Govt ID Image: ${model.govtIdImage != null ? 'Present' : 'Null'}",
      );

      print("📡 Making API call to adminCreateMember...");

      // Call API to create member
      final result = await ApiService.adminCreateMember(
        adminId: _adminId!,
        userId: model.userId!,
        password: model.password!,
        profileImage: model.profileImage?.toString(),
        firstName: model.firstName!,
        lastName: model.lastName!,
        mobile: model.mobile!,
        email: model.email!,
        floor: model.floor!,
        flatNo: model.flatNo!,
        paymentStatus: model.paymentStatus,
        parkingArea: model.parkingArea!,
        parkingSlot: model.parkingSlot!,
        govtIdType: model.govtIdType!,
        govtIdImage: model.govtIdImage?.toString() ?? "placeholder_image",
      );

      print("📨 API call completed, result received:");
      print("  Success: ${result['success']}");
      print("  Message: ${result['message']}");
      print("  Has data: ${result['data'] != null}");

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      if (result['success'] == true) {
        // Show success dialog
        if (mounted) {
          _showSuccessDialog(
            result['message'] ?? "Member created successfully!",
            result['data'],
          );
        }
      } else {
        // Provide more specific error message
        String errorMessage = result['message'] ?? "Failed to create member";
        if (errorMessage.contains('duplicate') ||
            errorMessage.contains('already exists')) {
          errorMessage =
              "A member with this email or mobile number already exists.";
        } else if (errorMessage.contains('validation')) {
          errorMessage = "Please check all fields and try again.";
        }

        if (mounted) {
          _showErrorDialog("Failed to create member: $errorMessage");
        }
      }
    } catch (e) {
      print("💥 Exception caught during member creation:");
      print("  Exception type: ${e.runtimeType}");
      print("  Exception message: ${e.toString()}");

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }

      // Provide user-friendly error messages
      String userFriendlyMessage =
          "An unexpected error occurred while creating the member.";

      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        userFriendlyMessage =
            "Network error. Please check your internet connection and try again.";
      } else if (e.toString().contains('timeout')) {
        userFriendlyMessage = "Request timed out. Please try again.";
      } else if (e.toString().contains('400')) {
        userFriendlyMessage = "Invalid data provided. Please check all fields.";
      } else if (e.toString().contains('500')) {
        userFriendlyMessage = "Server error. Please try again later.";
      }

      print("📝 Final error message to user: $userFriendlyMessage");

      if (mounted) {
        _showErrorDialog(
          "$userFriendlyMessage\n\nTechnical details: ${e.toString()}",
        );
      }
    }

    print("🏁 Member submission process completed");
  }

  bool _validateAllSteps() {
    return isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("Error"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, Map<String, dynamic>? data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Success"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (data != null) ...[
              SizedBox(height: 16),
              Text(
                "Member Details:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("User ID: ${data['credentials']?['userId'] ?? 'N/A'}"),
              Text("Password: ${data['credentials']?['password'] ?? 'N/A'}"),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  "Member can now login with these credentials",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(
                context,
                model,
              ); // Return to previous screen with created member
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Generates a random unique 6-digit userId
  /// Format: Random number between 100000 and 999999
  /// Uniqueness is ensured by the backend during member creation
  String _generateUserId() {
    final random = Random();
    int userId = 100000 + random.nextInt(900000); // Generates 100000 to 999999
    return userId.toString();
  }

  Future<void> _pickGovtIdImage() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF455A64)),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.file_present, color: Color(0xFF455A64)),
            title: const Text('Documents'),
            onTap: () => Navigator.pop(context, null),
          ),
        ],
      ),
    );

    if (source == ImageSource.camera) {
      final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          model.govtIdImage = MemoryImage(bytes);
        });
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          setState(() {
            model.govtIdImage = MemoryImage(bytes);
          });
        }
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    String? Function(String?)? validator,
    bool readOnly = false,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      validator: validator,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 700;
    final bool isLastStep = _currentStep == totalSteps - 1;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final stepTitles = [
      'Basic Details',
      'Flat Details',
      'Government ID',
      'Login Credentials',
    ];

    // Optimized validation - use the reliable getters
    bool canGoNext;
    switch (_currentStep) {
      case 0:
        canGoNext = isStep1Valid;
        break;
      case 1:
        canGoNext = isStep2Valid;
        break;
      case 2:
        canGoNext = isStep3Valid;
        break;
      case 3:
        canGoNext = isStep4Valid;
        break;
      default:
        canGoNext = false;
    }

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _previousPage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: Text(
            stepTitles[_currentStep],
            style: const TextStyle(
              color: Colors.white, // make text color white
            ),
          ),
          backgroundColor: Color(0xFF455A64),
          iconTheme: const IconThemeData(
            color: Colors.white, // <-- This makes the back arrow white
          ),
        ),

        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: isMobile ? 12 : 24,
            ),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_step1(), _step2(), _step3(), _step4()],
                ),
              ),
            ),
          ),
        ),

        // ✅ put buttons here instead of inside the column
        bottomNavigationBar: isKeyboardVisible
            ? null
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          label: const Text('PREVIOUS'),
                          onPressed: _previousPage,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isLastStep
                              ? Icons.done_outline_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 18,
                        ),
                        label: _isSubmitting && isLastStep
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'CREATING...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                isLastStep ? 'SUBMIT' : 'NEXT STEP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          elevation: 6,
                          backgroundColor: (canGoNext && !_isSubmitting)
                              ? Color(0xFF455A64)
                              : const Color.fromARGB(255, 218, 218, 218),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: (canGoNext && !_isSubmitting)
                            ? () => isLastStep ? _submitMember() : _nextPage()
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ------------------ Steps -------------------
  Widget _step1() {
    return Form(
      key: _formKeyStep1,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: model.profileImage,
                  child: model.profileImage == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () async {
                      final XFile? picked = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      if (picked != null) {
                        setState(() {
                          model.profileImage = FileImage(
                            File(picked.path), // ✅ File is recognized now
                          );
                        });
                      }
                    },
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF455A64),
                      radius: 16,
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _firstController,
            'First Name',
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _lastController,
            'Last Name',
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _mobileController,
            'Mobile Number',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.phone,
            maxLength: 13,
            validator: (v) {
              if (v == null || v.length != 13 || !v.startsWith('+91')) {
                return 'Enter valid number';
              }
              return null;
            },
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _emailController,
            'Email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!RegExp(r"^[\w\-.]+@([\w-]+\.)+[\w]{2,4}").hasMatch(v)) {
                return 'Invalid email';
              }
              return null;
            },
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _step2() {
    return Form(
      key: _formKeyStep2,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildTextField(
                _flatNoController,
                'Flat No',
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Floor selection
              DropdownButtonFormField<String>(
                value: model.floor,
                decoration: const InputDecoration(
                  labelText: 'Floor',
                  border: OutlineInputBorder(),
                ),
                items: ['I', 'II', 'III', 'IV', 'V', 'VI']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => model.floor = v),
                validator: (v) => v == null ? 'Select floor' : null,
              ),
              const SizedBox(height: 12),

              // ✅ New Payment Status dropdown
              DropdownButtonFormField<String>(
                value: model.paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select Status'),
                items: ['Booked', 'Pending', 'Available']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => model.paymentStatus = v),
                validator: (v) => v == null ? 'Select status' : null,
              ),
              const SizedBox(height: 12),

              // Parking Area
              DropdownButtonFormField<String>(
                value: model.parkingArea,
                decoration: const InputDecoration(
                  labelText: 'Parking Area *',
                  border: OutlineInputBorder(),
                ),
                items: ['P1', 'P2', 'N/A']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    model.parkingArea = v;
                    // Reset parking slot first
                    model.parkingSlot = null;
                  });

                  // Use post frame callback to ensure the widget rebuilds properly
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && v == 'N/A') {
                      setState(() {
                        model.parkingSlot = 'N/A';
                      });
                    }
                  });
                },
                validator: (v) =>
                    v == null ? 'Please select parking area' : null,
              ),

              const SizedBox(height: 12),

              // Parking Slot (depends on area)
              if (model.parkingArea != null)
                DropdownButtonFormField<String>(
                  value: _getValidParkingSlotValue(
                    model.parkingArea!,
                    model.parkingSlot,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Parking Slot *',
                    border: OutlineInputBorder(),
                  ),
                  items: _buildParkingSlotItems(model.parkingArea!),
                  onChanged: (v) => setState(() => model.parkingSlot = v),
                  validator: (v) =>
                      v == null ? 'Please select parking slot' : null,
                ),
            ],
          ),
          // Loading overlay for parking data
          if (_isLoadingParkingData)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading parking data...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _step3() {
    return Form(
      key: _formKeyStep3,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          DropdownButtonFormField<String>(
            value: model.govtIdType,
            decoration: const InputDecoration(
              labelText: 'Govt ID Type',
              border: OutlineInputBorder(),
            ),
            items: [
              'AadharCard',
              'PanCard',
              'VoterID',
              'Passport',
              'DrivingLicense',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => model.govtIdType = v),
            validator: (v) => v == null ? 'Select Govt ID type' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Govt ID'),
            style: ElevatedButton.styleFrom(
              backgroundColor: model.govtIdType != null
                  ? Color(0xFF455A64)
                  : Colors.grey,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
            ),
            onPressed: model.govtIdType != null ? _pickGovtIdImage : null,
          ),
          if (model.govtIdImage != null) ...[
            const SizedBox(height: 16),
            Image(image: model.govtIdImage!, height: 350, fit: BoxFit.cover),
          ],
        ],
      ),
    );
  }

  Widget _step4() {
    // Fallback: Ensure userId is generated if somehow missing
    if (!_userIdGenerated &&
        (_userIdController.text.isEmpty || model.userId?.isEmpty == true)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final id = _generateUserId();
        setState(() {
          model.userId = id;
          _userIdController.text = id;
          _userIdGenerated = true;
        });
      });
    }

    return Form(
      key: _formKeyStep4,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Frozen User ID field (no edit button)
          _buildTextField(
            _userIdController,
            'User ID (Auto-generated)',
            readOnly: true,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'User ID is required' : null,
          ),
          const SizedBox(height: 8),

          // Regenerate User ID button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final id = _generateUserId();
                setState(() {
                  model.userId = id;
                  _userIdController.text = id;
                  _userIdGenerated = true;
                });
              },
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              label: const Text(
                'Regenerate ID',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Info text to explain the userId format
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Text(
              'User ID Format: [Floor][Flat][Sum]\n'
              '• Example: Floor II + Flat 101 = "210103" (2+1=03)\n'
              '• Example: Floor 1 + Flat 11 = "101102" (1+1=02)\n'
              '• Last 2 digits = Sum of (floor + first flat digit)',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 16),

          // Email display for password reset functionality
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recovery Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  model.email ?? 'No email provided',
                  style: TextStyle(
                    fontSize: 14,
                    color: model.hasValidRecoveryEmail
                        ? Colors.green.shade800
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      model.hasValidRecoveryEmail
                          ? Icons.check_circle
                          : Icons.warning,
                      size: 14,
                      color: model.hasValidRecoveryEmail
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        model.hasValidRecoveryEmail
                            ? 'Ready for password reset functionality'
                            : model.recoveryEmailStatus,
                        style: TextStyle(
                          fontSize: 11,
                          color: model.hasValidRecoveryEmail
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildTextField(
            _passwordController,
            'Password',
            obscure: true,
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 chars' : null,
            onChanged: (_) => setState(() {}), // ✅ triggers re-evaluation
          ),
          const SizedBox(height: 12),
          _buildTextField(
            _rePasswordController,
            'Re-enter Password',
            obscure: true,
            validator: (v) =>
                v != _passwordController.text ? 'Passwords do not match' : null,
            onChanged: (_) => setState(() {}), // ✅ triggers re-evaluation
          ),
        ],
      ),
    );
  }

  // ✅ Optimized logic for "Next/Submit" button
  bool get canGoNext {
    switch (_currentStep) {
      case 0:
        return isStep1Valid;
      case 1:
        return isStep2Valid;
      case 2:
        return isStep3Valid;
      case 3:
        return isStep4Valid;
      default:
        return false;
    }
  }
}

// Assuming you already have MemberRegistrationModel defined
// and ViewIdCard widget for displaying a single member card

/// =========================
// File: lib/user_management/widgets/user_registration_widgets.dart
// =========================
