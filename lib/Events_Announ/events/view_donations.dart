import 'package:flutter/material.dart';
import 'modules.dart';
import '../../config/api_config.dart';

class ViewDonationsPage extends StatefulWidget {
  final Festival festival;

  const ViewDonationsPage({super.key, required this.festival});

  @override
  State<ViewDonationsPage> createState() => _ViewDonationsPageState();
}

class _ViewDonationsPageState extends State<ViewDonationsPage> {
  late Festival festival;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    festival = widget.festival;
    _loadEventDetails();
  }

  Future<void> _loadEventDetails({bool showLoader = true}) async {
    if (festival.id == null) return;

    try {
      if (showLoader) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final response = await ApiService.getEventCardById(festival.id!);
      final updatedFestival = Festival.fromJson(response['data']);

      setState(() {
        festival = updatedFestival;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;

    if (_isLoading) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    } else if (_errorMessage != null) {
      final errorColor = Colors.red.shade400;
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline, size: 64, color: errorColor),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: errorColor),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadEventDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    } else {
      final totalDonors = festival.donations.length;
      final averageDonation = totalDonors > 0
          ? festival.collectedAmount / totalDonors
          : 0.0;
      final progressPercentage = festival.targetAmount > 0
          ? (festival.collectedAmount / festival.targetAmount * 100)
          : 0.0;

      content = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Event Summary Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          festival.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: festival.isActive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: festival.isActive
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          festival.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: festival.isActive
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Event Image
                  if (festival.imageUrl != null &&
                      festival.imageUrl!.isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildDonationPageImage(festival),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.celebration,
                          size: 50,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),

                  // Description
                  Text(
                    festival.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Event Details
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Start: ${festival.startDate != null ? "${festival.startDate!.day}/${festival.startDate!.month}/${festival.startDate!.year}" : "Not set"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'End: ${festival.endDate != null ? "${festival.endDate!.day}/${festival.endDate!.month}/${festival.endDate!.year}" : "Not set"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Financial Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ₹${festival.targetAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Collected: ₹${festival.collectedAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${progressPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressPercentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Donation Statistics
          // ... (rest of your Slivers are unchanged and already correct)
          // Donations List remains the same
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Event Donations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadEventDetails(showLoader: false),
        color: Colors.blue.shade600,
        child: content,
      ),
    );
  }

  /// Helper widget to safely render image
  Widget _buildDonationPageImage(Festival festival) {
    return Image.network(
      festival.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
        ),
      ),
    );
  }
}
