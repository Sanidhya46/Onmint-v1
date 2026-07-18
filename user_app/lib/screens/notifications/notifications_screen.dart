import 'package:flutter/material.dart';

/// Notifications screen - View all notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock notifications data
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Appointment Confirmed',
      'body':
          'Your appointment with Dr. Smith is confirmed for tomorrow at 10:00 AM',
      'type': 'appointment',
      'time': DateTime.now().subtract(const Duration(hours: 2)),
      'read': false,
    },
    {
      'id': '2',
      'title': 'Prescription Ready',
      'body': 'Your prescription is ready for pickup at City Pharmacy',
      'type': 'prescription',
      'time': DateTime.now().subtract(const Duration(hours: 5)),
      'read': false,
    },
    {
      'id': '3',
      'title': 'Lab Report Available',
      'body': 'Your blood test results are now available',
      'type': 'report',
      'time': DateTime.now().subtract(const Duration(days: 1)),
      'read': true,
    },
    {
      'id': '4',
      'title': 'Payment Successful',
      'body': 'Your payment of ₹500 has been processed successfully',
      'type': 'payment',
      'time': DateTime.now().subtract(const Duration(days: 2)),
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationCard(notification);
              },
            )),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] as bool;
    final time = notification['time'] as DateTime;
    final type = notification['type'] as String;

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'appointment':
        icon = Icons.event;
        iconColor = Colors.blue;
        break;
      case 'prescription':
        icon = Icons.medication;
        iconColor = Colors.green;
        break;
      case 'report':
        icon = Icons.description;
        iconColor = Colors.purple;
        break;
      case 'payment':
        icon = Icons.payment;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.remove(notification);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: isRead ? null : Colors.blue.shade50,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            notification['title'],
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification['body']),
              const SizedBox(height: 4),
              Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            setState(() {
              notification['read'] = true;
            });
            // TODO: Navigate to relevant screen
          },
        ),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
