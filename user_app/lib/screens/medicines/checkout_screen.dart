import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../services/cart_service.dart';
import '../../utils/app_colors.dart';
import '../../data/indian_states_cities.dart';
import '../booking/payment_success_screen.dart';
import '../bookings/pharmacist_order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'cod';
  bool _isLoading = false;
  final _apiClient = OnMintApiClient();

  String _userAddress = 'Fetching address...';
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshProfile();
    final user = authProvider.currentUser;

    if (user != null) {
      _selectedState = user.state;
      if (_selectedState != null && _selectedState!.isEmpty) _selectedState = null;
      _selectedCity = user.city;
      if (_selectedCity != null && _selectedCity!.isEmpty) _selectedCity = null;
    }

    if (user?.address != null) {
      final addr = user!.address!;
      final parts = [addr.street, addr.city, addr.state, addr.pincode]
          .where((p) => p != null && p.isNotEmpty)
          .toList();
      setState(() {
        _userAddress = parts.join(', ');
        if (_userAddress.isEmpty) _userAddress = 'Address not provided in profile';
      });
    } else {
      setState(() {
        _userAddress = 'Address not provided in profile';
      });
    }
  }

  void _showChangeAddressDialog() {
    final controller = TextEditingController(
      text: _userAddress == 'Address not provided in profile' ? '' : _userAddress,
    );
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF0F2147), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F2147))),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your new delivery address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0F2147)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() {
                          _userAddress = controller.text.trim();
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2147),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartService>(context, listen: false);
    if (cart.itemCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    if (_userAddress.trim().isEmpty || _userAddress == 'Address not provided in profile') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please update your delivery address in profile')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      final finalAddress = _userAddress;

      final bookingData = {
        'serviceType': 'pharmacist',
        'title': 'Medicine Order - ${cart.itemCount} items',
        'description': 'Medicine Order - ${cart.itemCount} items',
        'address': finalAddress,
        'state': _selectedState ?? '',
        'city': _selectedCity ?? '',
        'coordinates': user?.location?.coordinates ?? [72.8777, 19.0760],
        'name': '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
        'phone': user?.phone ?? '',
        'paymentMethod': _paymentMethod == 'online' ? 'online' : 'cash',
        'totalAmount': cart.totalAmount,
        'isEmergency': false,
        'medicines': cart.getOrderItems(),
        'notes': 'Medicine delivery order',
        'preferredTime': DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
      };

      final response = await _apiClient.patient.createRealtimeBooking(bookingData);
      
      cart.clear(); // Clear local cart

      if (mounted) {
        final bookingId = response['id'] ?? response['_id'] ?? 'COD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacistOrderTrackingScreen(
              bookingId: bookingId.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F2147),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: const [
          Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF0F2147), size: 16),
              SizedBox(width: 4),
              Text(
                'Secure',
                style: TextStyle(color: Color(0xFF0F2147), fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F2147)))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProgressIndicator(),
                        _buildStateCitySelectors(),
                        _buildDeliveryAddress(),
                        _buildDeliveryTimeBanner(),
                        _buildPaymentMethodSection(),
                        _buildOrderSummary(cart),
                        _buildSafeSecureBanner(),
                        const SizedBox(height: 16),
                        _buildFastDeliveryPromise(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildStickyBottomBar(context, cart),
              ],
            )),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep(label: 'Cart', isCompleted: true, isActive: false),
          _buildLine(isCompleted: true),
          _buildStep(label: 'Address', isCompleted: true, isActive: false),
          _buildLine(isCompleted: true),
          _buildStep(label: 'Place Order', isCompleted: false, isActive: true, number: '3'),
        ],
      ),
    );
  }

  Widget _buildStep({required String label, required bool isCompleted, required bool isActive, String? number}) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted || isActive ? const Color(0xFF0F2147) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0F2147), width: 1.5),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Center(child: Text(number ?? '', style: TextStyle(color: isActive ? Colors.white : const Color(0xFF0F2147), fontWeight: FontWeight.bold, fontSize: 10))),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCompleted || isActive ? FontWeight.bold : FontWeight.normal,
            color: isCompleted || isActive ? const Color(0xFF0F2147) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 2,
        color: isCompleted ? const Color(0xFF0F2147) : Colors.grey[300],
      ),
    );
  }

  Widget _buildStateCitySelectors() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, color: Color(0xFF0F2147), size: 20),
              SizedBox(width: 8),
              Text('State & City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2147))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SearchableDropdown(
                  key: ValueKey('state_${_selectedState ?? "none"}'),
                  items: IndianStatesData.states,
                  value: _selectedState,
                  hint: 'Select State',
                  onChanged: (val) {
                    setState(() {
                      _selectedState = val;
                      _selectedCity = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SearchableDropdown(
                  key: ValueKey('city_${_selectedState ?? "none"}_${_selectedCity ?? "none"}'),
                  items: _selectedState != null
                      ? IndianStatesData.getCitiesForState(_selectedState!)
                      : [],
                  value: _selectedCity,
                  hint: 'Select City',
                  onChanged: (val) {
                    setState(() {
                      _selectedCity = val;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Color(0xFF0F2147), size: 20),
                  SizedBox(width: 8),
                  Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F2147))),
                ],
              ),
              InkWell(
                onTap: _showChangeAddressDialog,
                child: const Text('Change', style: TextStyle(color: Color(0xFF0F2147), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final name = '${auth.currentUser?.firstName ?? ''} ${auth.currentUser?.lastName ?? ''}'.trim();
                    return Text(name.isEmpty ? 'Patient' : name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13));
                  }
                ),
                const SizedBox(height: 2),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => Text(auth.currentUser?.phone ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ),
                const SizedBox(height: 4),
                Text(_userAddress, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Color(0xFF0F2147), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery within 8 Hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F2147))),
                SizedBox(height: 1),
                Text('We will deliver your order within 8 hours', style: TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2147),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('8 HOURS', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2147))),
          const SizedBox(height: 8),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF0F2147), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Radio<String>(
                  value: 'cod',
                  groupValue: _paymentMethod,
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                  activeColor: const Color(0xFF0F2147),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F2147))),
                      SizedBox(height: 2),
                      Text('Pay when you receive the order', style: TextStyle(color: Colors.black54, fontSize: 11)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(Icons.money, color: Color(0xFF0F2147), size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text('Only Cash on Delivery is available for this order.', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartService cart) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F2147))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Total (${cart.itemCount} Items)', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Delivery Charge', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹0.00', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 12)),
                  const Text('(Free Delivery)', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2147))),
              Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2147))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeSecureBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF0F2147), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safe and Secure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F2147))),
                SizedBox(height: 2),
                Text('You will pay in cash when your order is delivered.', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastDeliveryPromise() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Color(0xFF0F2147), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fast Delivery Promise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F2147))),
                SizedBox(height: 2),
                Text('We will deliver your order within 8 hours.', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2147),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('WITHIN 8 HOURS', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, CartService cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total Payable', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('₹${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2147))),
                const Text('(Cash on Delivery)', style: TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
            ElevatedButton(
              onPressed: _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2147),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                children: [
                  Text('Place Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
