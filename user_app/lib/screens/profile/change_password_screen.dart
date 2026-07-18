import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final _apiClient = OnMintApiClient();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiClient.auth.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        ToastUtils.showSuccess('Password changed successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to change password: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
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
              // Info Card
              Card(
                color: AppColors.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your password must be at least 8 characters long and include uppercase, lowercase, numbers, and special characters.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Current Password
              CustomTextField(
                controller: _currentPasswordController,
                label: 'Current Password',
                hint: 'Enter your current password',
                obscureText: _obscureCurrentPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
                validator: _validateCurrentPassword,
              ),
              const SizedBox(height: 16),

              // New Password
              CustomTextField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Enter your new password',
                obscureText: _obscureNewPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                obscureText: _obscureConfirmPassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 32),

              // Change Password Button
              CustomButton(
                text: 'Change Password',
                onPressed: _isLoading ? null : _changePassword,
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
}
