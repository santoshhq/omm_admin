import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'modules.dart';
import 'add_event.dart';
import 'view_donations.dart';

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

  Future<void> openAddEvent(BuildContext context, {Festival? existing}) async {
    final newEvent = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(existingEvent: existing),
      ),
    );
    if (newEvent != null) {
      setState(() {
        if (existing != null) {
          // replace existing if editing
          final idx = festivals.indexOf(existing);
          if (idx != -1) festivals[idx] = newEvent;
        } else {
          festivals.add(newEvent);
        }
      });
    }
  }

  void _deleteEvent(int index) {
    setState(() => festivals.removeAt(index));
  }

  void _editEvent(int index) async {
    await openAddEvent(context, existing: festivals[index]);
  }

  void _viewDonations(int index) {
    final festival = festivals[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewDonationsPage(festival: festival),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return festivals.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No Events Added yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap + to create one',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
                      double progress =
                          (fest.collectedAmount / fest.targetAmount).clamp(
                            0,
                            1,
                          );

                      return Slidable(
                        key: ValueKey(fest.name),
                        closeOnScroll: true,
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio:
                              0.4, // controls how much space the actions take
                          children: [
                            SlidableAction(
                              onPressed: (context) => _editEvent(index),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            SlidableAction(
                              onPressed: (context) => _deleteEvent(index),
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
                        child: GestureDetector(
                          onTap: () => _viewDonations(index),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            margin: const EdgeInsets.symmetric(
                              vertical: 4, // reduced from 7 → 4
                              horizontal: 4,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: fest.isActive
                                      ? [
                                          Colors.deepOrange.shade700,
                                          Colors.orange.shade800,
                                        ]
                                      : const [
                                          Color(0xFF455A64),
                                          Color(0xFF607D8B),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(
                                12,
                              ), // reduced from 16 → 12
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row 1: Image + Title + Description
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            (fest.imageUrl != null &&
                                                fest.imageUrl!.isNotEmpty)
                                            ? Image.file(
                                                File(fest.imageUrl!),
                                                width: 55, // reduced from 60
                                                height: 55, // reduced from 60
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 55,
                                                height: 55,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.celebration,
                                                  size: 26,
                                                  color: fest.isActive
                                                      ? Colors
                                                            .deepOrange // when active
                                                      : Color(0xFF455A64),
                                                  //when deactive
                                                ),
                                              ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ), // reduced from 16
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Title: ${fest.name}",
                                              style: const TextStyle(
                                                fontSize: 16, // reduced from 18
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ), // reduced from 4
                                            Text(
                                              fest.description,
                                              style: const TextStyle(
                                                fontSize: 12, // reduced from 13
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8), // reduced from 12
                                  // Row 2: Start & End Dates
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Start: ${fest.startDate != null ? "${fest.startDate!.day}/${fest.startDate!.month}/${fest.startDate!.year}" : "N/A"}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "End: ${fest.endDate != null ? "${fest.endDate!.day}/${fest.endDate!.month}/${fest.endDate!.year}" : "N/A"}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6), // reduced from 8
                                  // Row 3: Target & Collected
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Target: ₹${fest.targetAmount}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Collected: ₹${fest.collectedAmount}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellowAccent,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6), // reduced from 10
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6, // reduced from 8
                                      backgroundColor: Colors.white24,
                                      color: Colors.yellowAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 4), // reduced from 6
                                  // Progress % + Active toggle
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${(progress * 100).toStringAsFixed(1)}% completed",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Transform.scale(
                                            scale:
                                                0.65, // slightly reduced switch size
                                            child: Switch.adaptive(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              value: fest.isActive,
                                              onChanged: (v) {
                                                setState(() {
                                                  fest.isActive = v;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            fest.isActive
                                                ? 'Active'
                                                : 'Deactive',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: fest.isActive
                                                  ? Colors.greenAccent
                                                  : Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 9, // reduced from 10
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: fest.isActive
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}
