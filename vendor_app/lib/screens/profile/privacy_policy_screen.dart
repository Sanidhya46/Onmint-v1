import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1565C0);
    const Color darkNavy = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkNavy, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Partner Privacy Policy',
          style: TextStyle(
            color: darkNavy,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, color: primaryColor),
            tooltip: 'Open Web Policy',
            onPressed: () => _launchUrl('https://privacy.policy.onmint.in'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Header ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor.withValues(alpha: 0.12), primaryColor.withValues(alpha: 0.04)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.shield_outlined, size: 40, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ONMINT Partner Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: darkNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Effective Date: September 2026  •  Version 2.4',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your privacy and professional data protection are top priorities. This Privacy Policy discloses how ONMINT Partner collects, verifies, retains, and deletes partner data across our healthcare provider ecosystem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Key Badges ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTrustChip(Icons.verified_user_outlined, 'Non-Sale Guarantee', Colors.teal),
                _buildTrustChip(Icons.lock_clock_outlined, 'TLS 1.3 Encryption', Colors.indigo),
                _buildTrustChip(Icons.check_circle_outline, 'Google Play Compliant', Colors.green),
                _buildTrustChip(Icons.delete_sweep_outlined, '30-Day Erasure', Colors.deepOrange),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 1 ──
            _buildNumberedSection(
              number: '1',
              title: 'Information & KYC Data We Collect',
              description:
                  'We collect professional credential and identity data necessary for partner verification, background compliance, and dispatching:',
              bullets: [
                'Identity Information: Full Name, Mobile Number, Email Address, Gender, DOB, and Govt ID Proof (Aadhaar / PAN).',
                'Professional Credentials: State Medical Council Reg Number, Nursing Council Certificate, Pharmacy Drug License, Pathology Lab Certifications, Ambulance RC & Driving License.',
                'Live Location Data: Geolocation coordinates during active shift/duty for nearest patient request assignment and route dispatching.',
                'Banking & Payout Info: Verified bank account / UPI details for processing service earnings payouts.',
                'Payment & Transaction Metadata: Transaction reference identifiers processed via authorized PCI-DSS compliant payment gateways.',
              ],
            ),

            // ── Section 2 ──
            _buildNumberedSection(
              number: '2',
              title: 'Device Permissions & Purposes',
              description:
                  'In accordance with Google Play policies, ONMINT Partner requests only essential operational permissions:',
              bullets: [
                'Location (ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION): Used to assign nearby service requests, calculate travel distance, and enable patient live tracking during ambulance transit or home visits.',
                'Camera & Storage (CAMERA / Photos): Used to upload professional medical certificates, vehicle RC copies, KYC documents, and diagnostic test reports.',
                'Microphone (RECORD_AUDIO): Used solely during active tele-consultation audio/video calls between consulting doctors and patients.',
                'Notifications (POST_NOTIFICATIONS): Used for urgent new booking alerts, dispatch notices, and platform updates.',
              ],
            ),

            // ── Section 3 ──
            _buildNumberedSection(
              number: '3',
              title: 'Use of Partner Information',
              description:
                  'Your data is used solely to verify professional qualifications, assign relevant local service bookings, process partner payouts, and ensure patient safety:',
              bullets: [
                'Facilitating patient-partner connectivity and healthcare service dispatch.',
                'Verifying licenses with medical and healthcare regulatory bodies.',
                'Providing partner operational support, dispute resolution, and emergency assistance.',
                'Complying with statutory healthcare, legal, and tax requirements in India.',
              ],
            ),

            // ── Section 4 ──
            _buildNumberedSection(
              number: '4',
              title: 'Information Sharing & Non-Sale Guarantee',
              description:
                  'ONMINT strictly NEVER sells or monetizes partner data. Information (name, qualification, vehicle number) is shared with booking patients solely to facilitate service delivery.',
            ),

            // ── Section 5 ──
            _buildNumberedSection(
              number: '5',
              title: 'Data Security & Encryption',
              description:
                  'All partner credential files, location streams, and payout transactions are protected using enterprise-grade TLS 1.3 encryption and secure role-restricted cloud storage.',
            ),

            // ── Section 6 ──
            _buildNumberedSection(
              number: '6',
              title: 'Data Retention Policy & Schedules',
              description:
                  'ONMINT maintains clear, compliant data retention schedules for all partner data:',
              bullets: [
                'Partner Profile & KYC Credentials: Retained while partner account is active and as required for statutory medical licensing compliance.',
                'Service & Consultation Logs: Retained to support clinical continuity, auditing, and tax accounting requirements.',
                'Live Location Streams: Ephemeral. Used only during active on-duty patient dispatch and purged within 24 hours of trip completion.',
                'Security Logs: Retained for up to 90 days for system integrity, then automatically purged.',
                'Erasure Window: In the event of partner account termination, personal identifiers are permanently purged within 30 business days.',
              ],
            ),

            // ── Section 7 ──
            _buildNumberedSection(
              number: '7',
              title: 'Partner Data Deletion Policy & Step-by-Step Instructions',
              description:
                  'In compliance with Google Play User Data policies, partners have the absolute right to request permanent account offboarding and complete data deletion at any time:',
              bullets: [
                'Method 1 — Dedicated Online Web Deletion Portal (No app required): Visit our official portal at https://onmint.in/delete-account.html, select Partner role, and submit the deletion request.',
                'Method 2 — In-App Request: Profile Settings > Account Deletion in the partner app.',
                'Method 3 — Email Support: Send a request from your registered email to onmintofficial@gmail.com with your registered partner mobile number and subject "Account Deletion Request".',
                'Scope of Erasure: Verified credentials, contact details, vehicle logs, and profile records are irreversibly purged.',
                'Fulfillment Timeline: Immediate deactivation upon verification, with complete data purging finalized within 30 business days.',
              ],
            ),

            // ── Section 8 ──
            _buildNumberedSection(
              number: '8',
              title: 'Partner Consent & Medical Compliance',
              description:
                  'Using the ONMINT Partner app signifies consent to these credential verification, privacy, and dispatch terms. Partners agree to uphold ethical medical standards at all times.',
            ),
            const SizedBox(height: 12),

            // ── Contact & Grievance Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withValues(alpha: 0.04),
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.contact_support_outlined, color: primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Official Privacy & Support Contacts',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: darkNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildContactTile(
                    icon: Icons.language_rounded,
                    title: 'Official Privacy Portal',
                    value: 'https://privacy.policy.onmint.in',
                    onTap: () => _launchUrl('https://privacy.policy.onmint.in'),
                  ),
                  const SizedBox(height: 10),
                  _buildContactTile(
                    icon: Icons.email_outlined,
                    title: 'Support & Deletion Email',
                    value: 'onmintofficial@gmail.com',
                    onTap: () => _launchUrl('mailto:onmintofficial@gmail.com'),
                  ),
                  const SizedBox(height: 10),
                  _buildContactTile(
                    icon: Icons.phone_outlined,
                    title: 'Partner Helpline',
                    value: '+91 95654 43382',
                    onTap: () => _launchUrl('tel:9565443382'),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ONMINT Technologies Private Limited\nGrievance Officer: Legal & Privacy Team\nUttar Pradesh, India',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Footer ──
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 ONMINT Technologies Private Limited',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All Rights Reserved  •  Regulated Healthcare Ecosystem',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedSection({
    required String number,
    required String title,
    required String description,
    List<String>? bullets,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
          if (bullets != null && bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1565C0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1565C0)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
