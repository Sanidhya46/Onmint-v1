import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:user_app/data/indian_states_cities.dart';
import 'package:user_app/screens/booking/lab_test_selection_screen.dart';
import 'package:user_app/screens/booking/confirm_lab_test_booking_screen.dart';
import 'package:user_app/screens/booking/confirm_lab_test_booking_screen_new.dart';
import 'package:user_app/config/app_config.dart';

class LabTestBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? lab;

  const LabTestBookingScreen({Key? key, this.lab}) : super(key: key);

  @override
  State<LabTestBookingScreen> createState() => _LabTestBookingScreenState();
}

class _LabTestBookingScreenState extends State<LabTestBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  List<LabTestModel> _selectedTests = [];
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
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
      setState(() {});
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple[700]!, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black87, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.purple[700], // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  void _navigateToTestSelection() async {
    final result = await Navigator.push<List<LabTestModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => LabTestSelectionScreen(
          initialSelectedTests: _selectedTests,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedTests = result;
      });
    }
  }

  void _proceedToConfirmation() {
    if (_formKey.currentState!.validate()) {
      if (_selectedTests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one test')),
        );
        return;
      }
      if (_selectedCity == null || _selectedCity!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your city'), backgroundColor: Colors.orange),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppConfig.useNewFlow
              ? ConfirmLabTestBookingScreenNew(
                  address: _addressController.text,
                  contactName: _nameController.text,
                  phoneNumber: _phoneController.text,
                  preferredDate: _selectedDate!,
                  notes: _notesController.text,
                  selectedTests: _selectedTests,
                  city: _selectedCity ?? '',
                  state: _selectedState ?? '',
                )
              : ConfirmLabTestBookingScreen(
                  address: _addressController.text,
                  contactName: _nameController.text,
                  phoneNumber: _phoneController.text,
                  preferredDate: _selectedDate!,
                  notes: _notesController.text,
                  selectedTests: _selectedTests,
                  city: _selectedCity ?? '',
                  state: _selectedState ?? '',
                ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FA), // Very light grey/white background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 100% visible banner
            Image.asset(
              'assets/images/lab_test/labtest_booking_banner.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 150,
                color: Colors.purple[100],
                alignment: Alignment.center,
                child: const Text('Banner Image Missing',
                    style: TextStyle(color: Colors.purple)),
              ),
            ),

            // Booking Form Card
            Container(
              transform: Matrix4.translationValues(0.0, -4.0, 0.0),
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.science_outlined,
                                color: Colors.purple[700], size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Book a Lab Test',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Fill in your details and we\'ll arrange a sample collection at your home.',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('Your Area / Address'),
                      TextFormField(
                        controller: _addressController,
                        style: const TextStyle(fontSize: 12),
                        decoration: _buildInputDecoration(
                          'Enter your area or full address',
                          Icons.location_on_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // State & City
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
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
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
                                          icon: Icon(Icons.map_outlined, color: Colors.purple[400], size: 18),
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
                                _buildFieldLabel('City *'),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _selectedState == null ? Colors.grey.shade100 : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
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
                                          icon: Icon(Icons.location_city, color: Colors.purple[400], size: 18),
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
                      ),
                      const SizedBox(height: 16),

                      // Contact & Phone Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Contact Name'),
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _buildInputDecoration(
                                    'Enter Name',
                                    Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
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
                                TextFormField(
                                  controller: _phoneController,
                                  style: const TextStyle(fontSize: 12),
                                  keyboardType: TextInputType.phone,
                                  decoration: _buildInputDecoration(
                                    'Enter Mob No.',
                                    Icons.phone_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Required';
                                    if (value.length < 10)
                                      return 'Invalid 10-digit number';
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value))
                                      return 'Digits only';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Select Tests
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('Select Tests',
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                      InkWell(
                        onTap: _navigateToTestSelection,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.science_outlined,
                                        color: Colors.purple[700], size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedTests.isEmpty
                                            ? 'Choose Test / Package'
                                            : '${_selectedTests.length} Tests Selected',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_selectedTests.isEmpty)
                                        Text(
                                          'Select from popular tests or packages',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.grey[400], size: 14),
                            ],
                          ),
                        ),
                      ),

                      // Show selected tests chips if any
                      if (_selectedTests.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedTests
                                .map((test) => Chip(
                                      label: Text(test.name,
                                          style: const TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.purple[50],
                                      deleteIcon:
                                          const Icon(Icons.close, size: 16),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedTests.remove(test);
                                        });
                                      },
                                      side: BorderSide(
                                          color: Colors.purple[100]!),
                                    ))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Preferred Date (Calendar picker)
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Preferred Date'),
                                TextFormField(
                                  controller: _dateController,
                                  style: const TextStyle(fontSize: 12),
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                  decoration: _buildInputDecoration(
                                    'Select date',
                                    Icons.calendar_today_outlined,
                                  ).copyWith(
                                    suffixIcon: Icon(Icons.arrow_forward_ios,
                                        color: Colors.grey[400], size: 14),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                              flex: 4,
                              child: SizedBox()), // Reduce width to roughly 60%
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Additional Notes (Optional)
                      _buildFieldLabel('Additional Notes (Optional)'),
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 3,
                        maxLength: 150,
                        decoration: InputDecoration(
                          hintText: 'Any special instructions...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 11),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Icon(Icons.note_alt_outlined,
                                color: Colors.grey[500], size: 20),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.purple[700]!, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          alignLabelWithHint: true,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Proceed Button
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _proceedToConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFF6C2BD9), // Purple button matching design
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 24), // Balance spacing
                              const Text(
                                'Proceed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_forward,
                                    color: Color(0xFF6C2BD9), size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined,
                              color: Colors.grey[600], size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'We\'ll assign a nearby lab technician & confirm shortly',
                              style: TextStyle(
                                  fontSize: 11,
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
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40),
          ],
        ),
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

  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
      prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.purple[700]!, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
    );
  }
}

class _LabStatePickerDialog extends StatefulWidget {
  final String? selectedState;
  const _LabStatePickerDialog({this.selectedState});
  @override
  State<_LabStatePickerDialog> createState() => _LabStatePickerDialogState();
}
class _LabStatePickerDialogState extends State<_LabStatePickerDialog> {
  final _sc = TextEditingController();
  List<String> _filtered = IndianStatesData.states;
  @override
  void dispose() { _sc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select State', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: SizedBox(width: double.maxFinite, height: 400,
        child: Column(children: [
          TextField(controller: _sc,
            decoration: InputDecoration(hintText: 'Search state...', hintStyle: const TextStyle(fontSize: 12), prefixIcon: const Icon(Icons.search, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onChanged: (q) => setState(() { _filtered = IndianStatesData.states.where((s) => s.toLowerCase().contains(q.toLowerCase())).toList(); })),
          const SizedBox(height: 8),
          Expanded(child: ListView.builder(itemCount: _filtered.length, itemBuilder: (_, i) {
            final s = _filtered[i];
            return ListTile(dense: true, title: Text(s, style: const TextStyle(fontSize: 13)), selected: s == widget.selectedState, selectedTileColor: Colors.purple[50], onTap: () => Navigator.pop(context, s));
          })),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

class _LabCityPickerDialog extends StatefulWidget {
  final String state;
  final String? selectedCity;
  const _LabCityPickerDialog({required this.state, this.selectedCity});
  @override
  State<_LabCityPickerDialog> createState() => _LabCityPickerDialogState();
}
class _LabCityPickerDialogState extends State<_LabCityPickerDialog> {
  final _sc = TextEditingController();
  late List<String> _cities, _filtered;
  @override
  void initState() { super.initState(); _cities = IndianStatesData.getCitiesForState(widget.state); _filtered = _cities; }
  @override
  void dispose() { _sc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select City — ${widget.state}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      content: SizedBox(width: double.maxFinite, height: 400,
        child: Column(children: [
          TextField(controller: _sc,
            decoration: InputDecoration(hintText: 'Search city...', hintStyle: const TextStyle(fontSize: 12), prefixIcon: const Icon(Icons.search, size: 18), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onChanged: (q) => setState(() { _filtered = _cities.where((c) => c.toLowerCase().contains(q.toLowerCase())).toList(); })),
          const SizedBox(height: 8),
          Expanded(child: _filtered.isEmpty
            ? const Center(child: Text('No cities found', style: TextStyle(color: Colors.grey)))
            : ListView.builder(itemCount: _filtered.length, itemBuilder: (_, i) {
                final c = _filtered[i];
                return ListTile(dense: true, title: Text(c, style: const TextStyle(fontSize: 13)), selected: c == widget.selectedCity, selectedTileColor: Colors.purple[50], onTap: () => Navigator.pop(context, c));
              })),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

