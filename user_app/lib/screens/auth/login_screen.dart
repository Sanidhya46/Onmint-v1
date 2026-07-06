import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../../widgets/terms_privacy_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Assuming the backend accepts the identifier in the phone parameter
    // If it only accepts phone, and the user typed email, it might fail.
    // For now, we pass the text as 'phone'.
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      if (authProvider.isPatient) {
        ToastUtils.showSuccess('Welcome back!');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ToastUtils.showError('This app is for patients only.');
        await authProvider.logout();
      }
    } else {
      ToastUtils.showError(
        authProvider.error?.replaceAll('Login failed: ', '').replaceAll('Exception: ', '') ?? 'Login failed. Please try again.'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomHeight = screenHeight * 0.60;
    final s = (bottomHeight / 480).clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
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
                      'assets/images/register_login/login_top_banner.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                    ),
                    
                    // ──── BOTTOM: Form Container ────
                    Padding(
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
                                        'Login to access your healthcare services',
                                        style: TextStyle(
                                          fontSize: 11 * s,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 12 * s),

                                  _buildInputField(
                                    label: 'Mobile Number',
                                    hint: 'Enter your mobile number',
                                    controller: _usernameController,
                                    icon: Icons.phone_outlined,
                                    s: s,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter phone no.';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 4 * s),

                                  _buildInputField(
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    controller: _passwordController,
                                    icon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    s: s,
                                    suffixIcon: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth: 32 * s,
                                        minHeight: 32 * s,
                                      ),
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey.shade400,
                                        size: 16 * s,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 10 * s),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 16 * s,
                                            height: 16 * s,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4 * s)),
                                              side: BorderSide(color: Colors.grey.shade400),
                                            ),
                                          ),
                                          SizedBox(width: 6 * s),
                                          Text(
                                            'Remember me',
                                            style: TextStyle(
                                              fontSize: 10 * s,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: 10 * s,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0D6EFD),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 6 * s),

                                  SizedBox(
                                    height: 40 * s,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0D6EFD),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8 * s),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(width: 18 * s, height: 18 * s, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Text(
                                              'LOGIN',
                                              style: TextStyle(fontSize: 13 * s, fontWeight: FontWeight.bold),
                                            ),
                                    ),
                                  ),

                                  SizedBox(height: 8 * s),
                                  
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey.shade300)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8 * s),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(fontSize: 10 * s, color: Colors.grey.shade500),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey.shade300)),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 8 * s),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSocialButton(
                                          text: 'Google',
                                          iconData: Icons.g_mobiledata,
                                          iconColor: Colors.red,
                                          s: s,
                                          onPressed: () {},
                                        ),
                                      ),
                                      SizedBox(width: 8 * s),
                                      Expanded(
                                        child: _buildSocialButton(
                                          text: 'Apple',
                                          iconData: Icons.apple,
                                          iconColor: Colors.black,
                                          s: s,
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 12 * s),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: TextStyle(color: Colors.black87, fontSize: 11 * s),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).pushReplacementNamed('/register');
                                        },
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF0D6EFD),
                                            fontSize: 11 * s,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 12 * s),
                                  Center(
                                    child: Text.rich(
                                      TextSpan(
                                        text: 'By logging in, you agree to our ',
                                        style: TextStyle(fontSize: 9 * s, color: Colors.grey.shade500),
                                        children: [
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF0D6EFD)),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF0D6EFD)),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required double s,
    bool obscureText = false,
    Widget? suffixIcon,
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
            validator: validator,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(fontSize: 11 * s, color: const Color(0xFF152238)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 10 * s, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * s),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * s),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * s),
                borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 16 * s, horizontal: 12 * s),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 14 * s, right: 8 * s),
                child: Icon(icon, color: const Color(0xFF0D6EFD), size: 18 * s),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 32 * s, minHeight: 32 * s),
              suffixIcon: suffixIcon,
              suffixIconConstraints: BoxConstraints(minWidth: 32 * s, minHeight: 32 * s),
              errorStyle: const TextStyle(height: 0, fontSize: 0, color: Colors.transparent),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData iconData,
    required Color iconColor,
    required double s,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40 * s,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8 * s),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: iconColor, size: 20 * s),
            SizedBox(width: 6 * s),
            Text(
              text,
              style: TextStyle(
                color: const Color(0xFF152238),
                fontSize: 12 * s,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
