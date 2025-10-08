import 'dart:convert';
import 'package:flutter/material.dart';
import 'security_module.dart';
import 'security_form.dart';
import 'maid_form.dart';
import '../services/admin_session_service.dart';
import '../config/api_config.dart';

class SecurityDashboardPage extends StatefulWidget {
  const SecurityDashboardPage({super.key});

  @override
  State<SecurityDashboardPage> createState() => _SecurityDashboardPageState();
}

class _SecurityDashboardPageState extends State<SecurityDashboardPage> {
  bool _showGuards = true; // default selected option should be guards
  List<SecurityGuardModel> _guards = [];
  bool _loadingGuards = false;
  String? _guardsError;

  @override
  void initState() {
    super.initState();
    _fetchGuards();
    securityModule.addListener(_onModuleChanged);
  }

  Future<void> _fetchGuards() async {
    setState(() {
      _loadingGuards = true;
      _guardsError = null;
    });
    String? adminId = await AdminSessionService.getAdminId();
    if (adminId == null) {
      setState(() {
        _guardsError = 'Admin session not found.';
        _loadingGuards = false;
      });
      return;
    }
    try {
      final guards = await ApiService.getAllGuards(adminId);
      setState(() {
        _guards = guards;
        _loadingGuards = false;
      });
    } catch (e) {
      setState(() {
        _guardsError = 'Failed to load guards.';
        _loadingGuards = false;
      });
    }
  }

  @override
  void dispose() {
    securityModule.removeListener(_onModuleChanged);
    super.dispose();
  }

  void _onModuleChanged() => setState(() {});

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.shield, color: Colors.blue),
              title: const Text('Add Security Guard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecurityFormPage()),
                ).then((newGuard) {
                  if (newGuard != null && newGuard is SecurityGuardModel) {
                    _fetchGuards(); // Refresh list after adding
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.green),
              title: const Text('Add Maid'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MaidFormPage()),
                ).then((newMaid) {
                  if (newMaid != null) {
                    securityModule.addMaid(newMaid);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF455A64) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard({
    required String name,
    String? subtitle,
    String? imageUrl,
    IconData defaultIcon = Icons.person,
  }) {
    Widget avatar;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    if (hasImage && imageUrl!.startsWith('data:image/')) {
      // Base64 image
      try {
        final base64Str = imageUrl.split(',').last;
        avatar = CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(base64Decode(base64Str)),
        );
      } catch (e) {
        avatar = CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
          child: Icon(defaultIcon, color: Colors.grey[700]),
        );
      }
    } else if (hasImage) {
      // Network image
      avatar = CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(imageUrl!),
      );
    } else {
      // Fallback icon
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        child: Icon(defaultIcon, color: Colors.grey[700]),
      );
    }
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: avatar,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security & Staff',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF455A64),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Toggle Buttons
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _buildToggleButton(
                      'Guards',
                      _showGuards,
                      () => setState(() => _showGuards = true),
                    ),
                    const SizedBox(width: 8),
                    _buildToggleButton(
                      'Maids',
                      !_showGuards,
                      () => setState(() => _showGuards = false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Guards List
            if (_showGuards)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Guards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingGuards)
                    const Center(child: CircularProgressIndicator()),
                  if (_guardsError != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _guardsError!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  if (!_loadingGuards && _guardsError == null)
                    ..._guards.map(
                      (g) => _buildPersonCard(
                        name: '${g.firstName} ${g.lastName}',
                        subtitle:
                            'Gate: ${g.assignedGate} • Age: ${g.age} • Mobile: ${g.mobile}',
                        imageUrl: g.imageUrl,
                      ),
                    ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maids',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...securityModule.maids.map(
                    (m) => _buildPersonCard(
                      name: '${m.firstName} ${m.lastName}',
                      subtitle:
                          'Flats: ${m.workingFlats} • Timings: ${m.timings} • Mobile: ${m.mobile ?? '-'}',
                      imageUrl: m.imageUrl,
                      defaultIcon: Icons.person_pin,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF455A64),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
