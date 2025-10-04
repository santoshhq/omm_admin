import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:omm_admin/Events_Announ/events/add_event.dart';
import 'package:omm_admin/Events_Announ/events/festival_widget.dart';
import 'package:omm_admin/Events_Announ/announcements/announcement_widget.dart';
import 'package:omm_admin/Events_Announ/announcements/announcement_module.dart';

class EventAnnoun extends StatefulWidget {
  const EventAnnoun({super.key});

  @override
  State<EventAnnoun> createState() => _EventAnnounState();
}

class _EventAnnounState extends State<EventAnnoun> {
  bool _showEvents = true; // default tab
  final GlobalKey<FestivalContentState> _festivalKey =
      GlobalKey<FestivalContentState>();
  final GlobalKey<AnnouncementContentState> _announcementKey =
      GlobalKey<AnnouncementContentState>();

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.event, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events & Announcements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage community updates',
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
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
              onPressed: () {
                // Refresh the current view
                setState(() {
                  // Force rebuild to refresh data
                });
              },
              tooltip: 'Refresh Events & Announcements',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Professional spacing from AppBar
          const SizedBox(height: 16),
          _buildToggleTabs(),
          Expanded(
            child: _showEvents
                ? FestivalContent(key: _festivalKey)
                : AnnouncementContent(key: _announcementKey),
          ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildToggleTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildTab(
            label: 'Events',
            isSelected: _showEvents,
            color: Colors.deepOrange,
            onTap: () {
              if (!_showEvents && mounted) {
                setState(() => _showEvents = true);
              }
            },
          ),
          const SizedBox(width: 12),
          _buildTab(
            label: 'Announcements',
            isSelected: !_showEvents,
            color: Colors.blue,
            onTap: () {
              if (_showEvents && mounted) {
                setState(() => _showEvents = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        animatedIconTheme: const IconThemeData(size: 22),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.event, color: Colors.white),
            backgroundColor: Colors.deepOrange,
            label: 'Add Event',
            onTap: () {
              if (_showEvents) {
                _festivalKey.currentState?.openAddEvent(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEventPage()),
                );
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.campaign, color: Colors.white),
            backgroundColor: Colors.blue,
            label: 'Announcement',
            onTap: _openAnnouncementComposer,
          ),
        ],
      ),
    );
  }

  Future<void> _openAnnouncementComposer() async {
    final Announcement? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnnouncementComposePage()),
    );

    if (!mounted) return;

    // If announcement was created successfully, switch to announcements tab
    if (result != null) {
      setState(() => _showEvents = false);
      // Add the new announcement optimistically to the list
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _announcementKey.currentState?.addOptimisticAnnouncement(result);
      });
    }
  }
}
