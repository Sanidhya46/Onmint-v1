import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../data/indian_states_cities.dart';
import '../../widgets/terms_privacy_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedGender = 'Male';
  String? _selectedState;
  String? _selectedCity;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }


  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      ToastUtils.showError('Please select your state');
      return;
    }

    if (_selectedCity == null) {
      ToastUtils.showError('Please select your city');
      return;
    }

    if (!_agreeTerms) {
      ToastUtils.showError('Please agree to Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final data = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': 'patient',
      'gender': _selectedGender,
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'city': _selectedCity ?? '',
      'state': _selectedState ?? '',
      'pincode': _pincodeController.text.trim(),
      'location': {
        'type': 'Point',
        'coordinates': [0.0, 0.0],
      },
    };

    final success = await authProvider.register(data);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ToastUtils.showSuccess('Registration successful!');
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ToastUtils.showError(
        authProvider.error?.replaceAll('Registration failed: ', '').replaceAll('Exception: ', '') ?? 'Registration failed. Please try again.'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height + MediaQuery.of(context).viewInsets.bottom;
    final bottomHeight = screenHeight * (2 / 3);
    final s = (bottomHeight / 500).clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                    Image.asset(
                      'assets/images/register_login/register_top_banner.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    
                    // ──── BOTTOM: Form Container ────
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 12 * s, right: 12 * s, bottom: 0, top: 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24 * s),
                              topRight: Radius.circular(24 * s),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(top: 20 * s, left: 20 * s, right: 20 * s, bottom: 20 * s),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6 * s),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D6EFD),
                                        borderRadius: BorderRadius.circular(10 * s),
                                      ),
                                      child: Icon(Icons.person_outline, color: Colors.white, size: 18 * s),
                                    ),
                                    SizedBox(width: 12 * s),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create Your Profile',
                                            style: TextStyle(
                                              fontSize: 14 * s,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF152238),
                                            ),
                                          ),
                                          SizedBox(height: 2 * s),
                                          Text(
                                            'Please fill in your details to continue',
                                            style: TextStyle(
                                              fontSize: 10 * s,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16 * s),
                                
                                
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInputField(
                                              label: 'First Name',
                                              hint: 'First name',
                                              controller: _firstNameController,
                                              icon: Icons.person_outline,
                                              s: s,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter first name';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 16 * s),
                                          Expanded(
                                            child: _buildInputField(
                                              label: 'Last Name',
                                              hint: 'Last name',
                                              controller: _lastNameController,
                                              icon: Icons.person_outline,
                                              s: s,
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter last name';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      SizedBox(height: 16 * s),
                                      
                                      _buildInputField(
                                        label: 'Email Address',
                                        hint: 'Email address',
                                        controller: _emailController,
                                        icon: Icons.email_outlined,
                                        s: s,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter email';
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      SizedBox(height: 16 * s),
                                      
                                      _buildInputField(
                                        label: 'Phone Number',
                                        hint: 'Phone number',
                                        controller: _phoneController,
                                        icon: Icons.phone_outlined,
                                        s: s,
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter phone number';
                                          }
                                          if (value.length < 10) {
                                            return 'Phone number must be at least 10 digits';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      SizedBox(height: 16 * s),
                                      
                                      _buildInputField(
                                        label: 'Password',
                                        hint: 'Password',
                                        controller: _passwordController,
                                        icon: Icons.lock_outline,
                                        s: s,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: Colors.grey,
                                            size: 18 * s,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter password';
                                          }
                                          if (value.length < 8) {
                                            return 'password should be of 8 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      

                                      
                                      SizedBox(height: 16 * s),
                                      
                                      Row(
                                        children: [
                                          Expanded(child: _buildStateDropdown(s)),
                                          SizedBox(width: 16 * s),
                                          Expanded(child: _buildCityDropdown(s)),
                                        ],
                                      ),
                                      
                                      SizedBox(height: 16 * s),
                                      
                                      _buildInputField(
                                        label: 'Pincode',
                                        hint: 'Enter pincode',
                                        controller: _pincodeController,
                                        icon: Icons.pin_drop_outlined,
                                        s: s,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter pincode';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      SizedBox(height: 20 * s),
                                      
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 24 * s,
                                            height: 24 * s,
                                            child: Checkbox(
                                              value: _agreeTerms,
                                              activeColor: const Color(0xFF0D6EFD),
                                              onChanged: (value) {
                                                setState(() => _agreeTerms = value ?? false);
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 8 * s),
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                text: 'I agree to the ',
                                                style: TextStyle(color: Colors.grey.shade700, fontSize: 11 * s, fontFamily: 'Poppins'),
                                                children: [
                                                  TextSpan(
                                                    text: 'Terms & Conditions',
                                                    style: const TextStyle(
                                                      color: Color(0xFF0D6EFD),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = () async {
                                                        final approved = await showTermsPrivacyDialog(context, isPrivacyPolicy: false);
                                                        if (approved) {
                                                          setState(() => _agreeTerms = true);
                                                        }
                                                      },
                                                  ),
                                                  const TextSpan(text: ' and '),
                                                  TextSpan(
                                                    text: 'Privacy Policy',
                                                    style: const TextStyle(
                                                      color: Color(0xFF0D6EFD),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    recognizer: TapGestureRecognizer()
                                                      ..onTap = () async {
                                                        final approved = await showTermsPrivacyDialog(context, isPrivacyPolicy: true);
                                                        if (approved) {
                                                          setState(() => _agreeTerms = true);
                                                        }
                                                      },
                                                  ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
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
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40 * ((MediaQuery.of(context).size.height * (2 / 3)) / 500).clamp(0.8, 1.2),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * ((MediaQuery.of(context).size.height * (2 / 3)) / 500).clamp(0.8, 1.2)),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'CONTINUE',
                          style: TextStyle(fontSize: 14 * ((MediaQuery.of(context).size.height * (2 / 3)) / 500).clamp(0.8, 1.2), fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              SizedBox(height: 12 * ((MediaQuery.of(context).size.height * (2 / 3)) / 500).clamp(0.8, 1.2)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12 * ((MediaQuery.of(context).size.height * (2 / 3)) / 500).clamp(0.8, 1.2)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D6EFD),
                        fontSize: 12 * ((MediaQuery.of(context).size.height * (2 / 3)) / 500).clamp(0.8, 1.2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  // ──────────────────────────────────────────────────────────
  // State Searchable Autocomplete
  // ──────────────────────────────────────────────────────────
  Widget _buildStateDropdown(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: TextStyle(
            fontSize: 9 * s,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF152238),
          ),
        ),
        SizedBox(height: 2 * s),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8 * s),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 0),
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
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(fontSize: 11 * s, color: const Color(0xFF152238)),
                decoration: InputDecoration(
                  hintText: 'Type to search state...',
                  hintStyle: TextStyle(fontSize: 10 * s, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12 * s),
                  icon: Icon(Icons.map_outlined, color: const Color(0xFF0D6EFD), size: 14 * s),
                  suffixIcon: controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            controller.clear();
                            setState(() { _selectedState = null; _selectedCity = null; });
                          },
                          child: Icon(Icons.close, size: 14 * s, color: Colors.grey.shade400))
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
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10 * s),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200 * s),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 10 * s),
                            child: Row(
                              children: [
                                Icon(Icons.map_outlined, color: const Color(0xFF0D6EFD), size: 14 * s),
                                SizedBox(width: 8 * s),
                                Flexible(child: Text(option, style: TextStyle(fontSize: 12 * s, color: const Color(0xFF152238)))),
                              ],
                            ),
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // City Searchable Autocomplete (filtered by selected state)
  // ──────────────────────────────────────────────────────────
  Widget _buildCityDropdown(double s) {
    final cities = _selectedState != null
        ? IndianStatesData.getCitiesForState(_selectedState!)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: TextStyle(
            fontSize: 9 * s,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF152238),
          ),
        ),
        SizedBox(height: 2 * s),
        Container(
          decoration: BoxDecoration(
            color: _selectedState == null ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(8 * s),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 0),
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
              return TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: _selectedState != null,
                style: TextStyle(fontSize: 11 * s, color: const Color(0xFF152238)),
                decoration: InputDecoration(
                  hintText: _selectedState == null ? 'Select state first' : 'Type to search city...',
                  hintStyle: TextStyle(fontSize: 10 * s, color: Colors.grey.shade400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12 * s),
                  icon: Icon(Icons.location_city, color: const Color(0xFF0D6EFD), size: 14 * s),
                  suffixIcon: controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            controller.clear();
                            setState(() { _selectedCity = null; });
                          },
                          child: Icon(Icons.close, size: 14 * s, color: Colors.grey.shade400))
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
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10 * s),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200 * s),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 10 * s),
                            child: Row(
                              children: [
                                Icon(Icons.location_city, color: const Color(0xFF0D6EFD), size: 14 * s),
                                SizedBox(width: 8 * s),
                                Flexible(child: Text(option, style: TextStyle(fontSize: 12 * s, color: const Color(0xFF152238)))),
                              ],
                            ),
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
    );
  }

  // ──────────────────────────────────────────────────────────
  // Gender Dropdown
  // ──────────────────────────────────────────────────────────
  Widget _buildGenderDropdown(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 9 * s,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF152238),
          ),
        ),
        SizedBox(height: 2 * s),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8 * s),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 9 * s),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400, size: 24 * s),
              style:
                  TextStyle(fontSize: 11 * s, color: const Color(0xFF152238)),
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(Icons.transgender,
                          color: const Color(0xFF0D6EFD), size: 14 * s),
                      SizedBox(width: 6 * s),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  if (newValue != null) _selectedGender = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // Reusable Input Field
  // ──────────────────────────────────────────────────────────
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required double s,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9 * s,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF152238),
          ),
        ),
        SizedBox(height: 2 * s),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8 * s),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(fontSize: 11 * s, color: const Color(0xFF152238)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(fontSize: 10 * s, color: Colors.grey.shade400),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12 * s),
              icon: Padding(
                padding: EdgeInsets.only(left: 12.0 * s),
                child:
                    Icon(icon, color: const Color(0xFF0D6EFD), size: 14 * s),
              ),
              prefixText: prefixText,
              prefixStyle: TextStyle(
                  fontSize: 11 * s, color: const Color(0xFF152238)),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
