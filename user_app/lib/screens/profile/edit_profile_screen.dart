import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  bool _isLoading = false;
  final _apiClient = OnMintApiClient();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';

      if (user.address != null) {
        _streetController.text = user.address!.street ?? '';
        _cityController.text = user.address!.city ?? '';
        _stateController.text = user.address!.state ?? '';
        _zipCodeController.text = user.address!.zipCode ?? '';
      }

      if (user.emergencyContact != null) {
        _emergencyNameController.text = user.emergencyContact!['name'] ?? '';
        _emergencyPhoneController.text = user.emergencyContact!['phone'] ?? '';
        _emergencyRelationController.text =
            user.emergencyContact!['relation'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final data = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zipCode': _zipCodeController.text,
        },
        'emergencyContact': {
          'name': _emergencyNameController.text,
          'phone': _emergencyPhoneController.text,
          'relation': _emergencyRelationController.text,
        },
      };

      await _apiClient.patient.updateProfile(data);

      // Update local user data
      await authProvider.refreshProfile();

      if (mounted) {
        ToastUtils.showSuccess('Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to update profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'Enter your first name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Enter your last name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Address Section
              _buildSectionHeader('Address'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _streetController,
                label: 'Street Address',
                hint: 'Enter your street address',
                prefixIcon: Icons.home_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
                      prefixIcon: Icons.location_city_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      label: 'State',
                      hint: 'State',
                      prefixIcon: Icons.map_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _zipCodeController,
                label: 'ZIP Code',
                hint: 'Enter ZIP code',
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ZIP code';
                  }
                  if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                    return 'Please enter a valid 6-digit ZIP code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Emergency Contact Section
              _buildSectionHeader('Emergency Contact'),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emergencyNameController,
                label: 'Contact Name',
                hint: 'Enter emergency contact name',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter emergency contact name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emergencyPhoneController,
                label: 'Contact Phone',
                hint: 'Enter emergency contact phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter emergency contact phone';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emergencyRelationController,
                label: 'Relationship',
                hint: 'e.g., Father, Mother, Spouse',
                prefixIcon: Icons.family_restroom_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter relationship';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: 'Save Changes',
                onPressed: _isLoading ? null : _updateProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Cancel Button
              CustomButton(
                text: 'Cancel',
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                isOutlined: true,
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }
}
