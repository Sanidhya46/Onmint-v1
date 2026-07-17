import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import '../../widgets/terms_privacy_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _apiErrorMessage;
  String _selectedCountryCode = '+91';
  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+81', '+49', '+33', '+86', '+7', '+55'];

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        '$_selectedCountryCode${_phoneController.text.trim()}',
        _passwordController.text,
      );

      if (!success) {
        if (mounted) {
          setState(() {
            _apiErrorMessage = authProvider.error
                    ?.replaceAll('Login failed: ', '')
                    .replaceAll('Exception: ', '') ??
                'Login failed. Please try again.';
          });
        }
        return;
      }

      final user = authProvider.currentUser;
      
      if (user != null && AppConfig.vendorRoles.contains(user.role.toLowerCase())) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        await authProvider.logout();
        if (mounted) {
          setState(() {
            _apiErrorMessage = 'This app is for healthcare providers only';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiErrorMessage = e.toString()
              .replaceAll('Exception: ', '')
              .replaceAll('Login failed: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? prefixWidget,
    Widget? suffixWidget,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    required double s,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13 * s,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF152238),
          ),
        ),
        SizedBox(height: 6 * s),
        SizedBox(
          height: 48 * s, // Fixed scaled height to prevent varying heights
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(fontSize: 13 * s, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 12 * s, color: Colors.grey.shade400),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 12 * s, right: 8 * s),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: const Color(0xFF0033CC), size: 20 * s),
                    if (prefixWidget != null) ...[
                      SizedBox(width: 8 * s),
                      prefixWidget,
                    ]
                  ],
                ),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 36 * s, minHeight: 36 * s),
              suffixIcon: suffixWidget,
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12 * s),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * s),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * s),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10 * s),
                borderSide: const BorderSide(color: Color(0xFF0033CC), width: 1.5),
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0, color: Colors.transparent), // Hide default error text to keep layout intact
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        // Custom error message display for better spacing control
        if (validator != null && controller.text.isNotEmpty) ...[
          // We can optionally add custom error text here if needed, but keeping it simple based on the previous implementation.
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomHeight = screenHeight * 0.60;
    final s = (bottomHeight / 480).clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ──── TOP: Image Banner ────
                    Image.asset(
                      'assets/images/register_login/top_banner12.jpeg',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    
                    // ──── BOTTOM: Form Container ────
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16 * s, right: 16 * s, bottom: 0, top: 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24 * s),
                            topRight: Radius.circular(24 * s),
                          ),
                        ),
                          child: Padding(
                            padding: EdgeInsets.only(top: 20 * s, left: 20 * s, right: 20 * s, bottom: 0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── Welcome Back Header ──
                                  Column(
                                    children: [
                                      Text(
                                        'Welcome Back!',
                                        style: TextStyle(
                                          fontSize: 18 * s,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF152238),
                                        ),
                                      ),
                                      SizedBox(height: 6 * s),
                                      Text(
                                        'Login to access your vendor dashboard',
                                        style: TextStyle(
                                          fontSize: 11 * s,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 24 * s),

                                  // ── Mobile Number Field ──
                                  _buildTextField(
                                    controller: _phoneController,
                                    icon: Icons.phone_outlined,
                                    label: 'Mobile Number',
                                    hint: 'Enter your 10-digit number',
                                    keyboardType: TextInputType.phone,
                                    s: s,
                                    prefixWidget: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '+91',
                                          style: TextStyle(
                                            fontSize: 15 * s,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          height: 16,
                                          width: 1.5,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Phone number required';
                                      if (val.length != 10) return 'Enter a valid 10-digit number';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16 * s),

                                  // ── Password Field ──
                                  _buildTextField(
                                    controller: _passwordController,
                                    icon: Icons.lock_outline,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    obscureText: _obscurePassword,
                                    s: s,
                                    suffixWidget: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.grey.shade600,
                                        size: 20 * s,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return 'Password required';
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 12 * s),

                                  // ── Remember Me & Forgot Password ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: const Color(0xFF0033CC),
                                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12 * s,
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          // TODO: Implement forgot password
                                        },
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: const Color(0xFF0033CC),
                                            fontSize: 13 * s,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 32 * s),

                              // ── Login Button ──
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46 * s,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0033CC),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12 * s),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: _isLoading ? null : _login,
                                      child: _isLoading
                                          ? SizedBox(
                                              height: 20 * s,
                                              width: 20 * s,
                                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            )
                                          : Text(
                                              'LOGIN',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15 * s,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 16 * s),

                                  // ── OR Divider ──
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16 * s),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13 * s,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                    ],
                                  ),
                                  SizedBox(height: 14 * s),

                                  // ── Sign Up Link ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Don\'t have an account? ',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13 * s),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            color: const Color(0xFF0033CC),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14 * s,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ── Decreased Gap Before Terms & Conditions ──
                                  SizedBox(height: 8 * s),

                                  // ── Terms & Privacy ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => showTermsPrivacyDialog(context, showAgreeButton: false),
                                        child: Text(
                                          'Terms & Conditions',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0033CC),
                                            fontSize: 12 * s,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '  |  ',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12 * s),
                                      ),
                                      GestureDetector(
                                        onTap: () => showTermsPrivacyDialog(context, isPrivacyPolicy: true, showAgreeButton: false),
                                        child: Text(
                                          'Privacy Policy',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0033CC),
                                            fontSize: 12 * s,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  ),
              ),
            ),
          );
        },
      ),
    );
  }
}

