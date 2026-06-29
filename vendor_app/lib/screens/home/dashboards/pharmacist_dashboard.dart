import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import '../../../config/app_colors.dart';
import '../../pharmacist/pending_orders_screen.dart';
import '../../pharmacist/pending_order_details_screen.dart';

class PharmacistDashboard extends StatefulWidget {
  const PharmacistDashboard({super.key});

  @override
  State<PharmacistDashboard> createState() => _PharmacistDashboardState();
}

class _PharmacistDashboardState extends State<PharmacistDashboard> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _pendingOrders = [];
  bool _isLoading = true;
  bool _showAllOrders = false; // Added to expand orders inline

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (_dashboardData == null) {
      setState(() => _isLoading = true);
    }
    try {
      await _apiClient.initialize();
      // Using RealTimeBooking APIs to get dashboard and pending orders
      final dashResp = await _apiClient.get('/realtime/provider/dashboard');
      final ordersResp = await _apiClient.get('/realtime/provider/bookings', queryParameters: {
        'status': 'requested',
        // 'limit': 5, // Removed limit to fetch all and expand inline
      });

      setState(() {
        _dashboardData = dashResp.data['data'];
        _pendingOrders = ordersResp.data['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Dashboard error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(user),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildOrdersHeader(),
                          const SizedBox(height: 12),
                          _buildOrdersList(),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildInfoBanner(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    final stats = _dashboardData ?? {};
    final active = stats['activeBookings'] ?? 0;
    final completed = stats['completedBookings'] ?? 0;
    final pending = stats['pendingRequests'] ?? 0;
    
    return SliverToBoxAdapter(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 60),
            decoration: const BoxDecoration(
              color: Color(0xFF0033CC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: user?.profilePictureUrl != null && user!.profilePictureUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Image.network(
                              user.profilePictureUrl!,
                              fit: BoxFit.cover,
                              width: 70,
                              height: 70,
                              errorBuilder: (c, e, s) => Image.asset('assets/images/logos/pharmacy_logo.png'),
                            ),
                          )
                        : Image.asset(
                            'assets/images/logos/pharmacy_logo.png', // Fallback, using icon if not exist
                            errorBuilder: (c, e, s) => const Icon(Icons.local_pharmacy, color: Colors.green, size: 40),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Pharmacy Store',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '( Licensed Pharmacy )',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('${pending + active + completed}', "Today's Orders"),
                  _buildDivider(),
                  _buildStatItem('$active', 'Accepted'),
                  _buildDivider(),
                  _buildStatItem('$completed', 'Delivered'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001F4D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.blue,
    );
  }

  Widget _buildOrdersHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0), // Space for overlapping stat box
      child: Row(
        children: [
          const Text(
            'New Medicine Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          if (_pendingOrders.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${_dashboardData?['pendingRequests'] ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Spacer(),
          if (_pendingOrders.length > 1)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllOrders = !_showAllOrders;
                });
              },
              child: Text(
                _showAllOrders ? 'View Less' : 'View All',
                style: const TextStyle(
                  color: Color(0xFF0033CC),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_pendingOrders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No new orders at the moment.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final displayOrders = _showAllOrders ? _pendingOrders : _pendingOrders.take(1).toList();

    return Column(
      children: displayOrders.map((order) {
        return _buildOrderCard(order);
      }).toList(),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    // Determine order type
    bool isPrescriptionBased = order['isPrescriptionBased'] == true;
    bool isDirect = !isPrescriptionBased;
    String tag = isDirect ? 'Direct Order' : 'Prescription Order';
    Color tagColor = isDirect ? Colors.green[50]! : Colors.blue[50]!;
    Color tagTextColor = isDirect ? Colors.green[700]! : Colors.blue[700]!;

    int itemsCount = (order['medicines'] as List?)?.length ?? 0;
    
    // Formatting time
    String timeStr = '';
    if (order['createdAt'] != null) {
      final dt = DateTime.parse(order['createdAt']).toLocal();
      timeStr = '${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: order['patient']?['profilePic'] != null 
                      ? NetworkImage(order['patient']['profilePic'])
                      : null,
                  child: order['patient']?['profilePic'] == null 
                      ? const Icon(Icons.person, color: Colors.grey, size: 24)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              order['patientName'] ?? 'Unknown Patient',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF001F4D)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: tagTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isDirect ? '$itemsCount Medicines Ordered' : 'Prescription Medicines',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order['patientAge'] ?? 0} Years / ${order['patientGender'] ?? "Unknown"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 30),
                    Text(
                      '₹${order['price'] ?? order['totalAmount'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0033CC),
                      ),
                    ),
                    const Text(
                      'Order Amount',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PendingOrderDetailsScreen(order: order),
                    ),
                  ).then((_) => _loadDashboard());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0033CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_add, size: 28, color: Color(0xFF0033CC)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Manage Your Orders Easily',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001F4D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check orders, deliveries, and inventory in one place.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF0033CC) : Colors.grey[300],
      ),
    );
  }
}
