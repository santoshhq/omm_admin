import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'modules.dart';
import 'add_event.dart';
import 'view_donations.dart';
import '../../config/api_config.dart';

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

      final response = await ApiService.getAllEventCards();

      // Check again after the async call
      if (_isDisposed || !mounted) return;

      final List<dynamic> eventData = response['data'] ?? [];

      _safeSetState(() {
        festivals = eventData.map((json) => Festival.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
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
        await ApiService.deleteEventCard(festival.id!);
        await _loadEvents(); // Refresh from backend

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
    await openAddEvent(context, existing: festivals[index]);
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
                    child: ListView.builder(
                      itemCount: festivals.length,
                      itemBuilder: (context, index) {
                        final fest = festivals[index];

                        final double progress = (fest.targetAmount != 0)
                            ? (fest.collectedAmount / fest.targetAmount).clamp(
                                0.0,
                                1.0,
                              )
                            : 0.0;

                        return Slidable(
                          key: ValueKey(fest.name),
                          closeOnScroll: true,
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
                      },
                    ),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewDonationsPage(festival: fest),
            ),
          );
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
                // Event Image Section
                Row(
                  children: [
                    // Event Image or Icon
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

                    // Event Title and Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fest.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.65,
                                child: Switch.adaptive(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: fest.isActive,
                                  onChanged: (v) {
                                    _toggleEventStatus(fest);
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
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
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  fest.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Start and End Dates
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
                            fontSize: 11,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress indicator with percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    fest.isActive ? Colors.greenAccent : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collected: ₹${fest.collectedAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Target: ₹${fest.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
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

  /// Simple placeholder image widget for festival.
  /// Avoids referencing fields that may or may not exist in `Festival`.
  Widget _buildEventImageWidget(Festival fest) {
    // Use first image from imagePaths array
    if (fest.imagePaths.isEmpty) {
      return Icon(
        Icons.celebration,
        size: 30,
        color: fest.isActive ? Colors.deepOrange : const Color(0xFF455A64),
      );
    }

    final String imagePath = fest.imagePaths.first;

    // Handle base64 images
    if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',')[1];
        final bytes = base64.decode(base64String);
        return Image.memory(
          bytes,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.celebration,
              size: 30,
              color: fest.isActive
                  ? Colors.deepOrange
                  : const Color(0xFF455A64),
            );
          },
        );
      } catch (e) {
        return Icon(
          Icons.celebration,
          size: 30,
          color: fest.isActive ? Colors.deepOrange : const Color(0xFF455A64),
        );
      }
    }

    // Handle network images
    return Image.network(
      imagePath,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.celebration,
          size: 30,
          color: fest.isActive ? Colors.deepOrange : const Color(0xFF455A64),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 60,
          height: 60,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                fest.isActive ? Colors.deepOrange : const Color(0xFF455A64),
              ),
            ),
          ),
        );
      },
    );
  }
}
