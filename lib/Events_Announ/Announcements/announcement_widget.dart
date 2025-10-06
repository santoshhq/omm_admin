import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'announcement_module.dart';
import '../../config/api_config.dart';
import '../../services/admin_session_service.dart';

/// ==================== Main Announcement Screen ====================
class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Builder(
              builder: (ctx) {
                return TextButton.icon(
                  onPressed: () {
                    final state = ctx
                        .findAncestorStateOfType<AnnouncementContentState>();
                    if (state != null) {
                      state.openComposeSheet(ctx);
                    } else {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (c) => const AnnouncementComposePage(),
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    "Add",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: const AnnouncementContent(),
    );
  }
}

/// ==================== Announcement Content Widget ====================
class AnnouncementContent extends StatefulWidget {
  const AnnouncementContent({super.key});

  @override
  AnnouncementContentState createState() => AnnouncementContentState();
}

class AnnouncementContentState extends State<AnnouncementContent> {
  List<Announcement> announcements = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

  /// Safe setState that checks if widget is still mounted and not disposed
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  /// Sort announcements: active first, inactive at bottom, then by priority
  void _sortAnnouncements() {
    announcements.sort((a, b) {
      // First sort by active status
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;

      // Then sort by priority (High > Medium > Low)
      const priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      final aPriority = priorityOrder[a.priority] ?? 1;
      final bPriority = priorityOrder[b.priority] ?? 1;

      if (aPriority != bPriority) return aPriority.compareTo(bPriority);

      // Finally sort by creation date (newest first)
      return b.createdDate.compareTo(a.createdDate);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Load announcements from the backend (admin-specific)
  Future<void> _loadAnnouncements() async {
    if (_isDisposed) return;

    try {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get current admin ID to filter announcements per admin
      final adminId = await AdminSessionService.getAdminId();
      print('🔍 Loading announcements for Admin ID: $adminId');

      if (adminId == null) {
        throw Exception('Admin session expired. Please login again.');
      }

      // Try to get admin-specific announcements from backend, fallback to client-side filtering
      final response = await ApiService.getAnnouncementCardsByAdminId(adminId);
      print('📦 API Response: ${response.toString()}');

      // Check again after the async call
      if (_isDisposed || !mounted) return;

      final List<dynamic> announcementData = response['data'] ?? [];

      // If backend doesn't support admin filtering, filter on frontend with object format handling
      final adminAnnouncements = announcementData.where((announcementJson) {
        final announcementAdminId = announcementJson['adminId'];
        String? adminIdFromAnnouncement;

        // Handle different adminId formats from backend
        if (announcementAdminId is String) {
          adminIdFromAnnouncement = announcementAdminId;
        } else if (announcementAdminId is Map &&
            announcementAdminId['_id'] != null) {
          adminIdFromAnnouncement = announcementAdminId['_id'].toString();
        } else {
          adminIdFromAnnouncement = announcementAdminId?.toString();
        }

        final matches = adminIdFromAnnouncement == adminId;
        print(
          '🔍 Announcement "${announcementJson['title']}" - adminId: $adminIdFromAnnouncement, Current: $adminId, matches: $matches',
        );
        return matches;
      }).toList();

      _safeSetState(() {
        announcements = adminAnnouncements
            .map((json) => Announcement.fromJson(json))
            .toList();
        _sortAnnouncements();
        _isLoading = false;
      });

      // Debug info
      print('🔍 Admin ID: $adminId');
      print('🔍 Total announcements from backend: ${announcementData.length}');
      print('🔍 Admin-specific announcements: ${adminAnnouncements.length}');
      print('🔍 Final announcements in UI: ${announcements.length}');
    } catch (e) {
      _safeSetState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Public method to refresh announcements (can be called from parent widgets)
  Future<void> refreshAnnouncements() async {
    await _loadAnnouncements();
  }

  /// Add optimistic announcement update (shows immediately, then refreshes)
  void addOptimisticAnnouncement(Announcement announcement) {
    if (_isDisposed) return;

    print('🎯 Adding optimistic announcement: ${announcement.title}');
    print('🎯 Announcement adminId: ${announcement.adminId}');

    _safeSetState(() {
      announcements.insert(0, announcement);
      _sortAnnouncements();
    });

    // Refresh from backend to get the real data after a short delay
    // This ensures the backend has processed the creation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed && mounted) {
        print('🔄 Refreshing announcements after optimistic add...');
        refreshAnnouncements();
      }
    });
  }

  /// Open compose sheet for creating or editing announcements
  Future<void> openComposeSheet(
    BuildContext ctx, {
    Announcement? existing,
  }) async {
    final result = await Navigator.of(ctx).push<Announcement>(
      MaterialPageRoute(
        builder: (_) => AnnouncementComposePage(existing: existing),
      ),
    );
    if (result != null) {
      if (existing == null) {
        // New announcement - add optimistically
        addOptimisticAnnouncement(result);
      } else {
        // Updated announcement - refresh from backend
        await refreshAnnouncements();
      }
    }
  }

  /// Delete announcement
  Future<void> _deleteAnnouncement(int index) async {
    final announcement = announcements[index];

    if (announcement.id == null) {
      _showErrorSnackBar('Cannot delete announcement: Missing ID');
      return;
    }

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: Text(
            'Are you sure you want to delete "${announcement.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Optimistic update - remove from list immediately
      _safeSetState(() {
        announcements.removeAt(index);
      });

      // API call to delete
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin not logged in');
      }

      await ApiService.deleteAnnouncementCard(
        id: announcement.id!,
        adminId: adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Rollback on error - add the announcement back
      _safeSetState(() {
        announcements.insert(index, announcement);
        _sortAnnouncements();
      });
      _showErrorSnackBar(
        'Failed to delete announcement: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Edit announcement
  void _editAnnouncement(int index) async {
    await openComposeSheet(context, existing: announcements[index]);
  }

  /// Toggle announcement status
  Future<void> _toggleAnnouncementStatus(Announcement announcement) async {
    if (announcement.id == null || _isDisposed) return;

    try {
      // Optimistic update
      final updatedAnnouncements = announcements.map((a) {
        if (a.id == announcement.id) {
          return a.copyWith(isActive: !a.isActive);
        }
        return a;
      }).toList();

      _safeSetState(() {
        announcements = updatedAnnouncements;
        _sortAnnouncements();
      });

      // API call
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        throw Exception('Admin not logged in');
      }

      await ApiService.toggleAnnouncementStatus(
        id: announcement.id!,
        adminId: adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Announcement ${announcement.isActive ? 'activated' : 'deactivated'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Rollback on error
      await _loadAnnouncements();
      _showErrorSnackBar(
        'Failed to update announcement status: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Announcements',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: refreshAnnouncements,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshAnnouncements,
      child: announcements.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SlidableAutoCloseBehavior(
                      child: ListView.builder(
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          return Slidable(
                            key: ValueKey('${announcement.id}_$index'),
                            groupTag: 'announcement_group',
                            closeOnScroll: true,
                            startActionPane: null,
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.4,
                              children: [
                                SlidableAction(
                                  onPressed: (ctx) => _editAnnouncement(index),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                SlidableAction(
                                  onPressed: (ctx) =>
                                      _deleteAnnouncement(index),
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
                            child: _buildAnnouncementCard(announcement, index),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.campaign_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Announcements Yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first announcement',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build individual announcement card
  Widget _buildAnnouncementCard(Announcement announcement, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: announcement.isActive ? Colors.blue.shade50 : Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and priority
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    announcement.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: announcement.isActive
                          ? Colors.black87
                          : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(announcement.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    announcement.priority,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              announcement.description,
              style: TextStyle(
                fontSize: 14,
                color: announcement.isActive
                    ? Colors.grey[700]
                    : Colors.grey[500],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 16),

            // Footer with date and status toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(announcement.createdDate),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                // Status toggle
                Row(
                  children: [
                    Text(
                      announcement.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: announcement.isActive
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: announcement.isActive,
                      onChanged: (value) =>
                          _toggleAnnouncementStatus(announcement),
                      activeColor: Colors.green,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// ==================== Announcement Compose Page ====================
class AnnouncementComposePage extends StatefulWidget {
  final Announcement? existing;

  const AnnouncementComposePage({super.key, this.existing});

  @override
  State<AnnouncementComposePage> createState() =>
      _AnnouncementComposePageState();
}

class _AnnouncementComposePageState extends State<AnnouncementComposePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _priority = 'Medium';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _descriptionController.text = widget.existing!.description;
      _priority = widget.existing!.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Save announcement (create or update)
  Future<void> _saveAnnouncement() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a description');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get admin ID from session
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        _showErrorSnackBar('Admin not logged in. Please login again.');
        return;
      }

      if (widget.existing != null) {
        // Update existing announcement
        await ApiService.updateAnnouncementCard(
          id: widget.existing!.id!,
          adminId: adminId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new announcement
        await ApiService.createAnnouncementCard(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          adminId: adminId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Announcement created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        // Return the created/updated announcement data for optimistic updates
        final createdAnnouncement = Announcement(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          adminId: adminId,
          createdDate: DateTime.now(),
          isActive: true,
        );
        Navigator.pop(context, createdAnnouncement);
      }
    } catch (e) {
      _showErrorSnackBar(
        'Failed to save announcement: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing != null ? 'Edit Announcement' : 'Create Announcement',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Enter announcement title...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),

              // Description field
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 6,
                maxLength: 1000,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Enter announcement description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Priority selection
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPriorityChip('High', Colors.red),
                  _buildPriorityChip('Medium', Colors.orange),
                  _buildPriorityChip('Low', Colors.green),
                ],
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.existing != null
                              ? 'Update Announcement'
                              : 'Create Announcement',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build priority selection chip
  Widget _buildPriorityChip(String priority, Color color) {
    final isSelected = _priority == priority;
    return GestureDetector(
      onTap: () => setState(() => _priority = priority),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          priority,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
