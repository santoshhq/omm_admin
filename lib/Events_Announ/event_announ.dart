import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:omm_admin/Events_Announ/events/add_event.dart';
import 'package:omm_admin/Events_Announ/events/festival_widget.dart';
import 'package:omm_admin/Events_Announ/announcements/announcement_widget.dart';
import 'package:omm_admin/Events_Announ/announcements/announcement_module.dart';

class Event_Announ extends StatefulWidget {
  const Event_Announ({super.key});

  @override
  State<Event_Announ> createState() => _Event_AnnountState();
}

class _Event_AnnountState extends State<Event_Announ> {
  // (priority handled by announcement composer)
  bool _showEvents = true; // default selected tab: Events
  final GlobalKey<FestivalContentState> _festivalKey =
      GlobalKey<FestivalContentState>();
  final GlobalKey<AnnouncementContentState> _announcementKey =
      GlobalKey<AnnouncementContentState>();

  // Announcement composer is opened as a full-screen page now.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------- Floating Add (+) Button ----------
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15), // ✅ move button upward
        child: SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: const Color(0xFF455A64),
          foregroundColor: Colors.white, // "+" icon in white
          overlayColor: Colors.black,
          overlayOpacity: 0.4,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.event, color: Colors.white),
              backgroundColor: Colors.deepOrange,
              label: 'Add Event',
              onTap: () {
                // If Events tab is active, open add event within the embedded FestivalContent
                if (_showEvents) {
                  _festivalKey.currentState?.openAddEvent(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEventPage(),
                    ),
                  );
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.campaign, color: Colors.white),
              backgroundColor: Colors.blue,
              label: 'Announcement',
              onTap: () async {
                // Open full-screen composer and add returned announcement to list
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AnnouncementComposePage()),
                );
                if (result is Announcement) {
                  // switch to announcements tab and insert
                  setState(() => _showEvents = false);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _announcementKey.currentState?.addAnnouncement(result);
                  });
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      appBar: AppBar(title: const Text("Events & Announcements")),
      body: Column(
        children: [
          // Toggle row under AppBar: Events | Announcements
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showEvents = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showEvents ? Colors.deepOrange : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          'Events',
                          style: TextStyle(
                            color: _showEvents ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showEvents = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showEvents ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          'Announcements',
                          style: TextStyle(
                            color: !_showEvents ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: _showEvents
                ? FestivalContent(key: _festivalKey)
                : AnnouncementContent(key: _announcementKey),
          ),
        ],
      ),
    );
  }

  // Announcements view is now provided by AnnouncementContent widget.
}
