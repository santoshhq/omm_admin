import 'package:flutter/material.dart';
import 'package:omm_admin/Users_magement.dart/members_widget.dart';
import 'package:omm_admin/Users_magement.dart/memebers_module.dart';
import 'package:omm_admin/Users_magement.dart/member_details_widget.dart';
import 'package:omm_admin/Users_magement.dart/edit_member_widget.dart';
import '../config/api_config.dart';
import '../services/admin_session_service.dart';

class MembersPage extends StatefulWidget {
  final String? adminId; // Pass admin ID to fetch members

  const MembersPage({super.key, this.adminId});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  String _searchQuery = "";
  List<MemberRegistrationModel> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-refresh every time the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMembers();
    });
  }

  Future<void> _fetchMembers() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      // Use admin ID from widget or get from session
      String? adminId = widget.adminId;

      if (adminId == null) {
        adminId = await AdminSessionService.getAdminId();

        if (adminId == null) {
          if (mounted) {
            setState(() {
              _error = 'Admin session expired. Please login again.';
              _isLoading = false;
            });
          }
          return;
        }
      }

      final result = await ApiService.getAdminMembers(adminId);

      if (result['success'] == true) {
        final List<dynamic> membersData = result['data'] ?? [];
        if (mounted) {
          setState(() {
            _members = membersData.map((memberJson) {
              // Convert backend member data to frontend model
              final model = MemberRegistrationModel();

              // Store MongoDB document ID for updates
              model.id = memberJson['_id'];

              model.firstName = memberJson['firstName'];
              model.lastName = memberJson['lastName'];
              model.mobile = memberJson['mobile'];
              model.email = memberJson['email'];
              model.floor = memberJson['floor'];
              model.flatNo = memberJson['flatNo'];
              model.paymentStatus = memberJson['paymentStatus'];
              model.parkingArea = memberJson['parkingArea'];
              model.parkingSlot = memberJson['parkingSlot'];
              model.govtIdType = memberJson['govtIdType'];

              // Get user ID from credentials if available
              if (memberJson['memberCredentialsId'] != null) {
                model.userId = memberJson['memberCredentialsId']['userId'];
              }

              return model;
            }).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = result['message'] ?? 'Failed to fetch members';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getCardColor(String? status) {
    switch (status) {
      case 'I':
        return const Color(0xFFFFEBEE); // Soft Rose - Very light pink/red
      case 'II':
        return const Color(0xFFE8F5E8); // Mint Fresh - Very light green
      case 'III':
        return const Color(0xFFE3F2FD); // Sky Blue - Very light blue
      case 'IV':
        return const Color(0xFFFFF3E0); // Peach Cream - Very light orange
      case 'V':
        return const Color(0xFFF3E5F5); // Lavender Mist - Very light purple
      case 'VI':
        return const Color(0xFFE0F2F1); // Aqua Mint - Very light teal
      default:
        return const Color(0xFFF5F5F5); // Pearl White - Very light grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _members.where((member) {
      final query = _searchQuery.toLowerCase();
      return (member.firstName ?? "").toLowerCase().contains(query) ||
          (member.lastName ?? "").toLowerCase().contains(query) ||
          (member.userId ?? "").toLowerCase().contains(query) ||
          (member.mobile ?? "").toLowerCase().contains(query) ||
          (member.flatNo ?? "").toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage community members',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF455A64),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF455A64), Color(0xFF607D8B)],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF607D8B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () async {
                final newMember = await Navigator.push<MemberRegistrationModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemberRegistrationFlow(),
                  ),
                );

                if (newMember != null) {
                  // Refresh the members list from API after adding new member
                  _fetchMembers();
                }
              },
              tooltip: 'Add New Member',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Professional spacing from AppBar
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name, User ID, mobile, or flat number",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Filters row (dummy buttons for now)
          const SizedBox(height: 8),

          // Members list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Loading members..."),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          "Error: $_error",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchMembers,
                          child: Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : filteredMembers.isEmpty
                ? RefreshIndicator(
                    onRefresh: _fetchMembers,
                    child: ListView(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(child: Text("No members found")),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchMembers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: ViewIdCard(
                            model: member,
                            bgColor: _getCardColor(member.floor),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class ViewIdCard extends StatelessWidget {
  final MemberRegistrationModel model;
  final Color bgColor;

  const ViewIdCard({super.key, required this.model, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, bgColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberDetailsWidget(member: model),
                ),
              );
              if (context.mounted) {
                (context.findAncestorStateOfType<_MembersPageState>())
                    ?._fetchMembers();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header Section =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Avatar with status indicator
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF455A64),
                                  const Color(0xFF607D8B),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF455A64,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.transparent,
                              backgroundImage: model.profileImage,
                              child: model.profileImage == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 36,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          // Status dot
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Name and details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              "${model.firstName ?? ''} ${model.lastName ?? ''}"
                                      .trim()
                                      .isEmpty
                                  ? 'No Name'
                                  : "${model.firstName ?? ''} ${model.lastName ?? ''}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // User ID Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF3498DB),
                                    const Color(0xFF2980B9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3498DB,
                                    ).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                "ID: ${model.userId ?? 'Not Generated'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Payment Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getPaymentStatusColor(),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          model.paymentStatus ?? 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getPaymentStatusColor(),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===== Information Grid =====
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      children: [
                        // Row 1: Flat & Floor + Mobile
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                Icons.home_rounded,
                                "Flat ${model.flatNo ?? '-'} • Floor ${model.floor ?? '-'}",
                                const Color(0xFF8E44AD),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoItem(
                                Icons.phone_rounded,
                                model.mobile ?? 'No Mobile',
                                const Color(0xFF27AE60),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 2: Email
                        _buildInfoItem(
                          Icons.email_rounded,
                          model.email ?? 'No Email',
                          const Color(0xFFE67E22),
                        ),
                        const SizedBox(height: 12),
                        // Row 3: Govt ID
                        _buildInfoItem(
                          Icons.badge_rounded,
                          "ID: ${model.govtIdType ?? 'Not Provided'}",
                          const Color(0xFF34495E),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== Action Buttons =====
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModernAction(
                            Icons.call_rounded,
                            "Call",
                            const Color(0xFF3498DB),
                            () {
                              // TODO: Implement call functionality
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernAction(
                            Icons.message_rounded,
                            "WhatsApp",
                            const Color(0xFF25D366),
                            () {
                              // TODO: Implement WhatsApp functionality
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernAction(
                            Icons.edit_rounded,
                            "Edit",
                            const Color(0xFF9B59B6),
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditMemberWidget(member: model),
                                ),
                              );
                              if (result != null && context.mounted) {
                                (context
                                        .findAncestorStateOfType<
                                          _MembersPageState
                                        >())
                                    ?._fetchMembers();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernAction(
                            Icons.delete_rounded,
                            "Delete",
                            const Color(0xFFE74C3C),
                            () {
                              // TODO: Implement delete functionality
                            },
                          ),
                        ),
                      ],
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

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildModernAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    // Green for active/complete, orange for pending, red for inactive
    final status = model.paymentStatus?.toLowerCase();
    if (status == 'paid' || status == 'active' || status == 'completed') {
      return const Color(0xFF27AE60);
    } else if (status == 'pending' || status == 'processing') {
      return const Color(0xFFF39C12);
    } else {
      return const Color(0xFFE74C3C);
    }
  }

  Color _getPaymentStatusColor() {
    final status = model.paymentStatus?.toLowerCase();
    if (status == 'paid' || status == 'active' || status == 'completed') {
      return const Color(0xFF27AE60);
    } else if (status == 'pending' || status == 'processing') {
      return const Color(0xFFF39C12);
    } else {
      return const Color(0xFFE74C3C);
    }
  }
}
