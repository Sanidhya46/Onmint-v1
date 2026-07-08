import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/screens/services/confirm_nurse_booking_screen.dart';
import 'package:user_app/screens/booking/nursing_care_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:user_app/data/indian_states_cities.dart';

class NurseBookingScreen extends StatefulWidget {
  const NurseBookingScreen({Key? key}) : super(key: key);

  @override
  State<NurseBookingScreen> createState() => _NurseBookingScreenState();
}

class _NurseBookingScreenState extends State<NurseBookingScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _selectedGender;
  String? _selectedState;
  String? _selectedCity;
  final ScrollController _scrollController = ScrollController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone;
      setState(() {
        _selectedState = user.state.isNotEmpty ? user.state : null;
        _selectedCity = user.city.isNotEmpty ? user.city : null;
        if (user.dateOfBirth != null) {
          final age = DateTime.now().year - user.dateOfBirth!.year;
          _ageController.text = age.toString();
        }
        _selectedGender = user.gender?.isNotEmpty == true ? user.gender : null;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<NursingCareModel> _selectedCares = [];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  void _navigateToNursingCareSelection() async {
    final result = await Navigator.push<List<NursingCareModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => NursingCareSelectionScreen(
          initialSelectedCares: _selectedCares,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCares = result;
      });
    }
  }

  void _navigateToConfirm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCares.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one nursing care')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmNurseBookingScreen(
            address: _addressController.text,
            name: _nameController.text,
            phone: _phoneController.text,
            age: _ageController.text.isNotEmpty
                ? int.tryParse(_ageController.text) ?? 0
                : 0,
            gender: _selectedGender ?? 'Other',
            notes: _notesController.text,
            city: _selectedCity ?? '',
            state: _selectedState ?? '',
            selectedCares: _selectedCares,
            preferredDate: _selectedDate,
            preferredTime: _selectedTime != null
                ? DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute)
                : null,
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
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/nurse/Nurse_booking_banner.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
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
                          Icon(Icons.calendar_month,
                              color: Colors.blue[700], size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Book a Nurse',
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
                        'Fill in your details and we\'ll send your request to nearby nurses.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),

                      // Row 0: Address
                      _buildFieldLabel('Your Area / Address'),
                      _buildTextField(
                        controller: _addressController,
                        hintText: 'Enter Address',
                        prefixIcon: Icons.location_on_outlined,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // State & City
                      _buildStateCitySelectors(),
                      const SizedBox(height: 16),

                      // Row 1: Contact Name | Phone Number
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  hintText: 'Enter mob no.',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 1.5: Age | Gender
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  decoration: _buildInputDecoration(
                                      'Gender', Icons.person_outline),
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
                      const SizedBox(height: 16),

                      // Row 2: Select Nursing Care
                      _buildFieldLabel('Select Nursing Care'),
                      InkWell(
                        onTap: _navigateToNursingCareSelection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.medical_services_outlined,
                                      color: Colors.blue[600], size: 16),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedCares.isEmpty
                                        ? 'Choose Nurse Service'
                                        : '${_selectedCares.length} Cares Selected',
                                    style: TextStyle(
                                      color: _selectedCares.isEmpty
                                          ? Colors.grey[400]
                                          : Colors.black87,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.keyboard_arrow_down,
                                  color: Colors.blue[600], size: 16),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedCares.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedCares
                                .map((care) => Chip(
                                      label: Text(care.name,
                                          style: const TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.blue[50],
                                      deleteIcon:
                                          const Icon(Icons.close, size: 16),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedCares.remove(care);
                                        });
                                      },
                                      side:
                                          BorderSide(color: Colors.blue[100]!),
                                    ))
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Row 3: Preferred Date | Preferred Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Preferred Date'),
                                TextFormField(
                                  controller: _dateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _buildInputDecoration(
                                      'Date', Icons.calendar_today_outlined,
                                      suffixIcon: Icons.keyboard_arrow_right),
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
                                _buildFieldLabel('Preferred Time'),
                                TextFormField(
                                  controller: _timeController,
                                  readOnly: true,
                                  onTap: () => _selectTime(context),
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _buildInputDecoration(
                                      'Time', Icons.access_time_outlined,
                                      suffixIcon: Icons.keyboard_arrow_right),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Row 4: Additional Notes
                      _buildFieldLabel('Additional Notes (Optional)'),
                      _buildTextField(
                        controller: _notesController,
                        hintText: 'Any special requirements or notes...',
                        prefixIcon: Icons.note_alt_outlined,
                        maxLines: 3,
                        alignTopIcon: true,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _navigateToConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText, IconData prefixIcon,
      {IconData? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
      prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 16),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: Colors.blue[600], size: 16)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    IconData? suffixIcon,
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
          padding: EdgeInsets.only(bottom: alignTopIcon ? 20.0 : 0),
          child: Icon(prefixIcon, color: Colors.grey[500], size: 16),
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: Colors.blue[600], size: 16)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[300]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildStateCitySelectors() {
    final cities = _selectedState != null
        ? IndianStatesData.getCitiesForState(_selectedState!)
        : <String>[];

    return Row(
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
                        hintText: 'Search state...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                        border: InputBorder.none,
                        icon: Icon(Icons.map_outlined, color: Colors.grey[500], size: 16),
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
                          constraints: const BoxConstraints(maxHeight: 200),
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
              _buildFieldLabel('City'),
              Container(
                decoration: BoxDecoration(
                  color: _selectedState == null ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Autocomplete<String>(
                  key: ValueKey(_selectedState),
                  initialValue: TextEditingValue(text: _selectedCity ?? ''),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (_selectedState == null) return const Iterable<String>.empty();
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
                        hintText: _selectedState == null ? 'Select state first' : 'Search city...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                        border: InputBorder.none,
                        icon: Icon(Icons.location_city_outlined, color: Colors.grey[500], size: 16),
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
                          constraints: const BoxConstraints(maxHeight: 200),
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
    );
  }
}
