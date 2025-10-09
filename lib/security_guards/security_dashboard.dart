import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

  List<Map<String, dynamic>> _maids = [];
  bool _loadingMaids = false;
  String? _maidsError;

  @override
  void initState() {
    super.initState();
    _fetchGuards();
    securityModule.addListener(_onModuleChanged);
    _fetchMaids();
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
        _guards = guards.reversed.toList(); // Show newest first
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

  Future<void> _fetchMaids() async {
    setState(() {
      _loadingMaids = true;
      _maidsError = null;
    });
    String? adminId = await AdminSessionService.getAdminId();
    if (adminId == null) {
      setState(() {
        _maidsError = 'Admin session not found.';
        _loadingMaids = false;
      });
      return;
    }
    try {
      final maids = await ApiService.getAllHousekeepingStaff(adminId);
      setState(() {
        _maids = maids.reversed.toList();
        _loadingMaids = false;
      });
    } catch (e) {
      setState(() {
        _maidsError = 'Failed to load housekeeping staff.';
        _loadingMaids = false;
      });
    }
  }

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
              title: const Text('Add Housekeeping'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MaidFormPage()),
                ).then((newMaid) {
                  if (newMaid != null && newMaid is Map<String, dynamic>) {
                    setState(() {
                      _maids.insert(0, newMaid);
                      _showGuards = false; // Switch to housekeeping staff tab
                    });
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editGuard(int index) async {
    final guard = _guards[index];
    final updatedGuard = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SecurityFormPage(guard: guard)),
    );
    if (updatedGuard != null && updatedGuard is SecurityGuardModel) {
      setState(() {
        _guards[index] = updatedGuard;
      });
    }
  }

  Future<void> _deleteGuard(int index) async {
    final guard = _guards[index];
    if (guard.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Guard ID is missing.')),
      );
      return;
    }
    String? adminId = await AdminSessionService.getAdminId();
    if (adminId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin session not found.')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Security Guard'),
        content: Text(
          'Are you sure you want to delete ${guard.firstName} ${guard.lastName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await ApiService.deleteSecurityGuard(adminId, guard.id!);
      if (result['status'] == true || result['success'] == true) {
        setState(() {
          _guards.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security guard deleted.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Failed to delete guard.',
            ),
          ),
        );
      }
    }
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
    int? index,
    bool slidable = false,
  }) {
    Widget avatar;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;
    if (hasImage && imageUrl.startsWith('data:image/')) {
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
        backgroundImage: NetworkImage(imageUrl),
      );
    } else {
      // Fallback icon
      avatar = CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        child: Icon(defaultIcon, color: Colors.grey[700]),
      );
    }
    Widget card = Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: avatar,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
      ),
    );
    if (slidable && index != null) {
      card = Slidable(
        key: ValueKey('guard_$index'),
        groupTag: 'guard_group',
        closeOnScroll: true,
        //  autoClose: true,
        startActionPane: null,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (ctx) => _editGuard(index),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            SlidableAction(
              onPressed: (ctx) => _deleteGuard(index),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: card,
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security & Staff',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF263238),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8EAF6)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with subtitle

              // Toggle Buttons
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      _buildToggleButton(
                        'Guards',
                        _showGuards,
                        () => setState(() => _showGuards = true),
                      ),
                      const SizedBox(width: 10),
                      _buildToggleButton(
                        'Housekeeping Staff',
                        !_showGuards,
                        () => setState(() => _showGuards = false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Guards List
              if (_showGuards)
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield, color: Color(0xFF455A64)),
                            const SizedBox(width: 8),
                            const Text(
                              'Security Guards',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                          Container(
                            constraints: const BoxConstraints(
                              minHeight: 200,
                              maxHeight: 600,
                            ),
                            child: Stack(
                              children: [
                                SlidableAutoCloseBehavior(
                                  child: _guards.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No security guards assigned.',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _guards.length,
                                          itemBuilder: (context, idx) {
                                            final g = _guards[idx];
                                            return _buildPersonCard(
                                              name:
                                                  '${g.firstName} ${g.lastName}',
                                              subtitle:
                                                  'Gate: ${g.assignedGate} • Age: ${g.age} • Mobile: ${g.mobile}',
                                              imageUrl: g.imageUrl,
                                              index: idx,
                                              slidable: true,
                                            );
                                          },
                                        ),
                                ),
                                // Fade effect at bottom to hint scrolling
                                if (_guards.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: IgnorePointer(
                                      child: Container(
                                        height: 30,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.8),
                                            ],
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
                )
              else
                Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.cleaning_services,
                              color: Color(0xFF388E3C),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Housekeeping Staff',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_loadingMaids)
                          const Center(child: CircularProgressIndicator()),
                        if (_maidsError != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _maidsError!,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        if (!_loadingMaids && _maidsError == null)
                          Container(
                            constraints: const BoxConstraints(
                              minHeight: 200,
                              maxHeight: 600,
                            ),
                            child: _maids.isEmpty
                                ? Center(
                                    child: Text(
                                      'No housekeeping staff assigned.',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : SlidableAutoCloseBehavior(
                                    child: ListView.builder(
                                      itemCount: _maids.length,
                                      itemBuilder: (context, idx) {
                                        final m = _maids[idx];
                                        return Slidable(
                                          key: ValueKey('maid_$idx'),
                                          groupTag: 'maid_group',
                                          closeOnScroll: true,
                                          endActionPane: ActionPane(
                                            motion: const DrawerMotion(),
                                            extentRatio: 0.4,
                                            children: [
                                              SlidableAction(
                                                onPressed: (ctx) async {
                                                  final updatedMaid =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              MaidFormPage(
                                                                maid: m,
                                                              ),
                                                        ),
                                                      );
                                                  if (updatedMaid != null &&
                                                      updatedMaid
                                                          is Map<
                                                            String,
                                                            dynamic
                                                          >) {
                                                    setState(() {
                                                      _maids[idx] = updatedMaid;
                                                    });
                                                  }
                                                },
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                icon: Icons.edit,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topLeft: Radius.circular(
                                                        16,
                                                      ),
                                                      bottomLeft:
                                                          Radius.circular(16),
                                                    ),
                                              ),
                                              SlidableAction(
                                                onPressed: (ctx) async {
                                                  if (m['id'] == null) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Cannot delete: Maid ID is missing.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  String? adminId =
                                                      await AdminSessionService.getAdminId();
                                                  if (adminId == null) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Admin session not found.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: const Text(
                                                        'Delete Housekeeping Staff',
                                                      ),
                                                      content: Text(
                                                        'Are you sure you want to delete \'${m['firstname'] ?? ''} ${m['lastname'] ?? ''}\'?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                false,
                                                              ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                                true,
                                                              ),
                                                          child: const Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    final result =
                                                        await ApiService.deleteHousekeepingStaff(
                                                          adminId: adminId,
                                                          staffId: m['id'],
                                                        );
                                                    if (result['status'] ==
                                                            true ||
                                                        result['success'] ==
                                                            true) {
                                                      setState(() {
                                                        _maids.removeAt(idx);
                                                      });
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Housekeeping staff deleted.',
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            result['message']
                                                                    ?.toString() ??
                                                                'Failed to delete staff.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                icon: Icons.delete,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topRight: Radius.circular(
                                                        16,
                                                      ),
                                                      bottomRight:
                                                          Radius.circular(16),
                                                    ),
                                              ),
                                            ],
                                          ),
                                          child: _buildPersonCard(
                                            name:
                                                '${m['firstname'] ?? ''} ${m['lastname'] ?? ''}',
                                            subtitle:
                                                'Floors: ${(m['assignfloors'] as List?)?.join(', ') ?? '-'} • Age: ${m['age'] ?? '-'} • Mobile: ${m['mobilenumber'] ?? '-'}',
                                            imageUrl: m['personimage'],
                                            defaultIcon: Icons.person_pin,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF263238),
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }
}
