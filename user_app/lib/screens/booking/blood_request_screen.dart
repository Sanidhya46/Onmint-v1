import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import 'package:user_app/data/indian_states_cities.dart';
import 'confirm_blood_request_screen.dart';

class BloodRequestScreen extends StatefulWidget {
  final Map<String, dynamic>? bloodBank;

  const BloodRequestScreen({
    super.key,
    this.bloodBank,
  });

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  final _apiClient = OnMintApiClient();
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();
  final _unitsController = TextEditingController();
  final _scrollController = ScrollController();
  
  String? _selectedBloodGroup;
  bool _isLoading = false;
  String? _selectedState;
  String? _selectedCity;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillUserData());
  }

  void _prefillUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _patientNameController.text = user.fullName.isNotEmpty ? user.fullName : '';
      _contactController.text = user.phone.isNotEmpty ? user.phone : '';
      if (user.city.isNotEmpty) _selectedCity = user.city;
      if (user.state.isNotEmpty) _selectedState = user.state;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _contactController.dispose();
    _hospitalController.dispose();
    _addressController.dispose();
    _reasonController.dispose();
    _unitsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBloodGroup == null) {
      ToastUtils.showError('Please select blood group');
      return;
    }

    if (_selectedCity == null || _selectedCity!.isEmpty) {
      ToastUtils.showError('Please select your city');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // API call removed as requested to test UI directly
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading briefly

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmBloodRequestScreen(
              patientName: _patientNameController.text,
              bloodGroup: _selectedBloodGroup ?? '',
              unitsRequired: _unitsController.text,
              hospitalName: _hospitalController.text,
              contactNumber: _contactController.text,
              address: _addressController.text,
              emergencyNote: _reasonController.text,
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
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(top: false, bottom: false, child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
        controller: _scrollController,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section Image ONLY
              Image.asset(
                'assets/images/bloodbank/bloodbank_booking_banner.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.red[50],
                  alignment: Alignment.center,
                  child: const Text('Banner Missing', style: TextStyle(color: Colors.red)),
                ),
              ),
              
              Container(
                margin: const EdgeInsets.only(
                  left: 16, 
                  right: 16, 
                  bottom: 16,
                ),
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.water_drop, color: Colors.red[700], size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Request Blood',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Fill in the details and we'll help you find blood donors and blood banks.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ROW 1
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputGroup(
                            label: 'Patient Name',
                            hint: 'Enter patient full name',
                            icon: Icons.person_outline,
                            controller: _patientNameController,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Blood Group', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                isDense: true,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: 'Select',
                                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  prefixIcon: Icon(Icons.water_drop_outlined, color: Colors.grey[500], size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 18),
                                iconSize: 18,
                                value: _selectedBloodGroup,
                                items: _bloodGroups.map((group) {
                                  return DropdownMenuItem(
                                    value: group,
                                    child: Text(group, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedBloodGroup = value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ROW 2
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputGroup(
                            label: 'Units Required',
                            hint: 'Enter units',
                            icon: Icons.water_drop_outlined,
                            controller: _unitsController,
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildInputGroup(
                            label: 'Hospital Name',
                            hint: 'Enter hospital name',
                            icon: Icons.local_hospital_outlined,
                            controller: _hospitalController,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ROW 3
                    _buildInputGroup(
                      label: 'Contact Number',
                      hint: 'Enter contact number',
                      icon: Icons.phone_outlined,
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 10) return 'Invalid 10-digit number';
                        if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Digits only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // ROW 4
                    _buildInputGroup(
                      label: 'Address / Location',
                      hint: 'Enter your full address',
                      icon: Icons.location_on_outlined,
                      controller: _addressController,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      suffixIcon: Icons.my_location,
                    ),
                    const SizedBox(height: 8),

                    // State & City
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('State', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Autocomplete<String>(
                                initialValue: TextEditingValue(text: _selectedState ?? ''),
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text == '') {
                                    return IndianStatesData.states;
                                  }
                                  return IndianStatesData.states.where((String option) {
                                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                  });
                                },
                                onSelected: (String selection) {
                                  setState(() {
                                    _selectedState = selection;
                                    _selectedCity = null;
                                  });
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  // Keep controller in sync with prefill/state updates
                                  if (_selectedState != null && controller.text != _selectedState && !focusNode.hasFocus) {
                                    controller.text = _selectedState!;
                                  }
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Select State',
                                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      prefixIcon: Icon(Icons.map_outlined, color: Colors.grey[500], size: 18),
                                      suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    ),
                                    onChanged: (val) {
                                      _selectedState = val;
                                      _selectedCity = null;
                                    },
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4.0,
                                      child: SizedBox(
                                        height: 200.0,
                                        width: MediaQuery.of(context).size.width / 2 - 20,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.all(0),
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final String option = options.elementAt(index);
                                            return GestureDetector(
                                              onTap: () => onSelected(option),
                                              child: ListTile(
                                                title: Text(option, style: const TextStyle(fontSize: 12)),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('City *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Autocomplete<String>(
                                initialValue: TextEditingValue(text: _selectedCity ?? ''),
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  if (_selectedState == null || _selectedState!.isEmpty) return const Iterable<String>.empty();
                                  final cities = IndianStatesData.getCitiesForState(_selectedState!);
                                  if (textEditingValue.text == '') {
                                    return cities;
                                  }
                                  return cities.where((String option) {
                                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                  });
                                },
                                onSelected: (String selection) {
                                  setState(() {
                                    _selectedCity = selection;
                                  });
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  // Keep controller in sync
                                  if (_selectedCity != null && controller.text != _selectedCity && !focusNode.hasFocus) {
                                    controller.text = _selectedCity!;
                                  }
                                  return TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Select City',
                                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                                      prefixIcon: Icon(Icons.location_city, color: Colors.grey[500], size: 18),
                                      suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500], size: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: _selectedCity == null || _selectedCity!.isEmpty ? Colors.grey[300]! : Colors.red[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: _selectedCity == null || _selectedCity!.isEmpty ? Colors.grey[300]! : Colors.red[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    ),
                                    onChanged: (val) {
                                      _selectedCity = val;
                                    },
                                  );
                                },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4.0,
                                      child: SizedBox(
                                        height: 200.0,
                                        width: MediaQuery.of(context).size.width / 2 - 20,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.all(0),
                                          itemCount: options.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            final String option = options.elementAt(index);
                                            return GestureDetector(
                                              onTap: () => onSelected(option),
                                              child: ListTile(
                                                title: Text(option, style: const TextStyle(fontSize: 12)),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Emergency note
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Emergency Note (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 4,
                          maxLength: 150,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Any special instructions...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                            prefixIcon: Icon(Icons.note_alt_outlined, color: Colors.grey[500], size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828), // Dark Red matching UI
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                const Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Request Blood',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_forward, color: Color(0xFFC62828), size: 14),
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined, color: Colors.grey[600], size: 12),
                        const SizedBox(width: 4),
                        Text(
                          "We'll connect you with nearby blood banks",
                          style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ))),
    );
  }

  Widget _buildFeatureCard(IconData icon, String label, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGroup({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 18),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.red[700], size: 18) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
        ),
      ],
    );
  }
}
