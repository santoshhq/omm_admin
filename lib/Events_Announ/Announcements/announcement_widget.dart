import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'announcement_module.dart';

/// ------------------- Announcement List -------------------
class AnnouncementContent extends StatefulWidget {
  const AnnouncementContent({super.key});

  @override
  AnnouncementContentState createState() => AnnouncementContentState();
}

class AnnouncementContentState extends State<AnnouncementContent> {
  final List<Announcement> _announcements = [];

  void addAnnouncement(Announcement a) {
    setState(() => _announcements.insert(0, a));
  }

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
      setState(() {
        if (existing != null) {
          final idx = _announcements.indexOf(existing);
          if (idx != -1) _announcements[idx] = result;
        } else {
          _announcements.insert(0, result);
        }
      });
    }
  }

  void _deleteAnnouncement(int index) {
    setState(() => _announcements.removeAt(index));
  }

  Future<void> _editAnnouncement(int index) async {
    await openComposeSheet(context, existing: _announcements[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.campaign, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No announcements yet',
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
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final a = _announcements[i];
        return Slidable(
          key: ValueKey(a.createdAt.millisecondsSinceEpoch),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.36,
            children: [
              SlidableAction(
                onPressed: (ctx) => _editAnnouncement(i),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                // label: 'Edit',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              SlidableAction(
                onPressed: (ctx) => _deleteAnnouncement(i),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                // label: 'Delete',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ],
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
            color: a.isActive ? Colors.blue.shade100 : Colors.grey.shade200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Title & Priority =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _priorityColor(a.priority),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          a.priority,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ===== Description =====
                  Text(
                    a.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // ===== Footer =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${a.createdAt.toLocal()}'.split('.')[0],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Text(
                            a.isActive ? "Active" : "Deactive",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: a.isActive ? Colors.blue : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Switch.adaptive(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            value: a.isActive,
                            onChanged: (v) {
                              setState(() {
                                a.isActive = v;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}

/// ------------------- Full-page with FAB -------------------
class AnnouncementPage extends StatelessWidget {
  final GlobalKey<AnnouncementContentState>? contentKey;

  const AnnouncementPage({super.key, this.contentKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: contentKey != null
          ? AnnouncementContent(key: contentKey)
          : const AnnouncementContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<Announcement>(
            MaterialPageRoute(builder: (_) => AnnouncementComposePage()),
          );
          if (result != null) {
            contentKey?.currentState?.addAnnouncement(result);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("New"),
      ),
    );
  }
}

/// ------------------- Compose New Announcement -------------------
class AnnouncementComposePage extends StatefulWidget {
  final Announcement? existing;

  AnnouncementComposePage({super.key, this.existing});

  @override
  State<AnnouncementComposePage> createState() =>
      _AnnouncementComposePageState();
}

class _AnnouncementComposePageState extends State<AnnouncementComposePage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  String _priority = 'Medium';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _title.text = widget.existing!.title;
      _desc.text = widget.existing!.description;
      _priority = widget.existing!.priority;
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
              // Title
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.title),
                  hintText: 'Enter title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: TextField(
                  controller: _desc,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.notes),
                    hintText: 'Write details...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Priority Chips
              const Text(
                "Priority",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('High'),
                    selected: _priority == 'High',
                    selectedColor: Colors.red,
                    onSelected: (_) => setState(() => _priority = 'High'),
                  ),
                  ChoiceChip(
                    label: const Text('Medium'),
                    selected: _priority == 'Medium',
                    selectedColor: Colors.orange,
                    onSelected: (_) => setState(() => _priority = 'Medium'),
                  ),
                  ChoiceChip(
                    label: const Text('Low'),
                    selected: _priority == 'Low',
                    selectedColor: Colors.green,
                    onSelected: (_) => setState(() => _priority = 'Low'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Post Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final ann = Announcement(
                      title: _title.text.trim(),
                      description: _desc.text.trim(),
                      priority: _priority,
                    );
                    if (ann.title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }
                    Navigator.pop(context, ann);
                  },
                  icon: const Icon(Icons.send, size: 20, color: Colors.white),
                  label: Text(
                    widget.existing != null
                        ? 'Save Changes'
                        : 'Post Announcement',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
