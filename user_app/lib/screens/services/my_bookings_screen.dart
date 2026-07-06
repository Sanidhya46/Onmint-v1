import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import '../bookings/booking_details_screen.dart';
import '../booking/order_request_screen.dart';
import '../booking/order_detail_file.dart';
import '../booking/user_unified_tracking_screen.dart';
import '../booking/connected_vendor_details_screen.dart';
import '../booking/coming_soon_screen.dart';
import '../bookings/pharmacist_order_tracking_screen.dart';
import 'package:user_app/screens/booking/service_offers_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  final PatientService _patientService = PatientService();

  List<Map<String, dynamic>> _myBookings = [];
  List<Map<String, dynamic>> _medicineOrders = [];
  bool _isLoading = false;
  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  StreamSubscription? _statusSubscription;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(refresh: true);
    _scrollController.addListener(_onScroll);
    _setupSockets();
  }

  void _setupSockets() {
    _statusSubscription = SocketService().statusUpdates.listen((_) {
      if (mounted) _loadData(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  int _getStatusRank(String status) {
    status = status.toLowerCase();
    if (['requested', 'pending', 'waiting for pharmacist'].contains(status)) return 1;
    if (['accepted', 'confirmed'].contains(status)) return 2;
    if (['in_progress', 'processing', 'on_the_way', 'shipped'].contains(status)) return 3;
    if (['completed', 'delivered'].contains(status)) return 4;
    return 5; // cancelled, expired, etc.
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh) {
      _page = 1;
      _hasMore = true;
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final bookingsData =
          await _patientService.getBookings(page: _page, limit: _limit);
      final medicinesData =
          await _patientService.getMedicineOrders(page: _page, limit: _limit);

      var filteredBookings = bookingsData.where((b) {
        final type = b['serviceType']?.toString().toLowerCase() ?? '';
        final status = b['status']?.toString().toLowerCase() ?? '';

        if (type == 'pharmacist' || type == 'medicine' || status == 'expired' || status == 'cancelled') return false;
        return true;
      }).toList();

      var medicines = medicinesData.where((m) {
        final status = m['status']?.toString().toLowerCase() ?? '';
        if (status == 'expired' || status == 'cancelled') return false;
        return true;
      }).toList();

      filteredBookings.sort((a, b) {
        final rankA = _getStatusRank(a['status']?.toString() ?? '');
        final rankB = _getStatusRank(b['status']?.toString() ?? '');
        if (rankA != rankB) return rankA.compareTo(rankB);
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      medicines.sort((a, b) {
        final rankA = _getStatusRank(a['status']?.toString() ?? '');
        final rankB = _getStatusRank(b['status']?.toString() ?? '');
        if (rankA != rankB) return rankA.compareTo(rankB);
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          if (refresh) {
            _myBookings = filteredBookings;
            _medicineOrders = medicines;
          } else {
            _myBookings.addAll(filteredBookings);
            _medicineOrders.addAll(medicines);
          }
          _hasMore = bookingsData.length == _limit || medicinesData.length == _limit;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (!mounted) return;
    setState(() => _isLoadingMore = true);
    _page++;

    try {
      final bookingsData = await _patientService.getBookings(page: _page, limit: _limit);
      final medicinesData = await _patientService.getMedicineOrders(page: _page, limit: _limit);

      var filteredBookings = bookingsData.where((b) {
        final type = b['serviceType']?.toString().toLowerCase() ?? '';
        final status = b['status']?.toString().toLowerCase() ?? '';
        if (type == 'pharmacist' || type == 'medicine' || status == 'expired' || status == 'cancelled') return false;
        return true;
      }).toList();

      var medicines = medicinesData.where((m) {
        final status = m['status']?.toString().toLowerCase() ?? '';
        if (status == 'expired' || status == 'cancelled') return false;
        return true;
      }).toList();

      filteredBookings.sort((a, b) {
        final rankA = _getStatusRank(a['status']?.toString() ?? '');
        final rankB = _getStatusRank(b['status']?.toString() ?? '');
        if (rankA != rankB) return rankA.compareTo(rankB);
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      medicines.sort((a, b) {
        final rankA = _getStatusRank(a['status']?.toString() ?? '');
        final rankB = _getStatusRank(b['status']?.toString() ?? '');
        if (rankA != rankB) return rankA.compareTo(rankB);
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _myBookings.addAll(filteredBookings);
          _medicineOrders.addAll(medicines);
          _hasMore = bookingsData.length == _limit || medicinesData.length == _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _page--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF0E2038),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.black87,
          indicatorColor: Colors.blue,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Medicine Orders'),
            Tab(text: 'Bookings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: () => _loadData(refresh: true),
                  child: _buildMedicineList(),
                ),
                RefreshIndicator(
                  onRefresh: () => _loadData(refresh: true),
                  child: _buildBookingsList(),
                ),
              ],
            ),
    );
  }



  Widget _buildMedicineList() {
    if (_medicineOrders.isEmpty) {
      return Center(
          child: Text('No medicine orders found',
              style: TextStyle(color: Colors.grey.shade600)));
    }

    final Map<String, List<Map<String, dynamic>>> groupedOrders = {
      'Requested': [],
      'Confirmed': [],
      'In Progress': [],
      'Completed': [],
    };

    for (var order in _medicineOrders) {
      final status = order['status']?.toString().toLowerCase() ?? 'pending';
      if (['requested', 'pending', 'waiting for pharmacist'].contains(status)) {
        groupedOrders['Requested']!.add(order);
      } else if (['accepted', 'confirmed'].contains(status)) {
        groupedOrders['Confirmed']!.add(order);
      } else if (['in_progress', 'processing', 'on_the_way', 'shipped'].contains(status)) {
        groupedOrders['In Progress']!.add(order);
      } else if (['completed', 'delivered'].contains(status)) {
        groupedOrders['Completed']!.add(order);
      } else {
        groupedOrders['Completed']!.add(order);
      }
    }

    List<Widget> listItems = [];
    
    for (var groupName in ['Requested', 'Confirmed', 'In Progress', 'Completed']) {
      final groupList = groupedOrders[groupName]!;
      if (groupList.isNotEmpty) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
            child: Row(
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${groupList.length}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        
        for (var order in groupList) {
          listItems.add(_buildMedicineCard(order));
        }
      }
    }

    if (_hasMore) {
      listItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        return listItems[index];
      },
    );
  }

  Widget _buildBookingsList() {
    if (_myBookings.isEmpty) {
      return Center(
          child: Text('No bookings found',
              style: TextStyle(color: Colors.grey.shade600)));
    }

    final Map<String, List<Map<String, dynamic>>> groupedBookings = {
      'Requested': [],
      'Confirmed': [],
      'In Progress': [],
      'Completed': [],
    };

    for (var booking in _myBookings) {
      final status = booking['status']?.toString().toLowerCase() ?? 'pending';
      if (['requested', 'pending', 'waiting for pharmacist'].contains(status)) {
        groupedBookings['Requested']!.add(booking);
      } else if (['accepted', 'confirmed'].contains(status)) {
        groupedBookings['Confirmed']!.add(booking);
      } else if (['in_progress', 'processing', 'on_the_way', 'shipped'].contains(status)) {
        groupedBookings['In Progress']!.add(booking);
      } else if (['completed', 'delivered'].contains(status)) {
        groupedBookings['Completed']!.add(booking);
      } else {
        groupedBookings['Completed']!.add(booking);
      }
    }

    List<Widget> listItems = [];
    
    for (var groupName in ['Requested', 'Confirmed', 'In Progress', 'Completed']) {
      final groupList = groupedBookings[groupName]!;
      if (groupList.isNotEmpty) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
            child: Row(
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${groupList.length}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        
        for (var booking in groupList) {
          listItems.add(_buildBookingCard(booking));
        }
      }
    }

    if (_hasMore) {
      listItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        return listItems[index];
      },
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> order) {
    final orderId =
        order['_id']?.toString().substring(0, 6).toUpperCase() ?? '12456';
    final items = order['medicines'] as List? ?? [];
    final amount = order['price'] ?? order['totalAmount'] ?? 0;
    final status = order['status']?.toString().toLowerCase() ?? 'pending';
    final createdAtStr = order['createdAt']?.toString() ?? '';

    DateTime date = DateTime.now();
    if (createdAtStr.isNotEmpty) {
      date = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final itemsCount = items.length;

    String imageUrl = '';
    if (items.isNotEmpty && items[0] is Map) {
      final med = items[0]['medicineId'] ?? items[0]['medicine'];
      if (med != null && med is Map) {
        if (med['images'] != null &&
            med['images'] is List &&
            med['images'].isNotEmpty) {
          imageUrl = med['images'][0].toString();
        } else if (med['imageUrl'] != null) {
          imageUrl = med['imageUrl'].toString();
        }
      }
    }

    Color statusBgColor;
    Color statusTextColor;
    String displayStatus;

    if (['completed', 'delivered'].contains(status)) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green;
      displayStatus = 'Delivered';
    } else if (['shipped', 'on_the_way'].contains(status)) {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue;
      displayStatus = 'Shipped';
    } else {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
      displayStatus = 'Processing';
    }

    return GestureDetector(
      onTap: () {
        final bookingId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacistOrderTrackingScreen(bookingId: bookingId),
          ),
        ).then((_) => _loadData(refresh: true));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade100),
        ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.medication, color: Colors.blue))
                    : const Icon(Icons.medication,
                        color: Colors.blue, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #MED$orderId',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedDate • $itemsCount Item${itemsCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$amount',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
            // Status and Chevron
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    displayStatus,
                    style: TextStyle(
                        color: statusTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final serviceType = booking['serviceType']?.toString().toLowerCase() ?? '';
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    final scheduledTimeStr = booking['scheduledTime']?.toString() ??
        booking['createdAt']?.toString() ??
        '';

    DateTime date = DateTime.now();
    if (scheduledTimeStr.isNotEmpty) {
      date = DateTime.tryParse(scheduledTimeStr) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);

    String locationText = 'Shivaji Nagar, Jhansi'; // fallback
    if (booking['location'] != null && booking['location'] is Map) {
      if (booking['location']['address'] != null) {
        locationText = booking['location']['address'].toString();
      }
    }

    String title;
    Widget iconWidget;

    final provider = booking['acceptedProvider'] ?? booking['provider'];
    String? providerImage;
    if (provider != null && provider is Map && provider['profilePicture'] != null && provider['profilePicture'].toString().isNotEmpty) {
      providerImage = provider['profilePicture'].toString();
    }

    Widget getIconWidget(Widget fallback) {
      if (providerImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            providerImage,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          ),
        );
      }
      return fallback;
    }

    if (serviceType == 'ambulance') {
      title = 'Ambulance';
      iconWidget = getIconWidget(Image.asset('assets/images/ambulance.png',
          width: 32,
          height: 32,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.local_shipping, color: Colors.red)));
    } else if (serviceType == 'nurse') {
      title = 'Nursing Care';
      iconWidget = getIconWidget(Image.asset('assets/images/nurse.png',
          width: 32,
          height: 32,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.local_hospital, color: Colors.blue)));
    } else if (serviceType == 'elderly_care' ||
        serviceType == 'elderly care' ||
        serviceType == 'elderly') {
      title = 'Elderly Care';
      iconWidget = getIconWidget(const Icon(Icons.elderly, color: Colors.orange, size: 32));
    } else {
      title = serviceType.isNotEmpty
          ? serviceType[0].toUpperCase() + serviceType.substring(1)
          : 'Service';
      if (serviceType == 'doctor') {
        iconWidget = getIconWidget(Image.asset('assets/images/doctor_icon.png', width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.medical_services, color: Colors.blue, size: 40)));
      } else if (serviceType == 'pathology' || serviceType == 'lab_test' || serviceType == 'lab test' || serviceType == 'labtest') {
        iconWidget = getIconWidget(Image.asset('assets/images/lab_test.png', width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.science, color: Colors.blue, size: 40)));
      } else if (serviceType == 'bloodbank' || serviceType == 'blood bank') {
        iconWidget = getIconWidget(Image.asset('assets/images/bloodbank.png', width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.bloodtype, color: Colors.red, size: 40)));
      } else {
        iconWidget = getIconWidget(const Icon(Icons.medical_services, color: Colors.blue, size: 40));
      }
    }

    Color statusBgColor;
    Color statusTextColor;
    String displayStatus;

    bool isMedicineOffersPending = false;
    if (serviceType == 'medicine') {
      final offersList = booking['offers'];
      final isPrescr = booking['isPrescriptionBased'] == true;
      if (isPrescr && offersList is List && offersList.isNotEmpty) {
        if (status == 'requested' || status == 'pending' || status == 'waiting for pharmacist') {
          isMedicineOffersPending = true;
        }
      }
    }

    if (isMedicineOffersPending) {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
      displayStatus = 'Approve';
    } else if (['completed', 'delivered'].contains(status)) {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green;
      displayStatus = 'Completed';
    } else if (status == 'accepted' || status == 'confirmed') {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue;
      displayStatus = 'Confirmed';
    } else if (status == 'requested' || status == 'pending') {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange;
      displayStatus = 'Requested';
    } else {
      statusBgColor = Colors.blue.shade50;
      statusTextColor = Colors.blue;
      displayStatus = 'In Progress';
    }

    return GestureDetector(
      onTap: () {
        if (status == 'requested' || status == 'pending') {
          final hasOffers = booking['offers'] is List && (booking['offers'] as List).isNotEmpty;
          if (hasOffers) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceOffersScreen(
                  bookingId: booking['_id']?.toString() ?? booking['id']?.toString() ?? '',
                  serviceType: serviceType,
                  bookingData: booking,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderRequestScreen(
                  bookingId: booking['_id']?.toString() ?? booking['id']?.toString() ?? '',
                  bookingData: booking,
                  serviceType: serviceType,
                ),
              ),
            );
          }
          return;
        }

        if (serviceType == 'nurse' ||
            serviceType == 'ambulance' ||
            serviceType == 'pathology' ||
            serviceType == 'lab_test' ||
            serviceType == 'lab test' ||
            serviceType == 'labtest') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserUnifiedTrackingScreen(
                  bookingId: booking['_id'] ?? booking['id'] ?? '',
                  serviceType: serviceType),
            ),
          );
        } else if (serviceType == 'bloodbank' || serviceType == 'blood bank') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserUnifiedTrackingScreen(
                bookingId: booking['_id'] ?? booking['id'] ?? '',
                serviceType: 'bloodbank',
              ),
            ),
          );
        } else if (serviceType == 'doctor' || serviceType == 'consultation') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailFile(
                bookingId: booking['_id'] ?? booking['id'] ?? '',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComingSoonScreen(),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon box
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate • $formattedTime',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            locationText,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status and Chevron
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                          color: statusTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
