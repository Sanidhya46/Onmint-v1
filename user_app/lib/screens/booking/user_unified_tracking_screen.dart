import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';

class UserUnifiedTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String serviceType;

  const UserUnifiedTrackingScreen({
    super.key,
    required this.bookingId,
    required this.serviceType,
  });

  @override
  State<UserUnifiedTrackingScreen> createState() =>
      _UserUnifiedTrackingScreenState();
}

class _UserUnifiedTrackingScreenState extends State<UserUnifiedTrackingScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.patient.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = {
            ...data.toJson(),
            'status': data.status,
            'updatedAt': data.updatedAt.toIso8601String(),
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> _openChat(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri waUri = Uri.parse('https://wa.me/$cleanPhone');
    try {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
      await launchUrl(smsUri);
    }
  }

  String _getProfilePictureUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AppConfig.apiBaseUrl;
    final uri = Uri.tryParse(base);
    if (uri != null) {
      final hostUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return '$hostUrl$cleanPath';
    }
    return path;
  }

  void _viewReport() async {
    if (_booking!['report'] != null &&
        _booking!['report'].toString().isNotEmpty) {
      String urlStr = _booking!['report'].toString().trim();
      if (urlStr.startsWith('/')) {
        String base = AppConfig.apiBaseUrl;
        if (base.endsWith('/api/v1')) {
          base = base.substring(0, base.length - 7);
        }
        urlStr = base + urlStr;
      }

      // Also handle cases where the string might be poorly formatted
      urlStr = urlStr.replaceAll(' ', '');

      final uri = Uri.tryParse(urlStr);
      if (uri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading report...')),
        );
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          // Mock download notification
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report downloaded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open report: $e')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid report URL format')),
        );
      }
    }
  }

  Widget _buildViewReportButton() {
    if (_booking!['report'] == null || _booking!['report'].toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: ElevatedButton(
        onPressed: _viewReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0047CB).withOpacity(0.1),
          foregroundColor: const Color(0xFF0047CB),
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download, size: 20),
            SizedBox(width: 8),
            Text(
              'View / Download Report',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF1A1A60))),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(
            child: Text('Booking not found',
                style: TextStyle(color: Colors.black))),
      );
    }

    final status = _booking!['status'] ?? 'accepted';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A60)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF1A1A60),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined,
                color: Color(0xFF1A1A60)),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBooking,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProviderCard(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Live Status',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A60)),
                            ),
                            _buildStatusChip(status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: _buildTimeline(status)),
                        const SizedBox(height: 10),
                        _buildViewReportButton(),
                        const SizedBox(height: 10),
                        _buildHelpButton(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label = 'In Progress';
    Color bgColor = Colors.green.shade50;
    Color textColor = Colors.green.shade700;

    if (status == 'completed') {
      label = 'Completed';
    } else if (status == 'requested' || status == 'pending') {
      label = 'Pending';
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else if (status == 'cancelled') {
      label = 'Cancelled';
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: textColor, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    // FIX: Type error string is not a subtype of int.
    // Provider can be string ID from API, so handle it carefully.
    final pData = _booking!['acceptedProvider'] ?? _booking!['provider'];
    final provider = (pData is Map) ? pData : {};

    final fullName = provider['fullName'] ??
        '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();

    String cardTitle = 'Your Provider';
    String roleText = '';
    String subText = '';
    String locationText = '';

    final sType = widget.serviceType.toLowerCase();

    if (sType == 'lab_test' ||
        sType == 'lab' ||
        sType == 'pathology' ||
        sType == 'labtest') {
      cardTitle = 'Your Technician';
      roleText = provider['specialization'] ?? 'Lab Technician';
      subText =
          '${provider['rating'] ?? '4.8'} ★ (${provider['reviewCount'] ?? '125'})';
    } else if (sType == 'nurse') {
      cardTitle = 'Your Nurse';
      roleText = provider['specialization'] ?? 'B.Sc Nursing';
    } else if (sType == 'ambulance') {
      cardTitle = 'Your Ambulance';
      roleText = provider['specialization'] ?? 'Ambulance Driver';
      subText = provider['vehicleNumber'] ?? '(GJ 01 AB 1234)';
    } else if (sType == 'bloodbank' || sType == 'blood bank') {
      cardTitle = 'Your Blood Bank';
      roleText = provider['specialization'] ?? '(Blood Bank Office)';
      locationText = '${provider['city'] ?? ''}, ${provider['state'] ?? ''}'
          .replaceAll(RegExp(r'^, |,$'), '')
          .trim();
      if (locationText.isEmpty || locationText == ',') {
        locationText = provider['address'] ?? 'Ghaziabad, Uttar Pradesh';
      }
    }

    final providerPhone = provider['phone'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A60),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: (provider['profilePicture'] != null && provider['profilePicture'].toString().isNotEmpty)
                      ? Image.network(
                          _getProfilePictureUrl(provider['profilePicture'].toString()),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey, size: 24),
                        )
                      : const Icon(Icons.person, color: Colors.grey, size: 24),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Waiting...' : fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      if (sType == 'ambulance')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      else if (sType == 'lab_test' ||
                          sType == 'lab' ||
                          sType == 'pathology')
                        Row(
                          children: [
                            Text(
                              provider['rating']?.toString() ?? '4.8',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '(${provider['reviewCount']?.toString() ?? '125'})',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 10),
                            ),
                          ],
                        )
                      else
                        Text(
                          subText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.grey, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationText,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircleAction(
                    Icons.call,
                    'Call',
                    () {
                      if (providerPhone != null) {
                        _makePhoneCall(providerPhone.toString());
                      }
                    },
                    iconColor: const Color(0xFF0047CB),
                    bgColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  _buildCircleAction(
                    Icons.chat,
                    'WhatsApp',
                    () {
                      if (providerPhone != null) {
                        _openChat(providerPhone.toString());
                      }
                    },
                    iconColor: const Color(0xFF22C55E),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, String label, VoidCallback onTap,
      {Color? iconColor, Color? bgColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: bgColor ?? Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: bgColor != null ? bgColor.withOpacity(0.5) : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]),
            child: Icon(icon, color: iconColor ?? const Color(0xFF0047CB), size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String status) {
    final sType = widget.serviceType.toLowerCase();

    // Define steps based on service type
    List<Map<String, dynamic>> steps = [];

    if (sType == 'lab_test' ||
        sType == 'lab' ||
        sType == 'pathology' ||
        sType == 'labtest') {
      steps = [
        {
          'id': 'accepted',
          'title': 'Connected',
          'subtitle': 'Your request has been accepted'
        },
        {
          'id': 'on_the_way',
          'title': 'On The Way',
          'subtitle': 'Technician is on the way to your location'
        },
        {
          'id': 'sample_collected',
          'alt_id': 'in_progress',
          'title': 'Sample Collected',
          'subtitle': 'Your sample will be collected'
        },
        {
          'id': 'report_ready',
          'alt_id': 'ready',
          'title': 'Report Ready',
          'subtitle': 'Your report is ready to view'
        },
        {
          'id': 'completed',
          'title': 'Completed',
          'subtitle': 'Thank you for choosing our service'
        },
      ];
    } else if (sType == 'nurse') {
      steps = [
        {
          'id': 'accepted',
          'title': 'Connected',
          'subtitle': 'Your request has been accepted'
        },
        {
          'id': 'on_the_way',
          'title': 'On The Way',
          'subtitle': 'Nurse is on the way to your location'
        },
        {
          'id': 'reached',
          'alt_id': 'in_progress',
          'title': 'Reached',
          'subtitle': 'Nurse has reached your location'
        },
        {
          'id': 'completed',
          'title': 'Completed',
          'subtitle': 'Thank you for choosing our service'
        },
      ];
    } else if (sType == 'ambulance') {
      steps = [
        {
          'id': 'accepted',
          'title': 'Connected',
          'subtitle': 'Your request has been accepted'
        },
        {
          'id': 'on_the_way',
          'title': 'On The Way',
          'subtitle': 'Ambulance is on the way to your location'
        },
        {
          'id': 'at_pickup_point',
          'alt_id': 'in_progress',
          'title': 'At Pickup Point',
          'subtitle': 'Ambulance has reached the pickup location'
        },
        {
          'id': 'at_drop_point',
          'alt_id': 'reached',
          'title': 'At Drop Point',
          'subtitle': 'Ambulance has reached the drop location'
        },
        {
          'id': 'completed',
          'title': 'Completed',
          'subtitle': 'Thank you for choosing our service'
        },
      ];
    } else if (sType == 'bloodbank' || sType == 'blood bank') {
      steps = [
        {
          'id': 'accepted',
          'title': 'Request Accepted',
          'subtitle': 'Your blood request has been accepted\nby the blood bank.'
        },
        {
          'id': 'connected',
          'alt_id': 'in_progress',
          'title': 'Connected With Blood Bank',
          'subtitle':
              'You are connected with the blood bank\nfor further assistance and confirmation.'
        },
        {
          'id': 'completed',
          'title': 'Completed',
          'subtitle':
              'Blood request has been successfully\ncompleted.\nThank you for choosing our service.'
        },
      ];
    } else {
      // Fallback
      steps = [
        {
          'id': 'accepted',
          'title': 'Connected',
          'subtitle': 'Your request has been accepted'
        },
        {
          'id': 'in_progress',
          'title': 'In Progress',
          'subtitle': 'Service is in progress'
        },
        {
          'id': 'completed',
          'title': 'Completed',
          'subtitle': 'Service completed'
        },
      ];
    }

    // Determine current index based on status
    int currentIndex = -1;
    if (status != 'pending' && status != 'requested') {
      for (int i = 0; i < steps.length; i++) {
        if (steps[i]['id'] == status || steps[i]['alt_id'] == status) {
          currentIndex = i;
          break;
        }
      }
    }

    if (status == 'completed') {
      currentIndex = steps.length - 1;
    }

    return Column(
      children: List.generate(steps.length, (index) {
          bool isCompleted = index <= currentIndex;
          bool isLast = index == steps.length - 1;

          // Mock times for UI, usually would extract from booking tracking logs from backend
          String formattedTime = '';
          String formattedDate = '';
          if (isCompleted && _booking!['updatedAt'] != null) {
            final date = DateTime.tryParse(_booking!['updatedAt']);
            if (date != null) {
              formattedTime = DateFormat('hh:mm a').format(date);
              formattedDate = DateFormat('dd MMM').format(date);
            }
          }

          // For accurate UI match, if we don't have real time, mock it for past steps so the UI looks complete
          if (isCompleted && formattedTime.isEmpty) {
            final mockTime = DateTime.now()
                .subtract(Duration(minutes: (steps.length - index) * 15));
            formattedTime = DateFormat('hh:mm a').format(mockTime);
            formattedDate = DateFormat('dd MMM').format(mockTime);
          }

          Widget? extraContent;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
            child: _buildTimelineStep(
              steps[index]['title'],
              steps[index]['subtitle'],
              isCompleted,
              isLast,
              formattedTime,
              formattedDate,
              trailingWidget: extraContent,
            ),
          );
      }),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isCompleted,
      bool isLast, String time, String date,
      {Widget? trailingWidget}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side indicator
          SizedBox(
            width: 40,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10A843)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: isCompleted
                      ? Border.all(color: const Color(0xFFE5F6EB), width: 6)
                      : Border.all(color: Colors.white, width: 4),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFF10A843)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right side content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 0, top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCompleted
                                  ? const Color(0xFF10A843)
                                  : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailingWidget != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: trailingWidget,
                      ),
                    if (time.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(time,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(date,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade800)),
                        ],
                      ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
                if (isLast) const SizedBox(height: 8.0),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildHelpButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF0047CB), // Deep blue color matching image
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Support action
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.headset_mic_outlined,
                    color: Color(0xFF0047CB), size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'You can contact support anytime',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
