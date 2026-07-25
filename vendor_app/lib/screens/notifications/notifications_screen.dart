import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

/// Vendor App Notifications Screen - Modern, Dynamic & Service-Aware
class VendorNotificationsScreen extends StatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  State<VendorNotificationsScreen> createState() => _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
  final OnMintApiClient _apiClient = OnMintApiClient();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await _apiClient.get('/auth/notifications');
      List rawList = [];
      if (res.data != null && res.data['data'] != null) {
        if (res.data['data'] is List) {
          rawList = res.data['data'];
        } else if (res.data['data'] is Map && res.data['data']['notifications'] != null) {
          rawList = res.data['data']['notifications'];
        }
      }

      if (mounted) {
        setState(() {
          _notifications = rawList.map((n) {
            final Map<String, dynamic> item = Map<String, dynamic>.from(n as Map);
            DateTime parsedTime = DateTime.now();
            if (item['createdAt'] != null) {
              try {
                parsedTime = DateTime.parse(item['createdAt'].toString()).toLocal();
              } catch (_) {}
            }
            return {
              'id': item['_id']?.toString() ?? '',
              'title': item['title']?.toString() ?? 'Partner Notification',
              'body': item['message']?.toString() ?? '',
              'type': item['type']?.toString() ?? 'general',
              'serviceType': item['data']?['serviceType']?.toString() ?? item['type']?.toString() ?? 'general',
              'time': parsedTime,
              'read': item['isRead'] == true,
            };
          }).toList();
          _isLoading = false;
        });
      }
      return;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiClient.post('/auth/notifications/read-all');
    } catch (_) {}
    if (mounted) {
      setState(() {
        for (var n in _notifications) {
          n['read'] = true;
        }
      });
    }
  }

  Future<void> _markSingleAsRead(Map<String, dynamic> notification) async {
    if (notification['read'] == true) return;
    final id = notification['id'];
    if (id != null && id.isNotEmpty) {
      try {
        await _apiClient.post('/auth/notifications/$id/read');
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        notification['read'] = true;
      });
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final hour = localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour);
      final period = localTime.hour >= 12 ? 'PM' : 'AM';
      final minute = localTime.minute.toString().padLeft(2, '0');
      return '${localTime.day}/${localTime.month}/${localTime.year}, $hour:$minute $period';
    }
  }

  Map<String, dynamic> _getServiceStyle(String type, String serviceType) {
    final t = '$type $serviceType'.toLowerCase();
    if (t.contains('doctor') || t.contains('consultation')) {
      return {
        'icon': Icons.medical_services_rounded,
        'badge': 'Doctor Booking',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
      };
    } else if (t.contains('nurse')) {
      return {
        'icon': Icons.healing_rounded,
        'badge': 'Nurse Request',
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFF0FDFA),
      };
    } else if (t.contains('ambulance') || t.contains('emergency')) {
      return {
        'icon': Icons.airport_shuttle_rounded,
        'badge': 'Ambulance Call',
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEF2F2),
      };
    } else if (t.contains('pharmacist') || t.contains('pharmacy') || t.contains('medicine') || t.contains('order')) {
      return {
        'icon': Icons.shopping_bag_rounded,
        'badge': 'Medicine Order',
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEE),
      };
    } else if (t.contains('pathology') || t.contains('lab') || t.contains('report')) {
      return {
        'icon': Icons.science_rounded,
        'badge': 'Lab Request',
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      };
    } else if (t.contains('blood') || t.contains('bank')) {
      return {
        'icon': Icons.bloodtype_rounded,
        'badge': 'Blood Request',
        'color': const Color(0xFFE11D48),
        'bg': const Color(0xFFFFE4E6),
      };
    } else if (t.contains('registration') || t.contains('account')) {
      return {
        'icon': Icons.verified_user_rounded,
        'badge': 'Registration',
        'color': const Color(0xFF4F46E5),
        'bg': const Color(0xFFEEF2FF),
      };
    } else {
      return {
        'icon': Icons.notifications_active_rounded,
        'badge': 'Partner Notification',
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFF0F9FF),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partner Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount new update${unreadCount > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
              ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF2563EB)),
              label: const Text(
                'Mark all read',
                style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_off_rounded, size: 48, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Partner Notifications',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'New booking requests and service alerts will appear here.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['read'] == true;
    final DateTime time = notification['time'] as DateTime;
    final String type = notification['type'] as String;
    final String serviceType = notification['serviceType'] as String;
    final style = _getServiceStyle(type, serviceType);

    final IconData iconData = style['icon'] as IconData;
    final String badgeText = style['badge'] as String;
    final Color brandColor = style['color'] as Color;
    final Color iconBg = style['bg'] as Color;

    return GestureDetector(
      onTap: () => _markSingleAsRead(notification),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF4F7FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : brandColor.withOpacity(0.3),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isRead ? Colors.black.withOpacity(0.02) : brandColor.withOpacity(0.08),
              blurRadius: isRead ? 4 : 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Line for Unread Status
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: isRead ? 0 : 5,
                decoration: BoxDecoration(
                  color: brandColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Circle
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: brandColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      color: brandColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Time
                                Text(
                                  _formatRelativeTime(time),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isRead ? Colors.grey.shade500 : brandColor,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Title
                            Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: isRead ? const Color(0xFF334155) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Body Message
                            Text(
                              notification['body'],
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isRead ? Colors.grey.shade600 : const Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: brandColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
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
