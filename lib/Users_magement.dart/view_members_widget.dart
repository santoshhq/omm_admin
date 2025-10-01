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
        return Colors.red.shade100;
      case 'II':
        return Colors.green.shade100;
      case 'III':
        return Colors.blue.shade100;
      case 'IV':
        return Colors.orange.shade50;
      case 'V':
        return Colors.purple.shade100;
      case 'VI':
        return Colors.teal.shade100;
      default:
        return Colors.grey.shade100; // fallback
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
        title: const Text(
          " View Members",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
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
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Profile + Name + Mobile =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: model.profileImage,
                    child: model.profileImage == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${model.firstName ?? ''} ${model.lastName ?? ''}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.mobile ?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== Flat & Floor =====
              Text(
                "Flat No: ${model.flatNo ?? '-'}   |   Floor: ${model.floor ?? '-'}",
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 8),

              // ===== Email =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.email, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Recovery Email",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          model.email ?? 'Not provided',
                          style: TextStyle(
                            fontSize: 14,
                            color: model.email != null
                                ? Colors.green.shade800
                                : Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ===== Payment Status =====
              Text(
                "Payment Status: ${model.paymentStatus ?? '-'}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // ===== User ID =====
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Text(
                  "User ID: ${model.userId ?? 'Not Generated'}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ===== Govt ID =====
              Text(
                "Govt ID Type: ${model.govtIdType ?? '-'}",
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 12),
              const Divider(),

              // ===== Action Buttons =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAction(Icons.call, "Call", Colors.blue, () {
                    // TODO: Implement call functionality
                  }),
                  _buildAction(Icons.message, "WhatsApp", Colors.green, () {
                    // TODO: Implement WhatsApp functionality
                  }),
                  _buildAction(Icons.edit, "Edit", Colors.indigo, () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditMemberWidget(member: model),
                      ),
                    );
                    if (result != null && context.mounted) {
                      (context.findAncestorStateOfType<_MembersPageState>())
                          ?._fetchMembers();
                    }
                  }),
                  _buildAction(Icons.delete, "Delete", Colors.red, () {
                    // TODO: Implement delete functionality
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
