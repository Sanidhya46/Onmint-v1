import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:vendor_app/screens/blood_bank/blood_bank_accepted_order_screen.dart';
import 'package:vendor_app/config/app_config.dart';
import '../booking/waiting_for_patient_screen.dart';
import '../bloodbank/fill_price_bloodbank_screen.dart';

class BloodBankBookingsScreen extends StatefulWidget {
  const BloodBankBookingsScreen({super.key});

  @override
  State<BloodBankBookingsScreen> createState() => _BloodBankBookingsScreenState();
}

class _BloodBankBookingsScreenState extends State<BloodBankBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;

  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _inProgressBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (_allBookings.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      await _apiClient.initialize();
      // Fetch ALL without status filter, filter locally — more robust
      final response = await _apiClient.get('/realtime/provider/bookings', queryParameters: {
        'limit': 100,
        'serviceType': 'bloodbank',
      });

      if (mounted) {
        setState(() {
          final data = response.data['data'] ?? [];
          if (data is List) {
            _allBookings = data.map((e) => Map<String, dynamic>.from(e)).toList();
            
            // Sort newest first
            _allBookings.sort((a, b) {
              final timeA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
              final timeB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
              return timeB.compareTo(timeA);
            });

            _pendingBookings = [];
            _inProgressBookings = [];
            _completedBookings = [];

            for (var b in _allBookings) {
              final status = b['status']?.toString().toLowerCase() ?? '';
              bool isRejectedByMe = false;
              final offers = b['offers'] as List?;
              if (offers != null) {
                final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
                for (var o in offers) {
                  final vId = o is Map ? (o['vendorId'] ?? o['vendor'] ?? o['vendor_id']) : null;
                  bool isMyOffer = currentUserId != null && (vId == currentUserId || (vId is Map && (vId['_id'] == currentUserId || vId['id'] == currentUserId)));
                  if (isMyOffer && o is Map && o['status'] == 'rejected') {
                    isRejectedByMe = true;
                    break;
                  }
                }
              }
              if (isRejectedByMe) continue;

              if (status == 'requested' || status == 'pending') {
                _pendingBookings.add(b);
              } else if (status == 'completed' || status == 'cancelled' || status == 'rejected' || status == 'accepted') {
                _completedBookings.add(b);
              } else {
                _inProgressBookings.add(b);
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Failed to load blood requests: ${e.toString().replaceAll("Exception: ", "")}');
      }
    }
  }

  /// Safely extract address string from any type
  String _safeAddress(dynamic loc) {
    if (loc == null) return '';
    if (loc is String) return loc;
    if (loc is Map) {
      final addr = loc['address'];
      if (addr is Map) return addr['address']?.toString() ?? addr['street']?.toString() ?? '';
      if (addr != null) return addr.toString();
      return loc['street']?.toString() ?? loc['city']?.toString() ?? '';
    }
    return loc.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF152238),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'My Booking',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1565C0),
          indicatorWeight: 3,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(),
                        _buildList(_inProgressBookings, 'In Progress'),
                        _buildList(_completedBookings, 'Completed'),
                      ],
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildAllTab() {
    if (_allBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No blood requests found.',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Pull down to refresh',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_pendingBookings.isNotEmpty) _buildSectionHeader('Pending', _pendingBookings.length, Colors.orange),
        ..._pendingBookings.map((b) => _buildBookingCard(b)),
        if (_inProgressBookings.isNotEmpty) _buildSectionHeader('In Progress', _inProgressBookings.length, const Color(0xFF1565C0)),
        ..._inProgressBookings.map((b) => _buildBookingCard(b)),
        if (_completedBookings.isNotEmpty) _buildSectionHeader('Completed', _completedBookings.length, Colors.green),
        ..._completedBookings.map((b) => _buildBookingCard(b)),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, String type) {
    if (list.isEmpty) {
      return Center(child: Text('No $type requests.', style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildBookingCard(list[index]),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> request) {
    final patientData = request['patientDetails'] ?? {};
    final pName = patientData['fullName'] ?? 'Patient';
    final patientPhoto = patientData['profilePicture']?.toString() ?? '';
    final age = patientData['age'] ?? '35';
    final gender = patientData['gender'] ?? 'Male';
    final units = request['unitsRequired'] ?? '1';
    final address = _safeAddress(request['location']);
    final bloodGroup = request['bloodGroup'] ?? 'O+';
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    final offers = request['offers'] as List?;
    bool hasOffered = request['hasOffered'] == true;
    bool isRejectedByMe = false;
    if (offers != null) {
      hasOffered = hasOffered || offers.any((o) {
        if (currentUserId == null) return false;
        final vId = o is Map ? (o['vendorId'] ?? o['vendor'] ?? o['vendor_id']) : null;
        bool isMyOffer = vId == currentUserId || (vId is Map && (vId['_id'] == currentUserId || vId['id'] == currentUserId));
        if (isMyOffer && o is Map && o['status'] == 'rejected') isRejectedByMe = true;
        return isMyOffer;
      });
    }
    final statusRaw = request['status']?.toString().toLowerCase() ?? '';
    final bookingId = request['_id']?.toString() ?? '';

    Color statusColor;
    String statusLabel;
    bool isCompleted = false;

    if (statusRaw == 'requested' || statusRaw == 'pending') {
      statusColor = Colors.orange;
      statusLabel = 'Requested';
    } else if (statusRaw == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Completed';
      isCompleted = true;
    } else if (statusRaw == 'cancelled' || statusRaw == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'Cancelled';
      isCompleted = true;
    } else if (statusRaw == 'accepted') {
      statusColor = Colors.green;
      statusLabel = 'Connected';
    } else {
      statusColor = const Color(0xFF1565C0);
      statusLabel = 'In Progress';
    }

    String completedDateStr = '';
    if (isCompleted && request['updatedAt'] != null) {
      final dt = DateTime.tryParse(request['updatedAt'].toString());
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        completedDateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          Widget screen;
          if (statusRaw == 'requested' || statusRaw == 'pending') {
            if (hasOffered) {
              screen = WaitingForPatientScreen(bookingId: bookingId, bookingData: request);
            } else {
              screen = FillPriceBloodBankScreen(bookingId: bookingId, bookingData: request);
            }
          } else {
            screen = BloodBankAcceptedOrderScreen(
              bookingId: bookingId,
              initialData: request,
            );
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
          _loadBookings();
          if (result == 'accepted') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BloodBankAcceptedOrderScreen(
                  bookingId: bookingId,
                  initialData: request,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: patientPhoto.isNotEmpty 
                    ? NetworkImage(patientPhoto) 
                    : AssetImage(gender.toString().toLowerCase() == 'female' 
                        ? 'assets/images/female_profile.png' 
                        : 'assets/images/male_profile.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pName.isNotEmpty ? pName : 'Patient Name',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152238),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '$age Years',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Icon(gender.toString().toLowerCase() == 'female' ? Icons.female : Icons.male, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          gender.toString(),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.bloodtype, size: 12, color: Colors.redAccent),
                        const SizedBox(width: 2),
                        Text(
                          '$bloodGroup - $units Unit(s)',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Side (Status + Chevron)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCompleted && completedDateStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Completed on\n$completedDateStr',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.grey.shade600, height: 1.1),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.black54, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              _tabController.animateTo(0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F0FE),
              foregroundColor: const Color(0xFF1565C0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'View All Bookings',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
