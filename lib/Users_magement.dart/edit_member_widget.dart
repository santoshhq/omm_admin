import 'package:flutter/material.dart';
import 'package:omm_admin/Users_magement.dart/memebers_module.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:omm_admin/services/admin_session_service.dart';

class EditMemberWidget extends StatefulWidget {
  final MemberRegistrationModel member;

  const EditMemberWidget({super.key, required this.member});

  @override
  State<EditMemberWidget> createState() => _EditMemberWidgetState();
}

class _EditMemberWidgetState extends State<EditMemberWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _flatNoController;

  String? _selectedFloor;
  String? _selectedPaymentStatus;
  String? _selectedParkingArea;
  String? _selectedParkingSlot;
  String? _selectedGovtIdType;

  bool _isLoading = false;

  // Track occupied parking slots
  Set<String> _occupiedParkingSlots = <String>{};
  bool _isLoadingParkingData = false;

  final List<String> _floors = ['I', 'II', 'III', 'IV', 'V', 'VI'];
  final List<String> _paymentStatuses = ['Available', 'Booked', 'Pending'];
  final List<String> _parkingAreas = ['P1', 'P2', 'N/A'];
  final List<String> _govtIdTypes = [
    'AadharCard',
    'PanCard',
    'DrivingLicense',
    'VoterID',
  ];

  // Method to get parking slots based on selected area (including occupied slots)
  List<String> _getParkingSlots(String? parkingArea) {
    List<String> allSlots;
    switch (parkingArea) {
      case 'P1':
        allSlots = ['P1-1', 'P1-2', 'P1-3', 'P1-4', 'P1-5', 'P1-6'];
        break;
      case 'P2':
        allSlots = ['P2-1', 'P2-2', 'P2-3', 'P2-4', 'P2-5', 'P2-6'];
        break;
      case 'N/A':
        return ['N/A'];
      default:
        return ['N/A'];
    }

    // Return all slots (occupied ones will be handled in the dropdown display)
    return allSlots;
  }

  // Build parking slot dropdown items with occupied slots marked
  List<DropdownMenuItem<String>> _buildParkingSlotItems(String? parkingArea) {
    List<String> slots = _getParkingSlots(parkingArea);

    return slots
        .map((slot) {
          bool isOccupied =
              _occupiedParkingSlots.contains(slot) && slot != 'N/A';

          return DropdownMenuItem<String>(
            value: isOccupied ? null : slot, // Disable occupied slots
            enabled: !isOccupied,
            child: Row(
              children: [
                Text(
                  slot,
                  style: TextStyle(
                    color: isOccupied ? Colors.grey : Colors.black,
                    fontWeight: isOccupied
                        ? FontWeight.normal
                        : FontWeight.normal,
                  ),
                ),
                if (isOccupied) ...[
                  SizedBox(width: 8),
                  Icon(Icons.lock, size: 16, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    '(Occupied)',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        })
        .where((item) => item.value != null)
        .toList(); // Filter out disabled items
  }

  // Build custom parking slot dropdown with occupied slots handling
  Widget _buildParkingSlotDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedParkingSlot,
          decoration: InputDecoration(
            labelText: 'Parking Slot',
            prefixIcon: Icon(Icons.garage, color: Color(0xFF455A64)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF455A64), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          items: _buildParkingSlotItems(_selectedParkingArea),
          onChanged: (value) {
            setState(() {
              _selectedParkingSlot = value;
            });
          },
          validator: (value) {
            if (_selectedParkingArea != null &&
                _selectedParkingArea != 'N/A' &&
                (value == null || value.isEmpty)) {
              return 'Please select a parking slot';
            }
            return null;
          },
        ),
        if (_isLoadingParkingData)
          Positioned(
            right: 45,
            top: 15,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF455A64),
              ),
            ),
          ),
      ],
    );
  }

  // Normalize parking values from backend to match dropdown options
  String? _normalizeParkingValue(String? value) {
    if (value == null || value.isEmpty) return null;

    // Convert different variations to our standard format
    switch (value.toLowerCase().trim()) {
      case 'n/a':
      case 'na':
      case 'not assigned':
      case 'not_assigned':
        return 'N/A';
      case 'p1':
      case 'P1':
        return 'P1';
      case 'p2':
      case 'P2':
        return 'P2';
      default:
        // For parking slots, return as-is if it matches expected pattern
        if (value.startsWith('P1-') || value.startsWith('P2-')) {
          return value;
        }
        // If it doesn't match any known pattern, return null
        return null;
    }
  }

  // Strip +91 prefix from mobile number for display
  String _normalizeMobileForDisplay(String? mobile) {
    if (mobile == null || mobile.isEmpty) return '';

    // Remove +91, 91, or any other prefixes, spaces, dashes
    String cleaned = mobile.replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    ); // Remove spaces, dashes, parentheses

    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }

    return cleaned;
  }

  // Add +91 prefix to mobile number when saving
  String _normalizeMobileForSaving(String mobile) {
    if (mobile.isEmpty) return mobile;

    // Remove any existing prefixes and formatting
    String cleaned = mobile.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+91')) {
      return cleaned; // Already has +91
    } else if (cleaned.startsWith('91') && cleaned.length > 10) {
      return '+$cleaned'; // Add + to existing 91
    } else if (cleaned.length == 10) {
      return '+91$cleaned'; // Add full +91 prefix
    }

    return mobile; // Return as-is if format is unclear
  } // Fetch occupied parking slots from backend

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
          // Skip the current member being edited
          if (memberJson['_id'] == widget.member.id) {
            continue;
          }

          final parkingSlot = memberJson['parkingSlot'];
          if (parkingSlot != null &&
              parkingSlot != 'N/A' &&
              parkingSlot != 'N/A' &&
              parkingSlot != 'Not Assigned' &&
              parkingSlot.toString().isNotEmpty) {
            occupiedSlots.add(parkingSlot.toString());
          }
        }

        setState(() {
          _occupiedParkingSlots = occupiedSlots;
        });

        print(
          'Occupied parking slots (excluding current member): $_occupiedParkingSlots',
        );
      }
    } catch (e) {
      print('Error fetching parking data: $e');
    } finally {
      setState(() => _isLoadingParkingData = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchOccupiedParkingSlots(); // Fetch occupied parking slots on page load
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(
      text: widget.member.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.member.lastName ?? '',
    );
    _mobileController = TextEditingController(
      text: _normalizeMobileForDisplay(widget.member.mobile),
    );
    _emailController = TextEditingController(text: widget.member.email ?? '');
    _flatNoController = TextEditingController(text: widget.member.flatNo ?? '');

    _selectedFloor = widget.member.floor;
    _selectedPaymentStatus = widget.member.paymentStatus;
    // Normalize parking area values from backend
    _selectedParkingArea = _normalizeParkingValue(widget.member.parkingArea);
    _selectedGovtIdType = widget.member.govtIdType;

    // Validate and set parking slot based on parking area
    _selectedParkingSlot = _normalizeParkingValue(widget.member.parkingSlot);
    if (_selectedParkingArea != null) {
      List<String> validSlots = _getParkingSlots(_selectedParkingArea);
      if (_selectedParkingSlot != null &&
          !validSlots.contains(_selectedParkingSlot)) {
        _selectedParkingSlot = null; // Reset if invalid
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _flatNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Edit Member',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF455A64),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateMember,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF455A64)),
                  SizedBox(height: 16),
                  Text(
                    'Updating member...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Card
                    _buildSectionCard(
                      title: 'Personal Information',
                      icon: Icons.person,
                      children: [
                        _buildTextFormField(
                          controller: _firstNameController,
                          label: 'First Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _mobileController,
                          label: 'Mobile Number (10 digits)',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          helperText: '+91 will be added automatically',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Mobile number is required';
                            }
                            if (value.length != 10) {
                              return 'Mobile number must be 10 digits';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Mobile number must contain only digits';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Residence Information Card
                    _buildSectionCard(
                      title: 'Residence Information',
                      icon: Icons.home,
                      children: [
                        _buildDropdownField(
                          value: _selectedFloor,
                          label: 'Floor',
                          icon: Icons.layers,
                          items: _floors,
                          onChanged: (value) {
                            setState(() {
                              _selectedFloor = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Floor is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTextFormField(
                          controller: _flatNoController,
                          label: 'Flat Number',
                          icon: Icons.door_front_door,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Flat number is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        _buildDropdownField(
                          value: _selectedPaymentStatus,
                          label: 'Payment Status',
                          icon: Icons.payment,
                          items: _paymentStatuses,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentStatus = value;
                            });
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Parking Information Card
                    _buildSectionCard(
                      title: 'Parking Information (Optional)',
                      icon: Icons.local_parking,
                      children: [
                        _buildDropdownField(
                          value: _selectedParkingArea,
                          label: 'Parking Area',
                          icon: Icons.location_on,
                          items: _parkingAreas,
                          onChanged: (value) {
                            setState(() {
                              _selectedParkingArea = value;
                              // If N/A is selected in parking area, auto-select N/A for parking slot
                              if (value == 'N/A') {
                                _selectedParkingSlot = 'N/A';
                              } else {
                                // Reset slot when area changes and validate if current slot is valid
                                List<String> newSlots = _getParkingSlots(value);
                                if (_selectedParkingSlot == null ||
                                    !newSlots.contains(_selectedParkingSlot)) {
                                  _selectedParkingSlot = null;
                                }
                              }
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        _buildParkingSlotDropdown(),
                        if (_selectedParkingArea != null &&
                            _selectedParkingArea != 'N/A' &&
                            _occupiedParkingSlots.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Occupied slots: ${_occupiedParkingSlots.where((slot) => slot.startsWith(_selectedParkingArea!)).join(', ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Government ID Information Card
                    _buildSectionCard(
                      title: 'Government ID Information',
                      icon: Icons.badge,
                      children: [
                        _buildDropdownField(
                          value: _selectedGovtIdType,
                          label: 'Government ID Type',
                          icon: Icons.credit_card,
                          items: _govtIdTypes,
                          onChanged: (value) {
                            setState(() {
                              _selectedGovtIdType = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Government ID type is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF607D8B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Color(0xFF455A64), size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: Color(0xFF455A64)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF455A64), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF455A64)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF455A64), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _updateMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? adminId = await AdminSessionService.getAdminId();

      if (adminId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (widget.member.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Member ID not found. Cannot update member.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create updated member object
      final updatedMember = MemberRegistrationModel();
      updatedMember.userId = widget.member.userId; // Keep original user ID
      updatedMember.firstName = _firstNameController.text.trim();
      updatedMember.lastName = _lastNameController.text.trim();
      updatedMember.mobile = _normalizeMobileForSaving(
        _mobileController.text.trim(),
      );
      updatedMember.email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();
      updatedMember.floor = _selectedFloor;
      updatedMember.flatNo = _flatNoController.text.trim();
      updatedMember.paymentStatus = _selectedPaymentStatus;
      updatedMember.parkingArea = _selectedParkingArea;
      updatedMember.parkingSlot = _selectedParkingSlot;
      updatedMember.govtIdType = _selectedGovtIdType;
      updatedMember.profileImage =
          widget.member.profileImage; // Keep original image
      updatedMember.govtIdImage =
          widget.member.govtIdImage; // Keep original image

      final updateData = {
        'firstName': updatedMember.firstName!,
        'lastName': updatedMember.lastName!,
        'mobile': updatedMember.mobile!,
        'email': updatedMember.email,
        'floor': updatedMember.floor!,
        'flatNo': updatedMember.flatNo!,
        'paymentStatus': updatedMember.paymentStatus,
        'parkingArea': updatedMember.parkingArea,
        'parkingSlot': updatedMember.parkingSlot,
        'govtIdType': updatedMember.govtIdType!,
      };

      print("🔧 Debug: Admin ID: $adminId");
      print("🔧 Debug: Member ID: ${widget.member.id}");
      print("🔧 Debug: Member User ID: ${widget.member.userId}");
      print("🔧 Debug: Update Data: $updateData");

      // Validate required fields before API call
      if (adminId.isEmpty) {
        throw Exception('Admin ID is empty');
      }
      if (widget.member.id == null || widget.member.id!.isEmpty) {
        throw Exception('Member ID is empty');
      }

      print("🔧 Debug: Making API call to adminUpdateMember...");
      final result = await ApiService.adminUpdateMember(
        adminId: adminId,
        memberId: widget.member.id!,
        updateData: updateData,
      );
      print("🔧 Debug: API Response: $result");

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Member updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(updatedMember); // Return updated member
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update member. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print("🔧 Debug: Caught exception: $e");
      print("🔧 Debug: Stack trace: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
