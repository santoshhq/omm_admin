import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'modules.dart';
import 'add_event.dart';
import 'view_donations.dart';
import '../../config/api_config.dart';
import '../../services/admin_session_service.dart';

class FestivalScreen extends StatelessWidget {
  const FestivalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Builder(
              builder: (ctx) {
                // If used as a full screen, we can open the AddEvent page by
                // finding a FestivalContent ancestor via context.
                return TextButton.icon(
                  onPressed: () {
                    // Try to find a FestivalContentState in the widget tree
                    final state = ctx
                        .findAncestorStateOfType<FestivalContentState>();
                    if (state != null) {
                      state.openAddEvent(ctx);
                    } else {
                      // Fallback: open AddEventPage standalone
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(builder: (c) => const AddEventPage()),
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
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    "New Event",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: const FestivalContent(),
    );
  }
}

class FestivalContent extends StatefulWidget {
  const FestivalContent({super.key});

  @override
  FestivalContentState createState() => FestivalContentState();
}

class FestivalContentState extends State<FestivalContent> {
  List<Festival> festivals = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

  /// Safe setState that checks if widget is still mounted and not disposed
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  /// Sort events: active events first, inactive events at bottom
  void _sortEvents() {
    festivals.sort((a, b) {
      if (a.isActive && !b.isActive) return -1; // a comes before b
      if (!a.isActive && b.isActive) return 1; // b comes before a
      return 0; // keep original order for same status
    });
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (_isDisposed) return;

    try {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🚀 Starting _loadEvents...');

      // Get current admin ID to filter events per admin
      final adminId = await AdminSessionService.getAdminId();
      print('🔍 Retrieved Admin ID: $adminId');

      if (adminId == null) {
        print('❌ Admin ID is null - session expired');
        throw Exception('Admin session expired. Please login again.');
      }

      print('📡 Calling API with adminId: $adminId');
      // Try to get admin-specific events from backend, fallback to client-side filtering
      final response = await ApiService.getEventCardsByAdminId(adminId);
      print('📦 API Response: ${response.toString()}');

      // Check again after the async call
      if (_isDisposed || !mounted) return;

      final List<dynamic> eventData = response['data'] ?? [];
      print('📊 Raw event data length: ${eventData.length}');

      // Log first event if any for debugging
      if (eventData.isNotEmpty) {
        print('🔍 First event sample: ${eventData.first}');
      } else {
        print('⚠️ No events returned from API');
      }

      // If backend doesn't support admin filtering, filter on frontend
      final adminEvents = eventData.where((eventJson) {
        final adminIdFromEvent = eventJson['adminId'];
        String? adminIdString;

        // Handle different adminId formats from backend
        if (adminIdFromEvent is String) {
          adminIdString = adminIdFromEvent;
        } else if (adminIdFromEvent is Map && adminIdFromEvent['_id'] != null) {
          adminIdString = adminIdFromEvent['_id'].toString();
        } else {
          adminIdString = adminIdFromEvent?.toString();
        }

        final matches = adminIdString == adminId;
        print(
          '🔍 Event "${eventJson['name']}" - adminId: $adminIdString, Current: $adminId, Matches: $matches',
        );
        return matches;
      }).toList();

      print('✅ Filtered admin events: ${adminEvents.length}');

      _safeSetState(() {
        festivals = adminEvents.map((json) {
          print('🔍 Raw event data for ${json['name']}:');
          print('🔍 - Images field: ${json['images']}');
          print('🔍 - ImagePaths field: ${json['imagePaths']}');
          print('🔍 - Image field: ${json['image']}');

          final festival = Festival.fromJson(json);
          print('🎯 Mapped festival: ${festival.name} (ID: ${festival.id})');
          print('🎯 - Festival imagePaths: ${festival.imagePaths}');
          print(
            '🎯 - First image: ${festival.imagePaths.isNotEmpty ? festival.imagePaths.first : 'NO IMAGES'}',
          );
          return festival;
        }).toList();
        _sortEvents(); // Sort events: active first, inactive at bottom
        _isLoading = false;
      });

      print('🎯 Final festivals list: ${festivals.length}');

      // Debug info
      print('🔍 SUMMARY:');
      print('🔍 Admin ID: $adminId');
      print('🔍 Total events from backend: ${eventData.length}');
      print('🔍 Admin-specific events: ${adminEvents.length}');
      print('🔍 Festivals mapped: ${festivals.length}');

      if (festivals.isEmpty) {
        print(
          '⚠️ No festivals to display - this will show "No Events Added yet"',
        );
      }
    } catch (e) {
      print('❌ Error in _loadEvents: $e');
      _safeSetState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> openAddEvent(BuildContext context, {Festival? existing}) async {
    final newEvent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(existingEvent: existing),
      ),
    );
    if (newEvent != null) {
      await _loadEvents(); // Refresh from backend
    }
  }

  Future<void> _deleteEvent(int index) async {
    final festival = festivals[index];
    if (festival.id == null) return;

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Event'),
          content: Text('Are you sure you want to delete "${festival.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Get admin ID for the delete operation
        String? adminId = await AdminSessionService.getAdminId();
        if (adminId == null) {
          throw Exception("Admin not logged in");
        }

        await ApiService.deleteEventCard(id: festival.id!, adminId: adminId);

        // Remove the item from local list instead of refreshing entire list
        _safeSetState(() {
          festivals.removeAt(index);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${festival.name}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete event: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editEvent(int index) async {
    final festival = festivals[index];
    if (festival.id == null) return;

    try {
      // Get admin ID
      final adminId = await AdminSessionService.getAdminId();
      if (adminId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin session expired. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading event details...')),
        );
      }

      // Fetch complete event details from backend
      final response = await ApiService.getEventCardById(
        id: festival.id!,
        adminId: adminId,
      );
      if (response['success'] == true) {
        final completeEventData = response['data'];
        final completeFestival = Festival.fromJson(completeEventData);

        await openAddEvent(context, existing: completeFestival);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load event details: ${response['message']}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Ng event details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleEventStatus(Festival festival) async {
    if (festival.id == null || _isDisposed) return;

    try {
      // Optimistic update
      final updatedFestivals = festivals.map((f) {
        if (f.id == festival.id) {
          return f.copyWith(isActive: !f.isActive);
        }
        return f;
      }).toList();

      _safeSetState(() {
        festivals = updatedFestivals;
        _sortEvents(); // Sort events immediately: active first, inactive at bottom
      });

      // API call
      await ApiService.toggleEventStatus(festival.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on failure
      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update status: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, stackTrace) {
      print('❌ Critical error in FestivalContent build: $e');
      print('Stack trace: $stackTrace');
      return _buildErrorWidget(e.toString());
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: festivals.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.celebration,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Events Added yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap + to create one',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadEvents,
                      child: SlidableAutoCloseBehavior(
                        child: ListView.builder(
                          itemCount: festivals.length,
                          itemBuilder: (context, index) {
                            try {
                              final fest = festivals[index];

                              final double progress = (fest.targetAmount != 0)
                                  ? (fest.collectedAmount / fest.targetAmount)
                                        .clamp(0.0, 1.0)
                                  : 0.0;

                              return Slidable(
                                key: ValueKey('${fest.name}_$index'),
                                groupTag:
                                    'festival_group', // Ensures only one slidable is open at a time
                                closeOnScroll: true,
                                startActionPane: null, // Disable left swipe
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio:
                                      0.4, // controls how much space the actions take
                                  children: [
                                    SlidableAction(
                                      onPressed: (ctx) => _editEvent(index),
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      icon: Icons.edit,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    SlidableAction(
                                      onPressed: (ctx) => _deleteEvent(index),
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
                                child: _buildEventImage(
                                  fest,
                                  progress,
                                  index,
                                  context,
                                ),
                              );
                            } catch (e, stackTrace) {
                              print(
                                '❌ Error building event card at index $index: $e',
                              );
                              print('Stack trace: $stackTrace');

                              // Return a safe error card instead of crashing
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 4,
                                ),
                                child: Container(
                                  height: 120,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Error loading event',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Index: $index',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Build error widget for critical failures
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'App Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Something went wrong while loading the events.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _loadEvents();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                print('Debug error: $error');
              },
              child: const Text('Show Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage(
    Festival fest,
    double progress,
    int index,
    BuildContext context,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDonationsPage(festival: fest),
            ),
          );
          // Refresh the events list when returning from ViewDonationsPage
          // This ensures progress bars update if donations were modified
          await _loadEvents();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: fest.isActive
                  ? [Colors.deepOrange.shade700, Colors.orange.shade800]
                  : [const Color(0xFF455A64), const Color(0xFF607D8B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- First Row: Image + Title/Toggle ----------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildEventImageWidget(fest),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title, Toggle, Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  fest.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.7,
                                    child: Switch.adaptive(
                                      value: fest.isActive,
                                      onChanged: (v) =>
                                          _toggleEventStatus(fest),
                                    ),
                                  ),
                                  Text(
                                    fest.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: fest.isActive
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fest.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ---------- Dates ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Start: ${fest.startDate != null ? "${fest.startDate!.day}/${fest.startDate!.month}/${fest.startDate!.year}" : "N/A"}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'End: ${fest.endDate != null ? "${fest.endDate!.day}/${fest.endDate!.month}/${fest.endDate!.year}" : "N/A"}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ---------- Progress ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fest.isActive ? Colors.greenAccent : Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ---------- Collected vs Target ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collected: ₹${fest.collectedAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Target: ₹${fest.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Robust image widget with comprehensive error handling
  Widget _buildEventImageWidget(Festival fest) {
    print('🖼️ Building image widget for event: ${fest.name}');
    print('🖼️ - ImagePaths array: ${fest.imagePaths}');
    print('🖼️ - Array length: ${fest.imagePaths.length}');

    // Use first image from imagePaths array
    if (fest.imagePaths.isEmpty) {
      print('🖼️ - No images found, showing placeholder for: ${fest.name}');
      return _buildPlaceholderIcon(fest);
    }

    final String imagePath = fest.imagePaths.first;
    print('🖼️ - Selected image path: "$imagePath"');
    print('🖼️ - Path length: ${imagePath.length}');

    // Validate image path
    if (imagePath.trim().isEmpty) {
      print('⚠️ Empty image path for event: ${fest.name}');
      return _buildPlaceholderIcon(fest);
    }

    // Handle base64 images
    if (imagePath.startsWith('data:image')) {
      print('🖼️ - Detected base64 image for: ${fest.name}');
      return _buildBase64Image(imagePath, fest);
    }

    // Handle network images
    print('🖼️ - Detected network image for: ${fest.name}');
    return _buildNetworkImage(imagePath, fest);
  }

  /// Build placeholder icon
  Widget _buildPlaceholderIcon(Festival fest) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: (fest.isActive ? Colors.deepOrange : const Color(0xFF455A64))
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fest.isActive ? Colors.deepOrange : const Color(0xFF455A64),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.celebration,
        size: 30,
        color: fest.isActive ? Colors.deepOrange : const Color(0xFF455A64),
      ),
    );
  }

  /// Build base64 image with error handling
  Widget _buildBase64Image(String imagePath, Festival fest) {
    try {
      // Validate base64 format
      if (!imagePath.contains(',')) {
        print('⚠️ Invalid base64 format for event: ${fest.name}');
        return _buildPlaceholderIcon(fest);
      }

      final base64String = imagePath.split(',')[1];

      // Validate base64 string
      if (base64String.trim().isEmpty) {
        print('⚠️ Empty base64 string for event: ${fest.name}');
        return _buildPlaceholderIcon(fest);
      }

      final bytes = base64.decode(base64String);

      // Validate decoded bytes
      if (bytes.isEmpty) {
        print('⚠️ Empty image bytes for event: ${fest.name}');
        return _buildPlaceholderIcon(fest);
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Base64 image load error for ${fest.name}: $error');
            return _buildPlaceholderIcon(fest);
          },
        ),
      );
    } catch (e) {
      print('❌ Base64 decode error for ${fest.name}: $e');
      return _buildPlaceholderIcon(fest);
    }
  }

  /// Build network image with error handling
  Widget _buildNetworkImage(String imagePath, Festival fest) {
    // Validate URL format
    if (!imagePath.startsWith('http')) {
      print('⚠️ Invalid URL format for event ${fest.name}: $imagePath');
      return _buildPlaceholderIcon(fest);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Network image load error for ${fest.name}: $error');
          return _buildPlaceholderIcon(fest);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    fest.isActive ? Colors.deepOrange : const Color(0xFF455A64),
                  ),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
