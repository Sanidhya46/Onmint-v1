import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  String? _selectedGender;
  String? _selectedState;
  List<String> _selectedLanguages = [];
  bool _isLoading = false;
  DateTime? _dateOfBirth;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _stateOptions = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh',
    'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra',
    'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
    'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  ];
  final List<String> _languageOptions = ['Hindi', 'English', 'Kannada', 'Other'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address?.street ?? '');
    _cityController = TextEditingController(text: user?.address?.city ?? '');
    _pincodeController = TextEditingController(text: user?.address?.pincode ?? '');

    _dateOfBirth = user?.dateOfBirth;
    _selectedGender = user?.gender;
    if (_selectedGender != null && !_genderOptions.contains(_selectedGender)) {
      _selectedGender = null;
    }

    _selectedState = user?.address?.state;
    if (_selectedState != null && !_stateOptions.contains(_selectedState)) {
      if (_selectedState!.isNotEmpty) {
        _stateOptions.add(_selectedState!);
      } else {
        _selectedState = null;
      }
    }

    _selectedLanguages = List<String>.from(user?.languages ?? []);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  String _formatDob(DateTime dob) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dob.day} ${months[dob.month - 1]} ${dob.year}';
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();

      final Map<String, dynamic> updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      };

      if (_selectedGender != null) updateData['gender'] = _selectedGender;
      if (_selectedState != null) updateData['state'] = _selectedState;
      if (_dateOfBirth != null) updateData['dateOfBirth'] = _dateOfBirth!.toIso8601String();
      if (_selectedLanguages.isNotEmpty) updateData['languages'] = _selectedLanguages;

      // Use the OnMintApiClient via AuthService to call PUT /auth/profile
      final apiClient = OnMintApiClient();
      final updatedUser = await apiClient.auth.updateProfile(updateData);

      // Refresh user in auth provider
      await authProvider.refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personal details updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF152238), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(color: Color(0xFF152238), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Update your personal details',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo Section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: user?.profilePicture != null
                                    ? NetworkImage(user!.profilePicture!)
                                    : null,
                                child: user?.profilePicture == null
                                    ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade200, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFF1A237E)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Upload a clear photo\nof your face', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  Text('JPG, PNG up to 5MB', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.upload_outlined, size: 16),
                                label: const Text('Change Photo', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1A237E),
                                  side: const BorderSide(color: Color(0xFF1A237E)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Details
                    const Text('Basic Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF152238))),
                    const SizedBox(height: 12),
                    _buildField(label: 'Full Name', icon: Icons.person_outline,
                      child: Row(
                        children: [
                          Expanded(child: _textField(_firstNameController, 'First Name')),
                          const SizedBox(width: 8),
                          Expanded(child: _textField(_lastNameController, 'Last Name')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildField(
                            label: 'Date of Birth',
                            icon: Icons.calendar_today_outlined,
                            child: InkWell(
                              onTap: _pickDate,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _dateOfBirth != null ? _formatDob(_dateOfBirth!) : 'Select DOB',
                                      style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500,
                                        color: _dateOfBirth != null ? const Color(0xFF152238) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.calendar_month_outlined, color: Colors.grey.shade400, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _buildField(
                            label: 'Age',
                            icon: Icons.person_outline,
                            child: Text(
                              _dateOfBirth != null ? '${_calculateAge(_dateOfBirth!)} Years' : '-',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF152238)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Gender',
                      icon: Icons.wc_outlined,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isDense: true,
                          isExpanded: true,
                          hint: Text('Select Gender', style: TextStyle(color: Colors.grey.shade400)),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          style: const TextStyle(color: Color(0xFF152238), fontSize: 14, fontWeight: FontWeight.w500),
                          onChanged: (val) => setState(() => _selectedGender = val),
                          items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Details
                    const Text('Contact Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF152238))),
                    const SizedBox(height: 12),
                    _buildField(label: 'Mobile Number', icon: Icons.phone_outlined,
                      child: _textField(_phoneController, ''),
                      suffixIcon: Icons.phone_enabled_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildField(label: 'Email Address', icon: Icons.email_outlined,
                      child: _textField(_emailController, '', readOnly: true),
                      suffixIcon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 24),

                    // Address Details
                    const Text('Address Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF152238))),
                    const SizedBox(height: 12),
                    _buildField(label: 'Full Address', icon: Icons.location_on_outlined,
                      child: _textField(_addressController, ''),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(label: 'City', icon: null,
                            child: _textField(_cityController, ''),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(label: 'State', icon: null,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedState,
                                isDense: true,
                                isExpanded: true,
                                hint: Text('Select', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                                style: const TextStyle(color: Color(0xFF152238), fontSize: 14, fontWeight: FontWeight.w500),
                                onChanged: (val) => setState(() => _selectedState = val),
                                items: _stateOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(label: 'Pincode', icon: null,
                            child: _textField(_pincodeController, ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Languages Spoken
                    const Text('Languages Spoken', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF152238))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _languageOptions.map((lang) {
                        final isSelected = _selectedLanguages.contains(lang);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedLanguages.remove(lang);
                              } else {
                                _selectedLanguages.add(lang);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(lang, style: TextStyle(
                                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 13,
                                )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Update Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(color: Color(0xFF152238), fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
    );
  }

  Widget _buildField({required String label, IconData? icon, required Widget child, IconData? suffixIcon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF1A237E), size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
          if (suffixIcon != null) Icon(suffixIcon, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }
}
