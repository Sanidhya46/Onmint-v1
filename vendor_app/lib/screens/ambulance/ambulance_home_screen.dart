import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'ride_requests_screen.dart';
import 'ride_details_screen.dart';
import 'fill_price_ambulance_screen.dart';
import '../booking/waiting_for_patient_screen.dart';

/// Ambulance home screen - Main dashboard for ambulance drivers
class AmbulanceHomeScreen extends StatefulWidget {
  const AmbulanceHomeScreen({super.key});

  @override
  State<AmbulanceHomeScreen> createState() => _AmbulanceHomeScreenState();
}

class _AmbulanceHomeScreenState extends State<AmbulanceHomeScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isAvailable = true;
  List<Map<String, dynamic>> _recentRequests = [];
  bool _showAllRequests = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final stats = await _apiClient.ambulance.getDashboard();
      final requestsData = await _apiClient.ambulance.getRideRequests(
        status: 'all',
        page: 1,
        limit: 10,
      );
      
      final requests = <Map<String, dynamic>>[];
      if (requestsData['data'] is List) {
        for (var e in requestsData['data']) {
          requests.add(Map<String, dynamic>.from(e));
        }
      }
      // Sort newest first
      requests.sort((a, b) {
        final timeA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
        final timeB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
        return timeB.compareTo(timeA);
      });

      setState(() {
        _stats = stats.toJson();
        _isAvailable = _stats?['isAvailable'] ?? true;
        _recentRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      await _apiClient.ambulance.setAvailability(!_isAvailable);
      setState(() => _isAvailable = !_isAvailable);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAvailable ? 'You are now available for rides' : 'You are now offline'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final driverName = user != null
        ? '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim()
        : 'Driver';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE52329)))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: CustomScrollView(
                slivers: [
                  // Red gradient header
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE52329), Color(0xFFB71C1C)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: greeting + notification
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello, $driverName 👋',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Ambulance Driver Dashboard',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Availability toggle card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: _isAvailable ? Colors.green : Colors.red.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isAvailable ? Icons.check : Icons.close,
                                        color: Colors.white, size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isAvailable ? 'Available for Rides' : 'You are Offline',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            _isAvailable ? 'Receiving emergency requests' : 'Not receiving requests',
                                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _isAvailable,
                                      onChanged: (value) => _toggleAvailability(),
                                      activeColor: Colors.green,
                                      activeTrackColor: Colors.green.shade200,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Stats cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(child: _buildStatCard('Today\'s Rides', '${_stats?['todayRides'] ?? 0}', Icons.local_shipping, const Color(0xFFE52329))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard('Pending', '${_stats?['pendingRides'] ?? 0}', Icons.pending_actions, Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(child: _buildStatCard('Completed', '${_stats?['completedRides'] ?? 0}', Icons.check_circle_outline, Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatCard('Earnings', '₹${_stats?['totalEarnings'] ?? 0}', Icons.account_balance_wallet_outlined, const Color(0xFF7B1FA2))),
                        ],
                      ),
                    ),
                  ),

                  // Recent Requests section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Requests',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF152238)),
                          ),
                          if (_recentRequests.length > 1)
                            GestureDetector(
                              onTap: () {
                                if (_showAllRequests) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RideRequestsScreen()));
                                } else {
                                  setState(() => _showAllRequests = true);
                                }
                              },
                              child: Text(
                                _showAllRequests ? 'View All →' : 'View All',
                                style: const TextStyle(color: Color(0xFFE52329), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Request cards - show 1 initially, expand on View All
                  if (_recentRequests.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No requests yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final request = _recentRequests[index];
                          return _buildRequestCard(request);
                        },
                        childCount: _showAllRequests
                            ? _recentRequests.length
                            : (_recentRequests.isNotEmpty ? 1 : 0),
                      ),
                    ),

                  // Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: const Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF152238)),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildActionButton(
                            'View All Ride Requests',
                            Icons.list_alt,
                            const Color(0xFFE52329),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideRequestsScreen())),
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            'Emergency Contacts',
                            Icons.phone_in_talk,
                            Colors.orange,
                            () {},
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final patient = request['patient'] ?? {};
    String pName = 'Patient';
    if (patient is Map) {
      pName = patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    }
    if (pName.isEmpty) pName = 'Patient';
    
    final statusRaw = request['status']?.toString().toLowerCase() ?? '';
    final bookingId = request['_id']?.toString() ?? request['id']?.toString() ?? '';
    
    Color statusColor;
    String statusLabel;
    if (statusRaw == 'requested' || statusRaw == 'pending') {
      statusColor = Colors.orange;
      statusLabel = 'Pending';
    } else if (statusRaw == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Completed';
    } else if (statusRaw == 'cancelled' || statusRaw == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'Cancelled';
    } else {
      statusColor = const Color(0xFF1565C0);
      statusLabel = 'In Progress';
    }

    final locRaw = request['location'];
    String address;
    if (locRaw is Map) {
      final addr = locRaw['address'];
      if (addr is Map) {
        address = addr['address']?.toString() ?? addr['street']?.toString() ?? 'Not specified';
      } else {
        address = addr?.toString() ?? locRaw['street']?.toString() ?? 'Not specified';
      }
    } else {
      address = locRaw?.toString() ?? 'Not specified';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          Widget targetScreen;
          if (statusRaw == 'requested' || statusRaw == 'pending') {
            final hasOffered = request['offers'] != null && (request['offers'] as List).any((offer) => offer['vendor'] == ApiClient.userId);
            if (hasOffered) {
              targetScreen = WaitingForPatientScreen(bookingId: bookingId, bookingData: request);
            } else {
              targetScreen = FillPriceAmbulanceScreen(bookingId: bookingId, bookingData: request);
            }
          } else {
            targetScreen = RideDetailsScreen(rideId: bookingId);
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => targetScreen),
          );
          if (result == true) _loadDashboard();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping, color: Color(0xFFE52329), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
