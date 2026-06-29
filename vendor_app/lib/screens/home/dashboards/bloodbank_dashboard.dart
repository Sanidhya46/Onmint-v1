import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import '../../blood_bank/blood_request_details_screen.dart';
import '../../blood_bank/blood_bank_bookings_screen.dart';

class BloodBankDashboard extends StatefulWidget {
  const BloodBankDashboard({super.key});

  @override
  State<BloodBankDashboard> createState() => _BloodBankDashboardState();
}

class _BloodBankDashboardState extends State<BloodBankDashboard> {
  bool _isLoading = false;
  final _apiClient = OnMintApiClient();
  List<dynamic> _requests = [];
  int _totalRequests = 0;
  int _acceptedRequests = 0;
  int _completedRequests = 0;
  bool _showAllRequests = false;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _loadDashboard();
  }

  /// Safely extract address string from any type (String, Map, int, etc.)
  String _safeAddress(dynamic loc, [String fallback = 'Not specified']) {
    if (loc == null) return fallback;
    if (loc is String) return loc.isEmpty ? fallback : loc;
    if (loc is Map) {
      final addr = loc['address'];
      if (addr is Map) {
        return addr['address']?.toString() ??
            addr['street']?.toString() ??
            fallback;
      }
      if (addr != null) return addr.toString();
      return loc['street']?.toString() ??
          loc['city']?.toString() ??
          fallback;
    }
    return loc.toString();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      // Fetch ALL bookings without status filter — filter locally
      final res = await _apiClient.get('/realtime/provider/bookings',
          queryParameters: {
            'serviceType': 'bloodbank',
            'limit': 100,
          });

      if (mounted) {
        final data = res.data['data'] ?? [];
        final List<dynamic> all = data is List ? List.from(data) : [];

        // Sort newest first
        all.sort((a, b) {
          final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
          final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
          return tb.compareTo(ta);
        });

        final pending = all.where((b) {
          final s = b['status']?.toString().toLowerCase() ?? '';
          return s == 'requested' || s == 'pending';
        }).toList();

        final accepted = all.where((b) {
          final s = b['status']?.toString().toLowerCase() ?? '';
          return s == 'accepted' || s == 'in_progress' || s == 'processing';
        }).toList();

        final completed = all.where((b) {
          final s = b['status']?.toString().toLowerCase() ?? '';
          return s == 'completed';
        }).toList();

        setState(() {
          _requests = pending;
          _totalRequests = all.length;
          _acceptedRequests = accepted.length;
          _completedRequests = completed.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(user),
                            const SizedBox(height: 10),
                            _buildStatsRow(),
                            const SizedBox(height: 12),
                            _buildNewRequestsSection(),
                            const Spacer(),
                            _buildManageConsultationsCard(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
    );
  }

  Widget _buildHeader(User user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC62828), Color(0xFF8B1A1A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: user.profilePictureUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Image.network(user.profilePictureUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.business, color: Colors.grey, size: 36)),
                      )
                    : const Icon(Icons.business, color: Color(0xFFC62828), size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : 'Blood Bank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Blood Bank Vendor',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.address?.fullAddress ?? 'Location not set',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Notification bell
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('$_totalRequests', "Total\nRequests"),
            Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
            _buildStatItem('${_requests.length}', 'Pending'),
            Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
            _buildStatItem('$_completedRequests', 'Completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC62828),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNewRequestsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'New Blood Requests',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF152238),
                ),
              ),
              const SizedBox(width: 8),
              if (_requests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_requests.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              if (_requests.length > 1)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAllRequests = !_showAllRequests;
                    });
                  },
                  child: Text(
                    _showAllRequests ? 'View Less' : 'View All',
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_requests.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No pending blood requests',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Pull down to refresh',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            )
          else
            Column(
              children: _requests
                  .take(_showAllRequests ? _requests.length : 1)
                  .map((r) => _buildRequestCard(r))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic request) {
    final patient = request['patientDetails'] ?? {};
    final pName = (patient is Map)
        ? (patient['fullName'] ??
            '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim())
        : 'Patient';
    final age = (patient is Map) ? patient['age'] ?? '--' : '--';
    final gender = (patient is Map) ? patient['gender'] ?? 'Male' : 'Male';
    final units = request['unitsRequired'] ?? '1';
    final hospital = _safeAddress(request['location'], 'Location not specified');
    final bloodGroup = request['bloodGroup'] ?? 'O+';
    final bookingId = request['_id']?.toString() ?? '';

    String timeStr = '';
    if (request['createdAt'] != null) {
      final dt = DateTime.tryParse(request['createdAt'].toString());
      if (dt != null) {
        final local = dt.toLocal();
        final h = local.hour > 12 ? local.hour - 12 : local.hour;
        final period = local.hour >= 12 ? 'PM' : 'AM';
        timeStr = '${h.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} $period';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEBEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.red[50],
                child: const Icon(Icons.person, color: Color(0xFFC62828), size: 24),
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
                            pName.isNotEmpty ? pName : 'Patient',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(timeStr,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('$age Yrs / $gender',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('Needs $units Unit(s) of Blood',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hospital,
                            style: TextStyle(color: Colors.grey[700], fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            bloodGroup,
                            style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BloodRequestDetailsScreen(bookingId: bookingId),
                  ),
                );
                _loadDashboard();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View & Respond',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageConsultationsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC62828).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment, size: 28, color: Color(0xFFC62828)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage All Blood Requests',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 4),
                Text(
                  'Accept, reject and track all blood requests from patients.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
