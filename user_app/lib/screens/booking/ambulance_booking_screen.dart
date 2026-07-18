import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:user_app/data/indian_states_cities.dart';
import 'package:user_app/screens/booking/confirm_ambulance_booking_screen.dart';
import 'package:user_app/screens/booking/confirm_ambulance_booking_screen_new.dart';
import 'package:user_app/config/app_config.dart';

class AmbulanceBookingScreen extends StatefulWidget {
  const AmbulanceBookingScreen({Key? key}) : super(key: key);

  @override
  State<AmbulanceBookingScreen> createState() => _AmbulanceBookingScreenState();
}

class _AmbulanceBookingScreenState extends State<AmbulanceBookingScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedState;
  String? _selectedCity;

  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  Position? _currentPosition;
  bool _isFetchingLocation = false;
  final PatientService _patientService = PatientService();
  List<dynamic> _nearbyAmbulances = [];
  bool _isLoadingAmbulances = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillUserData());
  }

  void _prefillUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _nameController.text = user.fullName.isNotEmpty ? user.fullName : '';
      _phoneController.text = user.phone.isNotEmpty ? user.phone : '';
      if (user.city.isNotEmpty) _selectedCity = user.city;
      if (user.state.isNotEmpty) _selectedState = user.state;
      if (user.gender != null && user.gender!.isNotEmpty) {
        _selectedGender = user.gender;
      }
      if (user.dateOfBirth != null) {
        final age = DateTime.now().year - user.dateOfBirth!.year;
        _ageController.text = age.toString();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentPosition = position;

        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address =
              '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}';
          if (mounted) {
            setState(() {
              _pickupController.text = address;
            });
          }
        }
        _fetchNearbyAmbulances(position);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _fetchNearbyAmbulances(Position position) async {
    setState(() => _isLoadingAmbulances = true);
    try {
      final response = await _patientService.searchAmbulances(
        latitude: position.latitude,
        longitude: position.longitude,
        limit: 2,
        maxDistance: 50,
      );
      if (mounted) {
        setState(() {
          _nearbyAmbulances = response['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching ambulances: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAmbulances = false);
      }
    }
  }

  void _navigateToConfirm() {
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your city'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppConfig.useNewFlow
              ? ConfirmAmbulanceBookingScreenNew(
                  pickupLocation: _pickupController.text,
                  dropoffLocation: _dropoffController.text,
                  name: _nameController.text,
                  phone: _phoneController.text,
                  age: _ageController.text.isNotEmpty
                      ? int.tryParse(_ageController.text) ?? 0
                      : 0,
                  gender: _selectedGender ?? 'Other',
                  notes: _notesController.text,
                  coordinates: _currentPosition != null
                      ? [_currentPosition!.longitude, _currentPosition!.latitude]
                      : [0.0, 0.0],
                  city: _selectedCity ?? '',
                  state: _selectedState ?? '',
                )
              : ConfirmAmbulanceBookingScreen(
                  pickupLocation: _pickupController.text,
                  dropoffLocation: _dropoffController.text,
                  name: _nameController.text,
                  phone: _phoneController.text,
                  age: _ageController.text.isNotEmpty
                      ? int.tryParse(_ageController.text) ?? 0
                      : 0,
                  gender: _selectedGender ?? 'Other',
                  notes: _notesController.text,
                  coordinates: _currentPosition != null
                      ? [_currentPosition!.longitude, _currentPosition!.latitude]
                      : [0.0, 0.0],
                  city: _selectedCity ?? '',
                  state: _selectedState ?? '',
                ),
        ),
      ).then((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5), // Ice Red color
      body: SafeArea(top: false, bottom: false, child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Top Banner Section
            Stack(
              children: [
                Image.asset(
                  'assets/images/ambulance/ambulance_booking_banner.jpeg',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.red[50],
                    child: const Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.red)),
                  ),
                ),
              ],
            ),
            // Form Card Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.airport_shuttle,
                              color: Colors.red[700], size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Book an Ambulance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill in your details and we\'ll reach you with the nearest ambulance.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('Pickup Location'),
                      _buildTextField(
                        controller: _pickupController,
                        hintText: 'Enter pickup location / address',
                        prefixIcon: Icons.location_on_outlined,
                        suffixIcon: Icons.my_location,
                        onSuffixTap: _fetchCurrentLocation,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      if (_isFetchingLocation)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text('Fetching location...',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.blue)),
                        ),
                      const SizedBox(height: 12),

                      // State & City selection
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('State'),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  child: Autocomplete<String>(
                                    initialValue: TextEditingValue(text: _selectedState ?? ''),
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) return IndianStatesData.states;
                                      return IndianStatesData.states.where((s) =>
                                          s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (String selection) {
                                      setState(() {
                                        _selectedState = selection;
                                        _selectedCity = null;
                                      });
                                    },
                                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                                      if (_selectedState != null && controller.text != _selectedState && !focusNode.hasFocus) {
                                        controller.text = _selectedState!;
                                      }
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        decoration: InputDecoration(
                                          hintText: 'State',
                                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                                          border: InputBorder.none,
                                          icon: Icon(Icons.map_outlined, color: Colors.red[700], size: 18),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                          suffixIcon: controller.text.isNotEmpty
                                              ? GestureDetector(
                                                  onTap: () {
                                                    controller.clear();
                                                    setState(() { _selectedState = null; _selectedCity = null; });
                                                  },
                                                  child: Icon(Icons.close, size: 14, color: Colors.grey[400]))
                                              : null,
                                        ),
                                        onChanged: (val) {
                                          if (!IndianStatesData.states.contains(val)) {
                                            setState(() { _selectedState = null; _selectedCity = null; });
                                          }
                                        },
                                      );
                                    },
                                    optionsViewBuilder: (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4,
                                          borderRadius: BorderRadius.circular(8),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 150),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (context, index) {
                                                final option = options.elementAt(index);
                                                return InkWell(
                                                  onTap: () => onSelected(option),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    child: Text(option, style: const TextStyle(fontSize: 12)),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('City *'),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _selectedState == null ? Colors.grey.shade100 : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  child: Autocomplete<String>(
                                    key: ValueKey(_selectedState),
                                    initialValue: TextEditingValue(text: _selectedCity ?? ''),
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (_selectedState == null) return const Iterable<String>.empty();
                                      final cities = IndianStatesData.getCitiesForState(_selectedState!);
                                      if (textEditingValue.text.isEmpty) return cities;
                                      return cities.where((c) =>
                                          c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (String selection) {
                                      setState(() { _selectedCity = selection; });
                                    },
                                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                                      if (_selectedCity != null && controller.text != _selectedCity && !focusNode.hasFocus) {
                                        controller.text = _selectedCity!;
                                      }
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        enabled: _selectedState != null,
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        decoration: InputDecoration(
                                          hintText: _selectedState == null ? 'Select state' : 'City',
                                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                                          border: InputBorder.none,
                                          icon: Icon(Icons.location_city, color: Colors.red[700], size: 18),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                          suffixIcon: controller.text.isNotEmpty
                                              ? GestureDetector(
                                                  onTap: () {
                                                    controller.clear();
                                                    setState(() { _selectedCity = null; });
                                                  },
                                                  child: Icon(Icons.close, size: 14, color: Colors.grey[400]))
                                              : null,
                                        ),
                                        onChanged: (val) {
                                          final cities = IndianStatesData.getCitiesForState(_selectedState!);
                                          if (!cities.contains(val)) setState(() { _selectedCity = null; });
                                        },
                                      );
                                    },
                                    optionsViewBuilder: (context, onSelected, options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4,
                                          borderRadius: BorderRadius.circular(8),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 150),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (context, index) {
                                                final option = options.elementAt(index);
                                                return InkWell(
                                                  onTap: () => onSelected(option),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    child: Text(option, style: const TextStyle(fontSize: 12)),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildFieldLabel('Drop-off Location'),
                      _buildTextField(
                        controller: _dropoffController,
                        hintText: 'Enter drop-off location / hospital',
                        prefixIcon: Icons.location_on_outlined,
                        iconColor: Colors.red[700],
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Contact Name'),
                                _buildTextField(
                                  controller: _nameController,
                                  hintText: 'Enter Name',
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Phone Number'),
                                _buildTextField(
                                  controller: _phoneController,
                                  hintText: 'Enter Mob No.',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    if (v.length < 10)
                                      return 'Invalid 10-digit number';
                                    if (!RegExp(r'^[0-9]+$').hasMatch(v))
                                      return 'Digits only';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row 1.5: Age | Gender
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Age'),
                                _buildTextField(
                                  controller: _ageController,
                                  hintText: 'Enter Age',
                                  prefixIcon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Gender'),
                                DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    hintText: 'Select Gender',
                                    hintStyle: TextStyle(
                                        color: Colors.grey[400], fontSize: 11),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(bottom: 0),
                                      child: Icon(Icons.person_outline,
                                          color: Colors.red[700], size: 18),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide:
                                          BorderSide(color: Colors.grey[200]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.red[300]!, width: 1.5),
                                    ),
                                  ),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black87),
                                  icon: const Icon(Icons.keyboard_arrow_down,
                                      color: Colors.black87, size: 16),
                                  items: ['Male', 'Female', 'Other']
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value,
                                          style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedGender = newValue;
                                    });
                                  },
                                  validator: (v) =>
                                      v == null ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildFieldLabel('Additional Details (Optional)'),
                      _buildTextField(
                        controller: _notesController,
                        hintText:
                            'Patient condition, requirements, any other details...',
                        prefixIcon: Icons.note_alt_outlined,
                        maxLines: 3,
                        alignTopIcon: true,
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _navigateToConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFE53935), // Red color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 24),
                              Text(
                                'Proceed',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined,
                              color: Colors.grey[600], size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'We\'ll notify the nearest ambulance and contact you immediately',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trust Badges Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5), // Light red background
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTrustItem(Icons.airport_shuttle, 'Quick Response',
                      'Ambulance at your\nlocation in minutes'),
                  _buildTrustItem(Icons.verified_user_outlined,
                      'Safe & Reliable', 'Fully equipped &\nverified services'),
                  _buildTrustItem(Icons.support_agent, '24/7 Available',
                      'Round the clock\nemergency support'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Available Ambulances Section
            if (_isLoadingAmbulances)
              const Center(child: CircularProgressIndicator(color: Colors.red))
            else if (_nearbyAmbulances.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Ambulances Nearby (50km)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._nearbyAmbulances
                        .map((amb) => _buildAmbulanceCard(amb))
                        .toList(),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      )),
    );
  }

  Widget _buildAmbulanceCard(dynamic amb) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(Icons.airport_shuttle, color: Colors.red[600], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amb['driverName'] ?? 'Ambulance Driver',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  amb['vehicleType'] ?? 'Basic Life Support',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey[500], size: 12),
                    const SizedBox(width: 4),
                    Text(
                      amb['distance'] != null
                          ? '${amb['distance']} km away'
                          : 'Nearby',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Calling ${amb['driverName'] ?? 'Driver'}...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[300]!),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Call',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
    Color? iconColor,
    VoidCallback? onSuffixTap,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool alignTopIcon = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
              bottom: alignTopIcon ? (maxLines > 1 ? 40.0 : 0.0) : 0),
          child:
              Icon(prefixIcon, color: iconColor ?? Colors.red[700], size: 18),
        ),
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon, color: Colors.red[700], size: 18),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String title, String desc) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.red[600], size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for selecting Indian state
class _StatePickerDialog extends StatefulWidget {
  final String? selectedState;
  const _StatePickerDialog({this.selectedState});

  @override
  State<_StatePickerDialog> createState() => _StatePickerDialogState();
}

class _StatePickerDialogState extends State<_StatePickerDialog> {
  final _searchController = TextEditingController();
  List<String> _filtered = IndianStatesData.states;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select State', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search state...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (q) => setState(() {
                _filtered = IndianStatesData.states
                    .where((s) => s.toLowerCase().contains(q.toLowerCase()))
                    .toList();
              }),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final s = _filtered[i];
                  return ListTile(
                    dense: true,
                    title: Text(s, style: const TextStyle(fontSize: 13)),
                    selected: s == widget.selectedState,
                    selectedTileColor: Colors.red[50],
                    onTap: () => Navigator.pop(context, s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

/// Dialog for selecting city based on selected state
class _CityPickerDialog extends StatefulWidget {
  final String state;
  final String? selectedCity;
  const _CityPickerDialog({required this.state, this.selectedCity});

  @override
  State<_CityPickerDialog> createState() => _CityPickerDialogState();
}

class _CityPickerDialogState extends State<_CityPickerDialog> {
  final _searchController = TextEditingController();
  late List<String> _cities;
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _cities = IndianStatesData.getCitiesForState(widget.state);
    _filtered = _cities;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select City in ${widget.state}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (q) => setState(() {
                _filtered = _cities
                    .where((c) => c.toLowerCase().contains(q.toLowerCase()))
                    .toList();
              }),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('No cities found', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        return ListTile(
                          dense: true,
                          title: Text(c, style: const TextStyle(fontSize: 13)),
                          selected: c == widget.selectedCity,
                          selectedTileColor: Colors.red[50],
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

