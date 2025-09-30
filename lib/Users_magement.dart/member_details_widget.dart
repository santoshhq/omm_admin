import 'package:flutter/material.dart';
import 'package:omm_admin/Users_magement.dart/memebers_module.dart';
import 'package:omm_admin/Users_magement.dart/edit_member_widget.dart';
import 'package:omm_admin/config/api_config.dart';
import 'package:omm_admin/services/admin_session_service.dart';

class MemberDetailsWidget extends StatefulWidget {
  final MemberRegistrationModel member;

  const MemberDetailsWidget({super.key, required this.member});

  @override
  State<MemberDetailsWidget> createState() => _MemberDetailsWidgetState();
}

class _MemberDetailsWidgetState extends State<MemberDetailsWidget> {
  late MemberRegistrationModel _member;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _refreshMemberData() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin session not found');
      }

      final result = await ApiService.getAdminMembers(adminId);
      if (result['success'] == true) {
        final List<dynamic> membersData = result['data'] ?? [];

        // safely find updated member data
        final updatedMemberData = membersData
            .cast<Map<String, dynamic>?>()
            .firstWhere(
              (memberJson) => memberJson?['_id'] == _member.id,
              orElse: () => null,
            );

        if (updatedMemberData != null && mounted) {
          final updatedMember = MemberRegistrationModel()
            ..id = updatedMemberData['_id']
            ..firstName = updatedMemberData['firstName']
            ..lastName = updatedMemberData['lastName']
            ..mobile = updatedMemberData['mobile']
            ..email = updatedMemberData['email']
            ..floor = updatedMemberData['floor']
            ..flatNo = updatedMemberData['flatNo']
            ..paymentStatus = updatedMemberData['paymentStatus']
            ..parkingArea = updatedMemberData['parkingArea']
            ..parkingSlot = updatedMemberData['parkingSlot']
            ..govtIdType = updatedMemberData['govtIdType'];

          if (updatedMemberData['memberCredentialsId'] != null) {
            updatedMember.userId =
                updatedMemberData['memberCredentialsId']['userId'];
          }

          setState(() {
            _member = updatedMember;
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing member data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Member Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF455A64),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Member',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMemberWidget(member: _member),
                ),
              );

              if (result != null && result is MemberRegistrationModel) {
                await _refreshMemberData();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshMemberData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Profile Image
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: _member.profileImage != null
                                  ? (_member.profileImage.toString().startsWith(
                                          'http',
                                        )
                                        ? NetworkImage(
                                            _member.profileImage.toString(),
                                          )
                                        : _member.profileImage as ImageProvider)
                                  : null,
                              child: _member.profileImage == null
                                  ? const Icon(
                                      Icons.account_circle,
                                      size: 60,
                                      color: Color(0xFF607D8B),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Name
                          Text(
                            '${_member.firstName ?? ''} ${_member.lastName ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          // User ID
                          if (_member.userId != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ID: ${_member.userId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sections
                  _buildSectionCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    children: [
                      _buildDetailRow(
                        'Mobile',
                        _member.mobile != null ? '+91 ${_member.mobile}' : null,
                        Icons.phone,
                      ),
                      _buildDetailRow('Email', _member.email, Icons.email),
                      if (_member.hasValidRecoveryEmail)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recovery email available',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    title: 'Residence Information',
                    icon: Icons.home,
                    children: [
                      _buildDetailRow('Floor', _member.floor, Icons.layers),
                      _buildDetailRow(
                        'Flat Number',
                        _member.flatNo,
                        Icons.door_front_door,
                      ),
                      _buildDetailRow(
                        'Payment Status',
                        _member.paymentStatus,
                        Icons.payment,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    title: 'Parking Information',
                    icon: Icons.local_parking,
                    children: [
                      _buildDetailRow(
                        'Parking Area',
                        (_member.parkingArea == null ||
                                _member.parkingArea == 'Not Assigned')
                            ? 'NA'
                            : _member.parkingArea,
                        Icons.location_on,
                      ),
                      _buildDetailRow(
                        'Parking Slot',
                        (_member.parkingSlot == null ||
                                _member.parkingSlot == 'Not Assigned')
                            ? 'NA'
                            : _member.parkingSlot,
                        Icons.garage,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildSectionCard(
                    title: 'Government ID Information',
                    icon: Icons.badge,
                    children: [
                      _buildDetailRow(
                        'ID Type',
                        _member.govtIdType,
                        Icons.credit_card,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'ID Document:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _showGovtIdImage,
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text(
                              'View',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF607D8B,
                              ).withOpacity(0.1),
                              foregroundColor: const Color(0xFF455A64),
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF607D8B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF455A64), size: 20),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                fontSize: 14,
                color: value != null
                    ? Colors.grey.shade800
                    : Colors.grey.shade500,
                fontStyle: value != null ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGovtIdImage() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.9),
                  child: Center(
                    child: _member.govtIdImage != null
                        ? InteractiveViewer(
                            panEnabled: true,
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image(
                              image:
                                  _member.govtIdImage.toString().startsWith(
                                    'http',
                                  )
                                  ? NetworkImage(_member.govtIdImage.toString())
                                  : _member.govtIdImage as ImageProvider,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildNoImageWidget();
                              },
                            ),
                          )
                        : _buildNoImageWidget(),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoImageWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.image_not_supported,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Image Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The government ID image was not found in the backend.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
